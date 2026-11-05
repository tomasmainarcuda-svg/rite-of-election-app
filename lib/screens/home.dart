/*
 * Home: countdown, today's schedule, "Find your seat" (my parish) and quick links.
 * Ported from the web app's js/screens/home.js.
 */
import 'dart:async';

import 'package:flutter/material.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../i18n.dart';
import '../state.dart';
import '../theme.dart';
import '../util/time.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  /// Switch to another tab/screen: 'program', 'photos', 'map', 'translate', 'news', 'commit', 'info'.
  final ValueChanged<String> onGo;
  const HomeScreen({super.key, required this.onGo});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _tick;
  int _pop = 0; // bumps when the parish changes → facts "pop" animation

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final i = app.i;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _hero(i),
        const SizedBox(height: 4),
        SectionTitle(i.t('todaySchedule')),
        for (final item in EventInfo.schedule) _AgendaCard(item: item, onGo: widget.onGo),
        const SizedBox(height: 6),
        AppCard(title: i.t('findSeat'), child: _parishCard(app)),
        AppCard(title: i.t('quickLinks'), child: _quickLinks(i)),
        TextButton(
          onPressed: app.toggleLang,
          child: Text(
            app.lang == 'es' ? 'Idioma: Español · Change language' : 'Language: English · Cambiar idioma',
            style: T.body(14, color: C.green, weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  /* ---------------------------------------------------------- countdown */
  Widget _hero(I18n i) {
    final doors = eventTime(EventInfo.schedule.first.time);
    final start = eventTime(EventInfo.liturgyStart);
    final end = start.add(const Duration(minutes: EventInfo.liturgyDurationMin));
    final now = DateTime.now().toUtc();

    Widget body;
    if (now.isBefore(end) && !now.isBefore(start)) {
      body = Text(i.t('cdNow'), textAlign: TextAlign.center, style: T.serif(20, color: C.white, italic: true));
    } else if (!now.isBefore(end)) {
      body = Text(i.t('cdAfter'), textAlign: TextAlign.center, style: T.serif(20, color: C.white, italic: true));
    } else {
      final target = now.isBefore(doors) ? doors : start;
      final label = now.isBefore(doors) ? i.t('cdDoors') : i.t('cdLiturgy');
      final left = target.difference(now).inSeconds;
      final s = left < 0 ? 0 : left;
      final units = [
        [s ~/ 86400, 'cdDays'],
        [(s % 86400) ~/ 3600, 'cdHours'],
        [(s % 3600) ~/ 60, 'cdMin'],
        [s % 60, 'cdSec'],
      ];
      body = Column(children: [
        Text(label, textAlign: TextAlign.center, style: T.serif(16, color: C.gold2, italic: true)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final u in units)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text('${u[0]}', style: T.head(28, color: C.white)),
                    Text(i.t(u[1] as String), style: T.body(12, color: C.gold2)),
                  ]),
                ),
              ),
          ],
        ),
      ]);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [C.green, C.green2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: [
        Text(formatEventDate(i.lang).toUpperCase(), textAlign: TextAlign.center, style: T.head(15, color: C.gold2, spacing: 1)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.place_outlined, size: 16, color: C.white),
          const SizedBox(width: 4),
          Text(EventInfo.venue, style: T.body(14, color: C.white)),
        ]),
        const SizedBox(height: 14),
        body,
      ]),
    );
  }

  /* --------------------------------------------------------- my parish */
  Widget _parishCard(AppState app) {
    final i = app.i;
    final p = app.parish;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(i.t('myParish').toUpperCase(), style: T.label()),
      const SizedBox(height: 6),
      ParishPicker(
        selectedId: app.parishId,
        onPick: (id) {
          app.setParish(id);
          setState(() => _pop++);
        },
      ),
      const SizedBox(height: 12),
      if (p == null)
        Text(i.t('myParishHint'), style: T.body(14, color: C.muted))
      else
        _details(i, p),
    ]);
  }

  Widget _details(I18n i, Parish p) {
    final ok = p.hasAssignment;
    final tbd = i.t('tbd');
    final end = ok ? addMinutes(p.photoStart, Config.photoSlotMinutes) : '';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TweenAnimationBuilder<double>(
        key: ValueKey(_pop),
        tween: Tween<double>(begin: _pop == 0 ? 1.0 : 0.92, end: 1.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Row(children: [
          Expanded(child: Fact(i.t('section'), ok ? p.section : tbd)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: Fact(i.t('photoTime'), ok ? '${formatTime(p.photoStart)}–${formatTime(end)}' : tbd)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: SmallButton(i.t('seeOnMap'), onTap: () => widget.onGo('map'))),
        const SizedBox(width: 10),
        Expanded(child: SmallButton(i.t('photoDetails'), gold: true, onTap: () => widget.onGo('photos'))),
      ]),
    ]);
  }

  /* -------------------------------------------------------- quick links */
  Widget _quickLinks(I18n i) {
    const quick = [
      ['program', 'tabProgram'],
      ['photos', 'tabPhotos'],
      ['translate', 'tabTranslate'],
      ['map', 'tabMap'],
      ['commit', 'navCommit'],
      ['info', 'navInfo'],
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: [
        for (final q in quick)
          Material(
            color: C.paper,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => widget.onGo(q[0]),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(routeIcon(q[0]), size: 28, color: C.green),
                const SizedBox(height: 6),
                Text(i.t(q[1]), textAlign: TextAlign.center, style: T.body(13, weight: FontWeight.w600)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Icons per screen (Material equivalents of the web app's SVG set).
IconData routeIcon(String route) => switch (route) {
      'home' => Icons.home_outlined,
      'program' => Icons.menu_book_outlined,
      'photos' => Icons.photo_camera_outlined,
      'translate' => Icons.headphones_outlined,
      'map' => Icons.map_outlined,
      'news' => Icons.newspaper_outlined,
      'commit' => Icons.favorite_border,
      'info' => Icons.info_outline,
      _ => Icons.circle_outlined,
    };

/* ------------------------------------------------------------ agenda card */
class _AgendaCard extends StatelessWidget {
  final ScheduleItem item;
  final ValueChanged<String> onGo;
  const _AgendaCard({required this.item, required this.onGo});

  Color get _accent => switch (item.accent) {
        'gold' => C.gold,
        'green2' => C.green2,
        'muted' => C.muted,
        _ => C.green,
      };

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final now = DateTime.now().toUtc();
    final start = eventTime(item.time);
    final end = eventTime(item.end.isNotEmpty ? item.end : item.time);
    final past = !now.isBefore(end);
    final live = !past && !now.isBefore(start);
    final t = formatTime(item.time).split(' ');

    return Opacity(
      opacity: past ? 0.55 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: C.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: live ? C.gold : C.cardBorder, width: live ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onGo(item.link),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 6, color: _accent),
              SizedBox(
                width: 76,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: t[0], style: T.head(20, color: C.green)),
                      TextSpan(text: ' ${t[1]}', style: T.head(11, color: C.muted)),
                    ])),
                    if (item.end.isNotEmpty) Text(formatTime(item.end), style: T.body(11.5, color: C.muted)),
                  ]),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(i.pick(item.title), style: T.body(16, weight: FontWeight.w700)),
                    Text(i.pick(item.desc), style: T.serif(14, color: C.muted, italic: true)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.place_outlined, size: 14, color: C.goldDark),
                      const SizedBox(width: 3),
                      Flexible(child: Text(i.pick(item.place), style: T.body(12.5, color: C.goldDark))),
                    ]),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (past || live)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: live ? C.gold : C.paper, borderRadius: BorderRadius.circular(999)),
                      child: Text(i.t(live ? 'agNow' : 'agEnded'), style: T.head(11, color: live ? C.white : C.muted, weight: FontWeight.w700)),
                    ),
                  const Icon(Icons.chevron_right, color: C.muted),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
