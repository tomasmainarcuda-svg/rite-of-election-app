/*
 * Read-only live sync with the Firebase Realtime Database over its REST streaming API
 * (Server-Sent Events). Same database and paths the web app uses:
 *   roe/live      staff-driven live state (photo stations, rite part, announcement)
 *   roe/onair     { es: { live, since, by }, vi: {...} } — interpreter on air
 *   roe/libreto   staff overrides of the booklet + sheet-music keys
 *   roe/libimg/k  sheet-music image (data: URL or https URL)
 * Reads are public in the database rules, so the app needs no account and no Firebase SDK.
 * Reconnects by itself (backoff up to 30 s) — e.g. after the phone was locked.
 */
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/event_data.dart';

Uri _url(String path) => Uri.parse('${Config.databaseUrl}/${Config.dbRoot}/$path.json');

/// One-shot read.
Future<dynamic> rtdbGet(String path) async {
  final r = await http.get(_url(path)).timeout(const Duration(seconds: 20));
  if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
  return jsonDecode(utf8.decode(r.bodyBytes));
}

/// A list stored in the database may come back as a JSON array or as a map {"0":…, "1":…}.
List<dynamic> asList(dynamic v) {
  if (v is List) return v.where((e) => e != null).toList();
  if (v is Map) {
    final keys = v.keys.map((k) => '$k').toList()..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    return keys.map((k) => v[k]).where((e) => e != null).toList();
  }
  return const [];
}

class RtdbWatch {
  final String path;
  final void Function(dynamic value) onValue;
  final void Function(bool connected)? onConnection;

  RtdbWatch(this.path, {required this.onValue, this.onConnection});

  http.Client? _client;
  StreamSubscription<String>? _sub;
  Timer? _retry;
  bool _closed = false;
  int _attempt = 0;
  dynamic _value;

  void start() => _connect();

  void close() {
    _closed = true;
    _retry?.cancel();
    _sub?.cancel();
    _client?.close();
  }

  /// Drop the current connection and open a new one now (e.g. app came back to the foreground).
  void reconnect() {
    if (_closed) return;
    _retry?.cancel();
    _sub?.cancel();
    _client?.close();
    _attempt = 0;
    _connect();
  }

  Future<void> _connect() async {
    if (_closed) return;
    final client = http.Client();
    _client = client;
    try {
      final req = http.Request('GET', _url(path))..headers['Accept'] = 'text/event-stream';
      final res = await client.send(req).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      _attempt = 0;
      onConnection?.call(true);
      var event = '';
      final data = StringBuffer();
      _sub = res.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          if (line.isEmpty) {
            _dispatch(event, data.toString());
            event = '';
            data.clear();
          } else if (line.startsWith('event:')) {
            event = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            if (data.isNotEmpty) data.write('\n');
            data.write(line.substring(5).trimLeft());
          }
        },
        onError: (_) => _fail(client),
        onDone: () => _fail(client),
        cancelOnError: true,
      );
    } catch (_) {
      _fail(client);
    }
  }

  void _fail(http.Client client) {
    if (!identical(client, _client)) return; // an old connection we already replaced
    _sub?.cancel();
    client.close();
    if (_closed) return;
    onConnection?.call(false);
    final secs = [1, 2, 4, 8, 15, 30][_attempt.clamp(0, 5)];
    _attempt++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: secs), _connect);
  }

  void _dispatch(String event, String raw) {
    if (event == 'keep-alive' || raw.isEmpty) return;
    if (event == 'cancel' || event == 'auth_revoked') {
      final c = _client;
      if (c != null) _fail(c);
      return;
    }
    if (event != 'put' && event != 'patch') return;
    dynamic msg;
    try {
      msg = jsonDecode(raw);
    } catch (_) {
      return;
    }
    if (msg is! Map) return;
    final p = '${msg['path'] ?? '/'}';
    final d = msg['data'];
    if (event == 'put') {
      _value = _setAt(_value, _segments(p), d);
    } else if (d is Map) {
      for (final e in d.entries) {
        _value = _setAt(_value, [..._segments(p), ..._segments('${e.key}')], e.value);
      }
    }
    onValue(_value);
  }

  static List<String> _segments(String p) => p.split('/').where((s) => s.isNotEmpty).toList();

  static dynamic _setAt(dynamic node, List<String> segs, dynamic value) {
    if (segs.isEmpty) return value;
    Map<String, dynamic> map;
    if (node is Map) {
      map = node.map((k, v) => MapEntry('$k', v));
    } else if (node is List) {
      map = {for (var i = 0; i < node.length; i++) if (node[i] != null) '$i': node[i]};
    } else {
      map = {};
    }
    final key = segs.first;
    final child = _setAt(map[key], segs.sublist(1), value);
    if (child == null || (child is Map && child.isEmpty)) {
      map.remove(key);
    } else {
      map[key] = child;
    }
    return map.isEmpty ? null : map;
  }
}
