/*
 * STAFF APP — photo calling state ("who is being called at each station").
 *
 * FRONT ONLY for now (Tomás, Nov 6): the position of each station is kept on this tablet
 * (so a refresh doesn't lose it). It does NOT reach the participants' app yet.
 *
 * Backend hook (later): every change goes through _publish(). There we'll write
 *   roe/live/stations/{id} = { nowGroup, done }
 * in Firebase with the staff Google sign-in; the participants' app reads that same path.
 */
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/event_data.dart';
import '../data/models.dart';

class PhotoCalls {
  PhotoCalls._();
  static final PhotoCalls I = PhotoCalls._();

  static const _kPos = 'roe.staff.photoPos';

  /// Station id → index in that station's queue. index == queue length → station finished.
  final pos = ValueNotifier<Map<int, int>>({for (final s in stations) s.id: 0});

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final raw = _prefs!.getString(_kPos);
      if (raw != null) {
        final m = (jsonDecode(raw) as Map).map((k, v) => MapEntry(int.parse('$k'), (v as num).toInt()));
        pos.value = {for (final s in stations) s.id: (m[s.id] ?? 0).clamp(0, queue(s.id).length).toInt()};
      }
    } catch (_) {}
  }

  /// Groups waiting at a station, in calling order (one entry per parish/group).
  List<Parish> queue(int stationId) => parishes.where((p) => p.station == stationId && p.hasAssignment).toList()
    ..sort((a, b) => a.group.compareTo(b.group));

  Parish? now(int stationId) {
    final q = queue(stationId);
    final i = pos.value[stationId] ?? 0;
    return i < q.length ? q[i] : null;
  }

  Parish? next(int stationId) {
    final q = queue(stationId);
    final i = (pos.value[stationId] ?? 0) + 1;
    return i < q.length ? q[i] : null;
  }

  bool done(int stationId) => (pos.value[stationId] ?? 0) >= queue(stationId).length;

  void advance(int stationId) => _move(stationId, 1);
  void back(int stationId) => _move(stationId, -1);

  void resetAll() {
    pos.value = {for (final s in stations) s.id: 0};
    _save();
    for (final s in stations) {
      _publish(s.id);
    }
  }

  void _move(int stationId, int dir) {
    final len = queue(stationId).length;
    final cur = pos.value[stationId] ?? 0;
    final nxt = (cur + dir).clamp(0, len).toInt();
    if (nxt == cur) return;
    pos.value = {...pos.value, stationId: nxt};
    _save();
    _publish(stationId);
  }

  void _save() => _prefs?.setString(_kPos, jsonEncode(pos.value.map((k, v) => MapEntry('$k', v))));

  /// Backend hook — not connected yet (front only). Later: write to Firebase here.
  void _publish(int stationId) {
    // TODO(backend): roe/live/stations/$stationId = { nowGroup: now(stationId)?.group ?? 0, done: done(stationId) }
  }
}
