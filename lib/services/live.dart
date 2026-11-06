/*
 * Live data from the staff panel (Firebase, read-only), shared by every screen:
 *   roe/live      → current rite part ("now" in Program) + announcement banner
 *   roe/libreto   → staff overrides of the booklet + sheet-music keys (cached for offline)
 *   roe/libimg/k  → sheet-music image (data: URL or https URL), fetched once and cached
 * Ported from the web app's js/live.js + js/libreto.js (store part).
 */
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rtdb.dart';

class LiveState {
  final String ritePartId;
  final dynamic announcement; // string or {en, es}
  const LiveState({this.ritePartId = '', this.announcement});

  factory LiveState.from(dynamic raw) {
    if (raw is! Map) return const LiveState();
    return LiveState(
      ritePartId: raw['ritePartId'] is String ? raw['ritePartId'] as String : '',
      announcement: raw['announcement'],
    );
  }

  String announcementText(String lang) {
    final a = announcement;
    if (a == null) return '';
    if (a is String) return a;
    if (a is Map) return '${a[lang] ?? a['en'] ?? a['es'] ?? ''}';
    return '';
  }
}

class Live {
  Live._();
  static final Live I = Live._();

  final state = ValueNotifier<LiveState>(const LiveState());
  final libreto = ValueNotifier<Map<String, dynamic>>({});
  final connected = ValueNotifier<bool>(true);

  static const _kLibreto = 'roe.libreto';
  static const _kImg = 'roe.libimg.';

  RtdbWatch? _live, _lib;
  SharedPreferences? _prefs;
  final Map<String, Future<String?>> _pending = {};

  Future<void> start() async {
    if (_live != null) return;
    _prefs = await SharedPreferences.getInstance();
    try {
      final cached = _prefs!.getString(_kLibreto);
      if (cached != null) libreto.value = Map<String, dynamic>.from(jsonDecode(cached) as Map);
    } catch (_) {}

    _live = RtdbWatch('live', onValue: (v) => state.value = LiveState.from(v), onConnection: (c) => connected.value = c)..start();
    _lib = RtdbWatch('libreto', onValue: (v) {
      final m = v is Map ? v.map((k, val) => MapEntry('$k', val)) : <String, dynamic>{};
      libreto.value = m;
      _prefs?.setString(_kLibreto, jsonEncode(m));
    })
      ..start();
  }

  /// App came back to the foreground: reopen the streams right away.
  void resume() {
    _live?.reconnect();
    _lib?.reconnect();
  }

  /// Sheet-music image for a key (data: URL or https URL), cached on the phone.
  Future<String?> image(String key) {
    final hit = _prefs?.getString('$_kImg$key');
    if (hit != null) return Future.value(hit);
    return _pending[key] ??= rtdbGet('libimg/$key').then((v) {
      final url = v is String ? v : null;
      if (url != null) _prefs?.setString('$_kImg$key', url);
      return url;
    }).catchError((_) {
      _pending.remove(key);
      return null;
    });
  }
}
