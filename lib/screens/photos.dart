/*
 * Photos with the bishops — just two things (Tomás, Oct 18): pick your parish → see
 * your photo time and station. The parish is shared with Home and the Map.
 * Ported from js/screens/photos.js.
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

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  Timer? _tick;
  int _pop = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _count(Parish p, I18n i) {
    final now = DateTime.now().toUtc();
    final start = eventTime(p.photoStart);
    final end = eventTime(addMinutes(p.photoStart, Config.photoSlotMinutes));
    if (now.isBefore(start)) return relTime(start, i);
    if (now.isBefore(end)) return i.t('windowNow');
    return i.t('windowPassed');
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final i = app.i;
    final p = app.parish;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppCard(
          title: i.t('findPhotoTime'),
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
        if (p != null)
          // Make the change unmistakable (older users): the card pops in gold.
          TweenAnimationBuilder<double>(
            key: ValueKey('${p.id}-$_pop'),
            tween: Tween<double>(begin: _pop == 0 ? 1.0 : 0.0, end: 1.0),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: 0.94 + 0.06 * v, child: child),
            child: _timeCard(i, p),
          ),
      ],
    );
  }

  Widget _timeCard(I18n i, Parish p) {
    if (!p.hasAssignment) {
      return AppCard(
        title: i.t('yourPhotoTime'),
        child: Column(children: [
          Text(i.t('tbd'), style: T.head(28, color: C.green)),
          const SizedBox(height: 6),
          Text(i.t('photoTbd'), textAlign: TextAlign.center, style: T.body(14, color: C.muted)),
        ]),
      );
    }
    final end = addMinutes(p.photoStart, Config.photoSlotMinutes);
    Station? st;
    for (final s in stations) {
      if (s.id == p.station) st = s;
    }
    return AppCard(
      title: i.t('yourPhotoTime'),
      child: Column(children: [
        // Whose time this is, so it's obvious it changed with the parish (Tomás, Oct 18)
        Text(p.name, textAlign: TextAlign.center, style: T.body(16, weight: FontWeight.w700)),
        Text(p.city, textAlign: TextAlign.center, style: T.body(13.5, color: C.muted)),
        const SizedBox(height: 12),
        Text(formatTime(p.photoStart), style: T.head(48, color: C.green)),
        Text(i.t('windowRange', {'start': formatTime(p.photoStart), 'end': formatTime(end)}), style: T.body(14, color: C.muted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: const Color(0x22C59344), borderRadius: BorderRadius.circular(999)),
          child: Text(_count(p, i), style: T.head(15, color: C.goldDark, weight: FontWeight.w700)),
        ),
        const SizedBox(height: 14),
        // Where the photo is taken — the station on the field, NOT the parish's seats.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.t('photoLocation').toUpperCase(), style: T.label()),
            const SizedBox(height: 4),
            Text('${i.t('station')} ${p.station}', style: T.head(20, color: C.green)),
            if (st != null) Text(i.pick(st.bishop), style: T.head(17, color: C.green, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(i.pick(EventInfo.notePhotos), style: T.body(13, color: C.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        Text(i.pick(Config.photosReleaseNote), textAlign: TextAlign.center, style: T.serif(13.5, color: C.muted, italic: true)),
      ]),
    );
  }
}
