/*
 * Map: schematic (not to scale) of Chase Field for this event. Ported from
 * js/screens/map.js — same geometry, drawn as SVG (flutter_svg).
 *  - the user's parish section beats in gold;
 *  - tapping a legend item makes those places beat (never dims the rest);
 *  - tapping a section says which parish sits there;
 *  - Parking: the P icons beat, then Google Maps opens with directions.
 *
 * Geometry: home plate H at the bottom center. P(t, d, side): t = distance along the
 * foul line from home plate, d = offset away from the field, side L (3B) / R (1B).
 */
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'news.dart' show openLink;

/* ------------------------------------------------------------------ geometry */
class _Pt {
  final double x, y;
  const _Pt(this.x, this.y);
  String get s => '${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)}';
}

const _h = _Pt(200, 285);
const _line = 160.0;
final _r2 = math.sqrt1_2;
const _trackIn = 0.0, _trackOut = 18.0, _bowlIn = 18.0, _bowlOut = 56.0, _concourse = 66.0, _upper = 82.0, _gates = 98.0;
const _vbX = 0.0, _vbY = 55.0, _vbW = 400.0, _vbH = 345.0;

_Pt _p(double t, double d, String side) {
  final sx = side == 'L' ? -1 : 1;
  return _Pt(_h.x + sx * _r2 * t + sx * _r2 * d, _h.y - _r2 * t + _r2 * d);
}

String _band(double d, double tEnd) =>
    'M${_p(tEnd, d, 'L').s} L${_p(0, d, 'L').s} A$d $d 0 0 0 ${_p(0, d, 'R').s} L${_p(tEnd, d, 'R').s}';

List<_Pt> _quadPts(double t1, double t2, double d1, double d2, String side) =>
    [_p(t1, d1, side), _p(t2, d1, side), _p(t2, d2, side), _p(t1, d2, side)];

String _quad(double t1, double t2, double d1, double d2, String side) {
  final q = _quadPts(t1, t2, d1, d2, side);
  return 'M${q[0].s} L${q[1].s} L${q[2].s} L${q[3].s} Z';
}

String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

/// Parish sections drawn on the 3B side, home plate → left field.
class _Sec {
  final String n;
  final List<_Pt> poly;
  final _Pt center;
  const _Sec(this.n, this.poly, this.center);
}

List<_Sec> _sections() {
  const t0 = 4.0;
  final step = (_line + 16 - t0) / lowerSections.length;
  return [
    for (var i = 0; i < lowerSections.length; i++)
      () {
        final a = t0 + i * step;
        final b = a + step - 1.4;
        return _Sec(lowerSections[i], _quadPts(a, b, _bowlIn + 1, _bowlOut - 1, 'L'), _p((a + b) / 2, (_bowlIn + _bowlOut) / 2, 'L'));
      }(),
  ];
}

final _secs = _sections();

bool _inside(_Pt p, List<_Pt> poly) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final a = poly[i], b = poly[j];
    if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) inside = !inside;
  }
  return inside;
}

/* ------------------------------------------------------------------- the SVG */
const _green = '#1F4A3B', _green2 = '#2A5E4B', _gold = '#C59344', _gold2 = '#E2BE7C', _ink = '#1D2B25', _blue = '#2F6FB5';
const _font = 'font-family="Roboto Condensed, Arial Narrow, sans-serif" font-weight="700"';

