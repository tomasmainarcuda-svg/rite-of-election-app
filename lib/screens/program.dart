/*
 * Program = the worship aid (libreto) as continuous text, like the printed booklet.
 * Ported from js/screens/program.js:
 *  - official texts / sheet-music images come from the staff panel (Firebase), cached offline;
 *  - live: the section staff mark as "now" gets a red bar, the page follows it, and a
 *    "Now" button at the bottom jumps back to it;
 *  - pinch with two fingers to make the letters bigger (the text reflows; size remembered);
 *  - tap sheet music to see it full screen and zoom.
 */
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/libreto.dart';
import '../i18n.dart';
import '../services/live.dart';
import '../state.dart';
import '../theme.dart';
import '../util/time.dart';
import '../widgets/common.dart';

const _kZoom = 'roe.lbz';
const _zMin = 1.0, _zMax = 2.4;

class ProgramScreen extends StatefulWidget {
  const ProgramScreen({super.key});

  @override
  State<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends State<ProgramScreen> {
  final _scroll = ScrollController();
  final Map<String, GlobalKey> _keys = {for (final s in libretoSections) s.id: GlobalKey()};
  double _z = 1;
  String? _lastNow; // null until the first live value (no jump when opening the tab)

  // Two-finger pinch, tracked by hand so it never fights the scrolling.
  final Map<int, Offset> _pointers = {};
  double _d0 = 0, _z0 = 1;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final v = p.getDouble(_kZoom);
      if (v != null && mounted) setState(() => _z = v.clamp(_zMin, _zMax).toDouble());
    });
    Live.I.start();
    Live.I.state.addListener(_onLive);
  }

  @override
  void dispose() {
    Live.I.state.removeListener(_onLive);
    _scroll.dispose();
    super.dispose();
  }

  void _onLive() {
    final now = _nowId();
    if (_lastNow == null) {
      _lastNow = now;
    } else if (now != _lastNow) {
      // Follow the celebration when staff move to a new part.
      _lastNow = now;
      if (now.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _jump(now));
    }
    if (mounted) setState(() {});
  }

  String _nowId() {
    final id = Live.I.state.value.ritePartId;
    return libretoSections.any((s) => s.id == id) ? id : '';
  }

  void _jump(String id) {
    final ctx = _keys[id]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic, alignment: 0.02);
  }

  double _dist() {
    final p = _pointers.values.toList();
    return (p[0] - p[1]).distance;
  }

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2) {
      _d0 = _dist();
      _z0 = _z;
    }
  }

  void _move(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.position;
    if (_pointers.length == 2 && _d0 > 0) {
      setState(() => _z = (_z0 * _dist() / _d0).clamp(_zMin, _zMax).toDouble());
    }
  }

  void _up(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_pointers.length < 2 && _d0 > 0) {
      _d0 = 0;
      SharedPreferences.getInstance().then((p) => p.setDouble(_kZoom, _z));
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final nowId = _nowId();
    final LbSection? nowSec = libretoSections.where((s) => s.id == nowId).firstOrNull;

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: Live.I.libreto,
      builder: (context, content, _) => Stack(children: [
        Listener(
          onPointerDown: _down,
          onPointerMove: _move,
          onPointerUp: _up,
          onPointerCancel: _up,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_z)),
            child: SingleChildScrollView(
              controller: _scroll,
              physics: _pointers.length >= 2 ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _cover(i),
                for (final p in libretoParts) ...[
                  _partTitle(i, p),
                  for (final b in p.intro) _block(i, b, null, const {}),
                  for (final s in p.sections) _section(i, s, content[s.id], s.id == nowId),
                ],
              ]),
            ),
          ),
        ),
        if (nowSec != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: Material(
                color: C.red,
                shape: const StadiumBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _jump(nowSec.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.circle, size: 10, color: C.white),
                      const SizedBox(width: 8),
                      Text('${i.t('nowShort')}: ${i.pick(nowSec.title)}', style: T.head(15, color: C.white, weight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  /* --------------------------------------------------------------- cover */
  Widget _cover(I18n i) => Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          // Diocese logo with its lettering when available; otherwise the crest.
          Image.asset(
            'assets/images/dpc-logo.png',
            height: 56,
            errorBuilder: (_, __, ___) => const AssetLogo('diocese-logo.png', height: 56),
          ),
          const SizedBox(height: 14),
          Text(i.pick(LibretoCover.title).toUpperCase(), textAlign: TextAlign.center, style: T.head(28, color: C.white)),
          Text(i.pick(LibretoCover.title2), textAlign: TextAlign.center, style: T.serif(18, color: C.gold2, italic: true)),
          const SizedBox(height: 12),
          Text(formatEventDate(i.lang), textAlign: TextAlign.center, style: T.body(14, color: C.white, weight: FontWeight.w600)),
          Text('Chase Field', style: T.head(18, color: C.gold2)),
          Text(LibretoCover.address, textAlign: TextAlign.center, style: T.body(12, color: C.white)),
          Container(height: 1, width: 80, color: C.gold, margin: const EdgeInsets.symmetric(vertical: 14)),
          Text(i.pick(LibretoCover.presides), style: T.serif(13, color: C.gold2, italic: true)),
          Text(i.pick(LibretoCover.bishop), style: T.head(17, color: C.white)),
          Text(i.pick(LibretoCover.bishopRole), style: T.serif(13, color: C.white, italic: true)),
          const SizedBox(height: 14),
          Text(i.pick(LibretoCover.foot), style: T.body(11.5, color: C.gold2)),
        ]),
      );

  Widget _partTitle(I18n i, LbPart p) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(i.pick(p.title).toUpperCase(), style: T.head(22, color: C.green)),
          if (p.sub != null) Text(i.pick(p.sub), style: T.serif(14, color: C.goldDark, italic: true)),
          Container(height: 2, width: 48, color: C.gold, margin: const EdgeInsets.only(top: 6)),
        ]),
      );

  /* ------------------------------------------------------------- section */
  Widget _section(I18n i, LbSection s, dynamic c, bool isNow) {
    final staffText = c is Map && c['text'] is String && (c['text'] as String).trim().isNotEmpty ? c['text'] as String : null;
    final imgs = c is Map ? _strings(c['imgs']) : const <String>[];
    final credit = c is Map && c['credit'] is String ? c['credit'] as String : '';
    final blocks = staffText != null ? <Block>[if (s.hasMusic) M] : s.blocks;

    return Container(
      key: _keys[s.id],
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.only(left: isNow ? 12 : 0),
      decoration: BoxDecoration(border: isNow ? const Border(left: BorderSide(color: C.red, width: 4)) : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(i.pick(s.title), style: T.head(19, color: isNow ? C.red : C.ink)),
        if (s.ref != null) Text(i.pick(s.ref), style: T.serif(13.5, color: C.goldDark, italic: true)),
        const SizedBox(height: 6),
        if (staffText != null) ..._staffText(staffText),
        for (final b in blocks) _block(i, b, s, {'imgs': imgs, 'credit': credit}),
      ]),
    );
  }

  static List<String> _strings(dynamic v) {
    if (v is List) return v.whereType<String>().toList();
    if (v is Map) return v.values.whereType<String>().toList();
    return const [];
  }

  /// **bold** and line breaks.
  Widget _md(String text, TextStyle style, {TextAlign align = TextAlign.start}) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: style, children: spans), textAlign: align);
  }

  Widget _pad(Widget w) => Padding(padding: const EdgeInsets.only(bottom: 8), child: w);

  Widget _block(I18n i, Block b, LbSection? s, Map<String, Object> c) {
    final text = b.v == null ? '' : i.pick(b.v);
    switch (b.t) {
      case 'p':
        return _pad(_md(text, T.serif(16.5)));
      case 'strong':
        return _pad(_md(text, T.serif(16.5, weight: FontWeight.w700)));
      case 'rubric':
        return _pad(_md(text, T.serif(14.5, color: C.muted, italic: true)));
      case 'note':
        return _pad(_md(text, T.body(13, color: C.muted)));
      case 'label':
        return _pad(_md(text.toUpperCase(), T.label(color: C.goldDark)));
      case 'center':
        return _pad(_md(text, T.serif(16.5), align: TextAlign.center));
      case 'resp':
        return _pad(_resp(i.pick(b.who), text, people: true));
      case 'list':
        return _pad(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var n = 0; n < b.items.length; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 30, child: Text((n + 1).toString().padLeft(2, '0'), style: T.head(15, color: C.gold))),
                Expanded(child: _md(i.pick(b.items[n]), T.serif(16))),
              ]),
            ),
        ]));
      case 'songs':
        return _pad(Column(children: [
          for (final song in b.songs)
            InkWell(
              onTap: () => _jump(song.to),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(i.pick(song.label), style: T.body(14, weight: FontWeight.w700, color: C.green)),
                      Text(i.pick(song.song), style: T.serif(15, italic: true)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right, color: C.gold),
                ]),
              ),
            ),
        ]));
      case 'music':
        return _music(i, s, (c['imgs'] as List<String>?) ?? const [], (c['credit'] as String?) ?? '');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _resp(String who, String say, {required bool people}) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 2),
          child: Text(who, style: T.head(13, color: people ? C.goldDark : C.muted, weight: FontWeight.w700)),
        ),
        Expanded(child: _md(say, T.serif(16.5, weight: people ? FontWeight.w700 : FontWeight.w400))),
      ]);

  /// Staff-pasted text → paragraphs, rubrics (_text_ or > text) and dialogue lines (WHO: text).
  List<Widget> _staffText(String text) {
    final out = <Widget>[];
    var para = <String>[];
    void flush() {
      if (para.isNotEmpty) out.add(_pad(Text(para.join('\n'), style: T.serif(16.5))));
      para = [];
    }

    for (final raw in text.replaceAll('\r', '').split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        flush();
        continue;
      }
      final rub = RegExp(r'^_(.+)_$').firstMatch(line) ?? RegExp(r'^>\s*(.+)$').firstMatch(line);
      if (rub != null) {
        flush();
        out.add(_pad(Text(rub.group(1)!, style: T.serif(14.5, color: C.muted, italic: true))));
        continue;
      }
      final m = RegExp(r'^([A-ZÁÉÍÓÚÑÜ][A-ZÁÉÍÓÚÑÜ .\/]{0,24}):\s*(.*)$').firstMatch(line);
      if (m != null) {
        flush();
        final who = m.group(1)!.trim();
        out.add(_pad(_resp(who, m.group(2)!, people: peopleSpeakers.contains(who.toUpperCase()))));
        continue;
      }
      para.add(line);
    }
    flush();
    return out;
  }

  /* --------------------------------------------------------- sheet music */
  Widget _music(I18n i, LbSection? s, List<String> keys, String credit) {
    if (keys.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: C.cardSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.cardBorder)),
        child: Column(children: [
          for (var n = 0; n < 2; n++)
            Container(
              height: 18,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: C.cardBorder))),
            ),
          const SizedBox(height: 6),
          Text(i.t('musicSoon'), style: T.body(13, color: C.muted)),
        ]),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final k in keys)
        FutureBuilder<String?>(
          future: Live.I.image(k),
          builder: (context, snap) {
            final img = _imageFrom(snap.data);
            if (img == null) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: C.gold)));
            return GestureDetector(
              onTap: () => _zoom(context, i, img, s == null ? '' : i.pick(s.title)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.cardBorder)),
                clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  Image(image: img, width: double.infinity, fit: BoxFit.fitWidth),
                  const Positioned(right: 6, bottom: 6, child: Icon(Icons.zoom_out_map, color: C.goldDark, size: 20)),
                ]),
              ),
            );
          },
        ),
      if (credit.isNotEmpty) _pad(Text(credit, style: T.body(11, color: C.muted))),
    ]);
  }

  static ImageProvider? _imageFrom(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      try {
        return MemoryImage(base64Decode(url.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  void _zoom(BuildContext context, I18n i, ImageProvider img, String label) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: C.white,
          title: Text(label, style: T.body(15, color: C.white)),
        ),
        body: Column(children: [
          Expanded(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(child: Image(image: img, fit: BoxFit.contain, width: MediaQuery.of(context).size.width)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(i.t('musicTip'), textAlign: TextAlign.center, style: T.body(13, color: C.gold2)),
          ),
        ]),
      ),
    ));
  }
}
