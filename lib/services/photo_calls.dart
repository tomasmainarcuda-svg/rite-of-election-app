/*
 * STAFF APP — photo calling state ("who is being called at each station").
 *
 * Sends to Firebase (Nov 6): when the staff is signed in with the team's Google account,
 * every "Siguiente / Atrás" writes
 *   roe/live/stations/{id} = { nowGroup, done }     (+ roe/live/updatedAt)
 * — the same place the old web staff panel uses. The database rules only let the staff
 * account write there. Not signed in → TEST MODE: the position stays on this tablet only.
 *
 * It also LISTENS to roe/live/stations, so if another device moves a station, this tablet
 * follows. The position is kept on the tablet too (a refresh never loses it).
 */
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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

  /// Signed-in staff account (null = test mode, nothing is sent).
  final user = ValueNotifier<User?>(null);

  /// Last send worked (true) / failed (false) / nothing sent yet (null).
  final sent = ValueNotifier<bool?>(null);

  /// Human-readable problem to show on screen (null = all good).
  final problem = ValueNotifier<String?>(null);

  SharedPreferences? _prefs;
  DatabaseReference? _live;
  bool _cloudReady = false;

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

  /// Firebase project ecr-mesas (same one the web app uses). These values are public by design.
  Future<void> initCloud() async {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyAD1S_E_2y5D1QlIuDT9kL5kevX3jGXwLM',
          appId: '1:743610525231:web:a3e4f0f445994f3f4008da',
          messagingSenderId: '743610525231',
          projectId: 'ecr-mesas',
          authDomain: 'ecr-mesas.firebaseapp.com',
          databaseURL: Config.databaseUrl,
        ),
      );
      _live = FirebaseDatabase.instance.ref('${Config.dbRoot}/live');
      _cloudReady = true;
      FirebaseAuth.instance.authStateChanges().listen((u) => user.value = u);
      // Follow what's in Firebase (reads are public).
      _live!.child('stations').onValue.listen((e) => _fromCloud(e.snapshot.value), onError: (_) {});
    } catch (e) {
      problem.value = 'No se pudo conectar con Firebase: $e';
    }
  }

  Future<void> signIn() async {
    if (!_cloudReady) return;
    problem.value = null;
    try {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
    } catch (e) {
      problem.value = 'No se pudo entrar con Google: $e';
    }
  }

  Future<void> signOut() async {
    if (_cloudReady) await FirebaseAuth.instance.signOut();
    sent.value = null;
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
    _publish([for (final s in stations) s.id]);
  }

  void _move(int stationId, int dir) {
    final len = queue(stationId).length;
    final cur = pos.value[stationId] ?? 0;
    final nxt = (cur + dir).clamp(0, len).toInt();
    if (nxt == cur) return;
    pos.value = {...pos.value, stationId: nxt};
    _save();
    _publish([stationId]);
  }

  void _save() => _prefs?.setString(_kPos, jsonEncode(pos.value.map((k, v) => MapEntry('$k', v))));

  /// Send the given stations to Firebase (only when a staff account is signed in).
  Future<void> _publish(List<int> ids) async {
    final ref = _live;
    if (ref == null || user.value == null) return; // test mode: stays on this tablet
    final update = <String, Object?>{'updatedAt': ServerValue.timestamp};
    for (final id in ids) {
      update['stations/$id'] = {'nowGroup': now(id)?.group ?? 0, 'done': done(id)};
    }
    try {
      await ref.update(update);
      sent.value = true;
      problem.value = null;
    } catch (e) {
      sent.value = false;
      problem.value = 'No se envió. ¿Esta cuenta de Google tiene permiso de staff? ($e)';
    }
  }

  /// Firebase → tablet: { "1": {nowGroup, done}, ... } or a list with index = station id.
  void _fromCloud(Object? v) {
    Map<String, dynamic> m;
    if (v is Map) {
      m = v.map((k, val) => MapEntry('$k', val));
    } else if (v is List) {
      m = {for (var i = 0; i < v.length; i++) if (v[i] != null) '$i': v[i]};
    } else {
      return;
    }
    final next = {...pos.value};
    for (final s in stations) {
      final st = m['${s.id}'];
      if (st is! Map) continue;
      final q = queue(s.id);
      if (st['done'] == true) {
        next[s.id] = q.length;
      } else {
        final g = (st['nowGroup'] as num?)?.toInt() ?? 0;
        final idx = q.indexWhere((p) => p.group == g);
        next[s.id] = idx < 0 ? 0 : idx;
      }
    }
    if (!mapEquals(next, pos.value)) {
      pos.value = next;
      _save();
    }
  }
}