String _buildSvg(I18n i, {required String mySection, required int myStation, required String focus, required bool beat}) {
  final lf = _p(_line, 0, 'L'), rf = _p(_line, 0, 'R');
  final first = _p(60, 0, 'R'), third = _p(60, 0, 'L');
  final second = _Pt(_h.x, _h.y - 2 * _r2 * 60);
  bool on(String layer) => beat && focus == layer;
  final o = StringBuffer('<svg xmlns="http://www.w3.org/2000/svg" viewBox="$_vbX $_vbY $_vbW $_vbH">');
  String label(_Pt p, String text, {String fill = _green, double size = 7.5}) =>
      '<text x="${p.x.toStringAsFixed(1)}" y="${p.y.toStringAsFixed(1)}" $_font font-size="$size" fill="$fill" text-anchor="middle">${_esc(text)}</text>';

  // Upper level (contingency) + label below it
  o.write('<path d="${_band(_upper, 172)}" fill="none" stroke="$_gold2" stroke-width="12" stroke-opacity=".75" stroke-linejoin="round"/>');
  o.write(label(const _Pt(200, 381), i.t('mapUpperShort')));
  // Main concourse
  o.write('<path d="${_band(_concourse, 175)}" fill="none" stroke="$_green2" stroke-width="3" stroke-dasharray="6 4" stroke-linecap="round"/>');
  // Lower bowl band
  const mid = (_bowlIn + _bowlOut) / 2;
  o.write('<path d="${_band(mid, 175)}" fill="none" stroke="$_gold" stroke-opacity=".35" stroke-width="${_bowlOut - _bowlIn + 2}"/>');
  o.write('<path d="${_band(mid, 175)}" fill="none" stroke="#FFFFFF" stroke-width="${_bowlOut - _bowlIn}"/>');

  // Field
  o.write('<path d="M${_h.s} L${lf.s} Q200 0 ${rf.s} Z" fill="$_green2"/>');
  o.write('<path d="M${lf.s} Q200 0 ${rf.s}" fill="none" stroke="$_gold2" stroke-width="8"/>');
  o.write('<path d="${_quad(-2, _line, _trackIn, _trackOut, 'L')}" fill="$_gold2" fill-opacity=".55"/>');
  o.write('<path d="${_quad(-2, _line, _trackIn, _trackOut, 'R')}" fill="$_gold2" fill-opacity=".55"/>');
  o.write('<path d="M${_h.s} L${_p(68, -6, 'R').s} L${_Pt(_h.x, _h.y - 2 * _r2 * 68 - 6).s} L${_p(68, -6, 'L').s} Z" fill="$_gold2"/>');
  o.write('<path d="M${lf.s} L${_h.s} L${rf.s}" fill="none" stroke="#FFFFFF" stroke-width="1.5"/>');
  for (final b in [first, second, third]) {
    o.write('<rect x="${(b.x - 3).toStringAsFixed(1)}" y="${(b.y - 3).toStringAsFixed(1)}" width="6" height="6" fill="#FFFFFF" transform="rotate(45 ${b.x.toStringAsFixed(1)} ${b.y.toStringAsFixed(1)})"/>');
  }
  o.write('<path d="M${_h.x - 4} ${_h.y - 3} h8 v4 l-4 4 l-4 -4 z" fill="#FFFFFF"/>');
  o.write(label(const _Pt(200, 128), i.t('mapNoGrass'), fill: '#FFFFFF'));

  // Stage: foul territory between home plate and the left-field foul pole
  final st = _p(85, 9, 'L');
  o.write('<g transform="translate(${st.x.toStringAsFixed(1)},${st.y.toStringAsFixed(1)}) rotate(45)">'
      '<rect x="-26" y="-7" width="52" height="14" rx="2" fill="$_green" stroke="$_gold" stroke-width="2"/>'
      '<text x="0" y="3" $_font font-size="7.5" fill="#FFFFFF" text-anchor="middle">${_esc(i.t('mapStageShort'))}</text></g>');

  // Parish sections (the user's one last, so it's on top)
  final seatsOn = on('seating');
  final ordered = [..._secs.where((s) => s.n != mySection), ..._secs.where((s) => s.n == mySection)];
  for (final s in ordered) {
    final mine = s.n == mySection;
    final fill = mine ? (beat ? _gold2 : _gold) : (seatsOn ? '#F3DFB4' : '#FFFFFF');
    final stroke = mine || seatsOn ? _green : _gold;
    final sw = mine ? (beat ? 3.5 : 2.2) : (seatsOn ? 1.4 : 0.8);
    final q = s.poly;
    o.write('<path d="M${q[0].s} L${q[1].s} L${q[2].s} L${q[3].s} Z" fill="$fill" stroke="$stroke" stroke-width="$sw"/>');
    o.write('<text x="${s.center.x.toStringAsFixed(1)}" y="${(s.center.y + 3).toStringAsFixed(1)}" $_font font-size="${mine && beat ? 10 : 8}" fill="${mine ? _green : _ink}" text-anchor="middle">${_esc(s.n)}</text>');
  }

  // Ministry tables behind home plate
  for (final dx in [-14, -4, 6]) {
    o.write('<rect x="${_h.x + dx}" y="${_h.y + _concourse - 3}" width="8" height="6" rx="1" fill="$_gold" stroke="$_green" stroke-width="1"/>');
  }

  // Photo stations + flow on the warning track, home plate → right field
  o.write('<path d="${_quad(20, _line - 4, _trackIn + 2, _trackOut - 2, 'R')}" fill="$_gold" fill-opacity=".45"/>');
  final f1 = _p(22, _concourse, 'R'), f2 = _p(28, 13, 'R'), f3 = _p(148, 13, 'R'), f4 = _p(165, _concourse, 'R');
  o.write('<path d="M${f1.s} L${f2.s} L${f3.s} L${f4.s}" fill="none" stroke="$_green" stroke-width="2" stroke-dasharray="4 3"/>');
  // arrow head at the end of the flow
  final ang = math.atan2(f4.y - f3.y, f4.x - f3.x);
  _Pt rot(double dx, double dy) => _Pt(f4.x + dx * math.cos(ang) - dy * math.sin(ang), f4.y + dx * math.sin(ang) + dy * math.cos(ang));
  o.write('<path d="M${rot(0, 0).s} L${rot(-6, -3.5).s} L${rot(-6, 3.5).s} Z" fill="$_green"/>');
  o.write(label(_p(12, _concourse + 7, 'R'), i.t('mapIn')));
  o.write(label(_p(176, _concourse + 7, 'R'), i.t('mapOut')));
  for (var n = 0; n < stations.length; n++) {
    final s = stations[n];
    final c = _p(62 + n * 34.0, 9, 'R');
    final mine = s.id == myStation;
    o.write('<circle cx="${c.x.toStringAsFixed(1)}" cy="${c.y.toStringAsFixed(1)}" r="${mine ? 10 : 8}" fill="${mine ? _green : _gold}" stroke="${mine ? _gold2 : _green}" stroke-width="${mine ? 2.5 : 1.5}"/>');
    o.write('<text x="${c.x.toStringAsFixed(1)}" y="${(c.y + 3.5).toStringAsFixed(1)}" $_font font-size="9" fill="${mine ? _gold2 : _green}" text-anchor="middle">${s.id}</text>');
  }

  // Restrooms on the concourse
  final wcOn = on('restrooms');
  for (final p in [_p(50, _concourse, 'L'), _p(130, _concourse, 'L'), _p(60, _concourse, 'R'), _p(130, _concourse, 'R')]) {
    o.write('<circle cx="${p.x.toStringAsFixed(1)}" cy="${p.y.toStringAsFixed(1)}" r="${wcOn ? 9.5 : 7}" fill="${focus == 'restrooms' ? _green : '#FFFFFF'}" stroke="${focus == 'restrooms' ? _gold : _green}" stroke-width="1.4"/>');
    o.write('<text x="${p.x.toStringAsFixed(1)}" y="${(p.y + 2.2).toStringAsFixed(1)}" $_font font-size="5.5" fill="${focus == 'restrooms' ? '#FFFFFF' : _green}" text-anchor="middle">WC</text>');
  }
  // First aid
  final fa = _p(20, _concourse, 'L');
  final faR = on('firstaid') ? 10.0 : 7.5;
  o.write('<circle cx="${fa.x.toStringAsFixed(1)}" cy="${fa.y.toStringAsFixed(1)}" r="$faR" fill="$_green" stroke="${focus == 'firstaid' ? _gold : '#FFFFFF'}" stroke-width="1.5"/>');
  o.write('<path d="M${(fa.x - 4).toStringAsFixed(1)} ${fa.y.toStringAsFixed(1)} h8 M${fa.x.toStringAsFixed(1)} ${(fa.y - 4).toStringAsFixed(1)} v8" stroke="#FFFFFF" stroke-width="2.4"/>');

  // Parking: bottom corners, outside the gates (TBD confirm lots with the D-backs)
  final pS = on('parking') ? 13.0 : 9.0;
  for (final p in const [_Pt(52, 378), _Pt(348, 378)]) {
    o.write('<rect x="${p.x - pS}" y="${p.y - pS}" width="${2 * pS}" height="${2 * pS}" rx="4" fill="$_blue" stroke="${focus == 'parking' ? _gold : '#FFFFFF'}" stroke-width="1.5"/>');
    o.write('<text x="${p.x}" y="${p.y + 4.5}" $_font font-size="${on('parking') ? 16 : 12}" fill="#FFFFFF" text-anchor="middle">P</text>');
  }

  // Information booth
  final inf = _p(28, _concourse, 'R');
  final iR = on('info') ? 10.0 : 7.5;
  o.write('<circle cx="${inf.x.toStringAsFixed(1)}" cy="${inf.y.toStringAsFixed(1)}" r="$iR" fill="$_gold" stroke="$_green" stroke-width="1.5"/>');
  o.write('<text x="${inf.x.toStringAsFixed(1)}" y="${(inf.y + 3.6).toStringAsFixed(1)}" font-family="Georgia, serif" font-style="italic" font-weight="700" font-size="10" fill="$_green" text-anchor="middle">i</text>');

  // Food trucks: outer plaza, both sides (TBD confirm spots)
  final foodOn = on('food');
  for (final p in [_p(100, 91, 'L'), _p(100, 91, 'R')]) {
    final x = p.x - 10, y = p.y - 6;
    final body = foodOn ? _gold2 : _gold;
    o.write('<g transform="translate(${x.toStringAsFixed(1)},${y.toStringAsFixed(1)})${foodOn ? ' scale(1.3)' : ''}">'
        '<rect x="0" y="0" width="13" height="9" rx="1.5" fill="$body" stroke="$_green" stroke-width="1"/>'
        '<path d="M13 3 h4 l3 3 v3 h-7 z" fill="$_gold2" stroke="$_green" stroke-width="1"/>'
        '<circle cx="4" cy="10" r="2" fill="$_green"/><circle cx="16" cy="10" r="2" fill="$_green"/></g>');
  }

  // Entry gates
  final gatePos = {'home': _Pt(_h.x, _h.y + _gates + 8), 'left': _p(150, _gates, 'L'), 'right': _p(150, _gates, 'R')};
  for (final g in MapData.gates) {
    final p = gatePos[g.id];
    if (p == null) continue;
    o.write('<rect x="${(p.x - 8).toStringAsFixed(1)}" y="${(p.y - 8).toStringAsFixed(1)}" width="16" height="16" rx="4" fill="$_green" stroke="$_gold" stroke-width="1.5"/>');
    o.write('<text x="${p.x.toStringAsFixed(1)}" y="${(p.y + 3.5).toStringAsFixed(1)}" $_font font-size="9" fill="#FFFFFF" text-anchor="middle">${_esc(g.short)}</text>');
  }

  o.write('</svg>');
  return o.toString();
}

/* ------------------------------------------------------------------ the screen */
class _Legend {
  final String layer, label, desc;
  final IconData icon;
  const _Legend(this.layer, this.icon, this.label, this.desc);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _focus = '';
  String _detail = '';
  bool _beat = false;
  int _phase = 0;
  Timer? _timer, _mapsTimer;
  int _pop = 0;

  @override
  void initState() {
    super.initState();
    // "boom, boom, boom": a short beat every 1.3 s (like the web app's secPulse).
    _timer = Timer.periodic(const Duration(milliseconds: 130), (_) {
      _phase = (_phase + 1) % 10;
      final b = _phase == 1 || _phase == 2;
      if (b != _beat && mounted) setState(() => _beat = b);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapsTimer?.cancel();
    super.dispose();
  }

  List<_Legend> _items(I18n i) => [
        _Legend('food', Icons.local_shipping_outlined, i.t('legendFood'), i.t('legendFoodDesc')),
        _Legend('seating', Icons.event_seat_outlined, i.t('legendSeats'), i.t('legendSeatingDesc')),
        _Legend('restrooms', Icons.wc, i.t('legendRestrooms'), i.t('legendRestroomsDesc')),
        _Legend('parking', Icons.local_parking, i.t('legendParking'), i.t('legendParkingDesc')),
        _Legend('info', Icons.info_outline, i.t('legendInfo'), i.t('legendInfoDesc')),
        _Legend('firstaid', Icons.medical_services_outlined, i.t('legendFirstAidShort'), i.t('legendFirstAidDesc')),
      ];

  String get _parkingUrl =>
      'https://www.google.com/maps/dir/?api=1&destination=${MapData.parkingLat},${MapData.parkingLng}&travelmode=driving';

  void _setFocus(I18n i, String layer, {bool keepOn = false}) {
    _mapsTimer?.cancel();
    setState(() {
      _focus = (_focus == layer && !keepOn) ? '' : layer;
      final it = _items(i).where((x) => x.layer == _focus).firstOrNull;
      _detail = it == null ? '' : '${it.label}: ${it.desc}';
    });
    if (_focus == 'parking') {
      // The P icons beat, then Google Maps opens with directions (Tomás, Oct 28).
      _mapsTimer = Timer(const Duration(milliseconds: 900), () {
        if (_focus == 'parking' && mounted) openLink(_parkingUrl);
      });
    }
  }

  void _tapMap(I18n i, Offset local, Size size) {
    final p = _Pt(_vbX + local.dx * _vbW / size.width, _vbY + local.dy * _vbH / size.height);
    // Tap on a P → same as the Parking button (never turns it off)
    for (final c in const [_Pt(52, 378), _Pt(348, 378)]) {
      if ((p.x - c.x).abs() < 14 && (p.y - c.y).abs() < 14) return _setFocus(i, 'parking', keepOn: true);
    }
    for (final s in _secs) {
      if (_inside(p, s.poly)) {
        Parish? who;
        for (final x in parishes) {
          if (x.section == s.n) {
            who = x;
            break;
          }
        }
        setState(() => _detail = '${i.t('sectionN', {'n': s.n})} — ${who != null ? who.label : i.t('sectionOpen')}');
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final i = app.i;
    final parish = app.parish;
    final items = _items(i);
    final svg = _buildSvg(
      i,
      mySection: parish?.section ?? '',
      myStation: parish?.station ?? 0,
      focus: _focus,
      beat: _beat,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppCard(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AspectRatio(
              aspectRatio: _vbW / _vbH,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _tapMap(i, d.localPosition, box.biggest),
                  child: SvgPicture.string(svg, fit: BoxFit.fill),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(i.t('notToScale'), textAlign: TextAlign.center, style: T.body(12, color: C.muted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_detail.isEmpty ? i.t('mapTapHint') : _detail, style: T.body(14)),
                if (_focus == 'parking') ...[
                  const SizedBox(height: 4),
                  Text(i.t('mapOpeningMaps'), style: T.body(12.5, color: C.muted)),
                  const SizedBox(height: 8),
                  // Backup in case the phone blocks the automatic opening.
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: C.parking),
                    onPressed: () => openLink(_parkingUrl),
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: Text(i.t('mapDirections')),
                  ),
                ],
              ]),
            ),
          ]),
        ),
        // Parish banner: big section number (option B, Tomás Oct 16)
        if (parish != null)
          TweenAnimationBuilder<double>(
            key: ValueKey('${parish.id}-$_pop'),
            tween: Tween<double>(begin: _pop == 0 ? 1.0 : 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: 0.94 + 0.06 * v, child: child),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Column(children: [
                  Text(i.t('mapSection').toUpperCase(), style: T.label(color: C.gold2)),
                  Text(parish.section.isNotEmpty ? parish.section : '—', style: T.head(40, color: C.white)),
                ]),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(parish.name, style: T.body(16, color: C.white, weight: FontWeight.w700)),
                    Text(parish.section.isNotEmpty ? i.t('mapYourSpot') : i.t('tbd'), style: T.body(13.5, color: C.gold2)),
                  ]),
                ),
              ]),
            ),
          ),
        AppCard(
          title: i.t('findSection'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(i.t('yourParish').toUpperCase(), style: T.label()),
            const SizedBox(height: 6),
            ParishPicker(
              selectedId: app.parishId,
              onPick: (id) {
                app.setParish(id);
                setState(() => _pop++);
              },
            ),
          ]),
        ),
        AppCard(
          title: i.t('legend'),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            children: [
              for (final it in items)
                Material(
                  color: _focus == it.layer ? C.green : C.paper,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _setFocus(i, it.layer),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(it.icon, size: 28, color: _focus == it.layer ? C.gold2 : C.green),
                      const SizedBox(height: 4),
                      Text(it.label,
                          textAlign: TextAlign.center,
                          style: T.body(12.5, weight: FontWeight.w600, color: _focus == it.layer ? C.white : C.ink)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
