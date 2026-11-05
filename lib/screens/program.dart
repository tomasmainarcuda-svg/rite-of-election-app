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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              // The booklet "page": like the printed worship aid (web app's .libreto).
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFECE4D3)),
                ),
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
        ),
        if (nowSec != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 14,
            child: Center(
              child: Material(
                color: C.green,
                shape: const StadiumBorder(),
                elevation: 4,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => _jump(nowSec.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.circle, size: 10, color: Color(0xFFFF6B6B)),
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
  Widget _cover(I18n i) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Column(children: [
          // Diocese logo with its lettering (official branding), like the web app.
          Image.asset('assets/images/dpc-logo.png', width: 210, errorBuilder: (_, __, ___) => const AssetLogo('diocese-logo.png', height: 70)),
          const SizedBox(height: 14),
          Text('${i.pick(LibretoCover.title)}\n${i.pick(LibretoCover.title2)}',
              textAlign: TextAlign.center, style: T.serif(28, color: C.green, weight: FontWeight.w700).copyWith(height: 1.15)),
          const SizedBox(height: 16),
          Text(formatEventDate(i.lang).toUpperCase(), textAlign: TextAlign.center, style: T.head(14, weight: FontWeight.w700, spacing: 0.6)),
          const SizedBox(height: 4),
          Text('Chase Field', style: T.serif(24, weight: FontWeight.w700)),
          Text(LibretoCover.address, textAlign: TextAlign.center, style: T.serif(13.5, color: C.muted)),
          Container(width: 120, height: 2, color: C.gold, margin: const EdgeInsets.symmetric(vertical: 14)),
          Text(i.pick(LibretoCover.presides).toUpperCase(), style: T.head(11.5, color: C.muted, weight: FontWeight.w400, spacing: 0.9)),
          const SizedBox(height: 4),
          Text(i.pick(LibretoCover.bishop), textAlign: TextAlign.center, style: T.serif(21, color: C.green, weight: FontWeight.w700)),
          Text(i.pick(LibretoCover.bishopRole), style: T.serif(15)),
          const SizedBox(height: 18),
          Text(i.pick(LibretoCover.foot).toUpperCase(), textAlign: TextAlign.center, style: T.head(11.5, color: C.muted, weight: FontWeight.w400, spacing: 0.9)),
        ]),
      );

  /// Small caps like the printed booklet ("Ritos iniciales" → RITOS INICIALES with smaller
  /// lowercase letters). Done by hand so it works with any serif font.
  Widget _smallCaps(String text, double size, Color color, {TextAlign align = TextAlign.start}) {
    final spans = <TextSpan>[];
    final buf = StringBuffer();
    bool? lower;
    void flush() {
      if (buf.isEmpty) return;
      spans.add(TextSpan(text: buf.toString().toUpperCase(), style: TextStyle(fontSize: lower == true ? size * 0.78 : size)));
      buf.clear();
    }

    for (final ch in text.split('')) {
      final isLower = ch != ch.toUpperCase();
      if (lower != null && isLower != lower) flush();
      lower = isLower;
      buf.write(ch);
    }
    flush();
    return Text.rich(TextSpan(style: T.serif(size, color: color).copyWith(letterSpacing: 0.4, height: 1.25), children: spans), textAlign: align);
  }

  Widget _partTitle(I18n i, LbPart p) => Container(
        margin: const EdgeInsets.only(top: 30, bottom: 6),
        padding: const EdgeInsets.only(top: 18),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
        child: Column(children: [
          _smallCaps(i.pick(p.title), 22, C.green, align: TextAlign.center),
          if (p.sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(i.pick(p.sub).toUpperCase(), textAlign: TextAlign.center, style: T.head(11, color: C.gold, weight: FontWeight.w700, spacing: 1.3)),
            ),
        ]),
      );

  /* ------------------------------------------------------------- section */
  Widget _section(I18n i, LbSection s, dynamic c, bool isNow) {
    final staffText = c is Map && c['text'] is String && (c['text'] as String).trim().isNotEmpty ? c['text'] as String : null;
    final imgs = c is Map ? _strings(c['imgs']) : const <String>[];
    final credit = c is Map && c['credit'] is String ? c['credit'] as String : '';
    final blocks = staffText != null ? <Block>[if (s.hasMusic) M] : s.blocks;

    // Live "now": thin red bar on the left + pulsing red dot after the title (like the web app).
    return Container(
      key: _keys[s.id],
      padding: const EdgeInsets.only(top: 4, bottom: 6, left: 10),
      transform: Matrix4.translationValues(-10, 0, 0),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: isNow ? _red : Colors.transparent, width: 3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Flexible(child: _smallCaps(i.pick(s.title), 19, C.green)),
          if (isNow) ...[
            const SizedBox(width: 8),
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: _red, shape: BoxShape.circle)),
          ],
        ]),
        if (s.ref != null) Padding(padding: const EdgeInsets.only(top: 2, bottom: 4), child: Text(i.pick(s.ref), style: T.serif(14.5, weight: FontWeight.w700))),
        if (staffText != null) ..._staffText(staffText),
        for (final b in blocks) _block(i, b, s, {'imgs': imgs, 'credit': credit}),
      ]),
    );
  }

  static const _paper = Color(0xFFFBF8F1);
  static const _red = Color(0xFFD93A3A);
  static const _rubric = Color(0xFF77736A);

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

  Widget _pad(Widget w, [double v = 6]) => Padding(padding: EdgeInsets.symmetric(vertical: v), child: w);

  TextStyle get _body => T.serif(16).copyWith(height: 1.55);

  Widget _block(I18n i, Block b, LbSection? s, Map<String, Object> c) {
    final text = b.v == null ? '' : i.pick(b.v);
    switch (b.t) {
      case 'p':
        return _pad(_md(text, _body));
      case 'strong':
        return _pad(_md(text, _body.copyWith(fontWeight: FontWeight.w700)));
      case 'rubric':
        return _pad(_md(text, T.serif(15, color: _rubric, italic: true)));
      case 'note':
        return _pad(_md(text, T.serif(13.5, color: const Color(0xFF8A867C))), 8);
      case 'label':
        return Padding(padding: const EdgeInsets.only(top: 10, bottom: 2), child: _md(text, _body.copyWith(fontWeight: FontWeight.w700)));
      case 'center':
        return _pad(_md(text, _body, align: TextAlign.center), 10);
      case 'resp':
        return _pad(_resp(i.pick(b.who), text, people: true), 8);
      case 'list':
        return _pad(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var n = 0; n < b.items.length; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 26,
                  child: Padding(padding: const EdgeInsets.only(top: 3), child: Text((n + 1).toString().padLeft(2, '0'), style: T.head(12, color: C.gold, weight: FontWeight.w700))),
                ),
                Expanded(child: _md(i.pick(b.items[n]), _body)),
              ]),
            ),
        ]));
      case 'songs':
        // Song list: tap → jumps to the song (dashed lines, gold ↓ like the booklet).
        return _pad(Column(children: [
          for (final song in b.songs)
            InkWell(
              onTap: () => _jump(song.to),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE3DCCD)))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.pick(song.label), style: T.serif(14, weight: FontWeight.w700)),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: i.pick(song.song), style: T.serif(14.5, color: const Color(0xFF6F6A5E))),
                    TextSpan(text: ' ↓', style: T.serif(14.5, color: C.gold)),
                  ])),
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

  /// Who speaks (small, gold for the people) on top; what they say below (bold for the people).
  Widget _resp(String who, String say, {required bool people}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(who, style: T.head(11, color: people ? C.gold : C.muted, weight: FontWeight.w700, spacing: 0.9)),
        _md(say, people ? T.serif(17, weight: FontWeight.w700) : _body),
      ]);

  /// Staff-pasted text → paragraphs, rubrics (_text_ or > text) and dialogue lines (WHO: text).
  List<Widget> _staffText(String text) {
    final out = <Widget>[];
    var para = <String>[];
    void flush() {
      if (para.isNotEmpty) out.add(_pad(Text(para.join('\n'), style: _body)));
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
        out.add(_pad(Text(rub.group(1)!, style: T.serif(15, color: _rubric, italic: true))));
        continue;
      }
      final m = RegExp(r'^([A-ZÁÉÍÓÚÑÜ][A-ZÁÉÍÓÚÑÜ .\/]{0,24}):\s*(.*)$').firstMatch(line);
      if (m != null) {
        flush();
        final who = m.group(1)!.trim();
        out.add(_pad(_resp(who, m.group(2)!, people: peopleSpeakers.contains(who.toUpperCase())), 8));
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
      if (s == null || !s.hasMusic) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFECE4D3))),
        child: Column(children: [
          for (var n = 0; n < 2; n++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(children: [for (var l = 0; l < 5; l++) Container(height: 1, margin: const EdgeInsets.only(top: 4), color: const Color(0xFFCFC6B2))]),
            ),
          Text(i.t('musicSoon'), style: T.body(12, color: C.muted)),
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
              // Printed straight on the page, no frame: the scan's white paper blends into the
              // booklet's paper (multiply), like the web app (Tomás, Oct 18).
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Stack(children: [
                  Image(image: img, width: double.infinity, fit: BoxFit.fitWidth, color: _paper, colorBlendMode: BlendMode.multiply),
                  const Positioned(right: 0, bottom: 0, child: Opacity(opacity: 0.55, child: Icon(Icons.open_in_full, color: C.muted, size: 16))),
                ]),
              ),
            );
          },
        ),
      if (credit.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2, bottom: 6), child: Text(credit, style: T.body(10.5, color: const Color(0xFF8F8A7C)).copyWith(height: 1.35))),
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
          automaticallyImplyLeading: false,
          title: Text(label, style: T.body(15, color: C.white)),
          // Big white round ✕ on the right, like the web app.
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Builder(
                builder: (ctx) => IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: C.white, foregroundColor: C.green),
                  icon: const Icon(Icons.close),
                  tooltip: i.s('Close', 'Cerrar'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
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
