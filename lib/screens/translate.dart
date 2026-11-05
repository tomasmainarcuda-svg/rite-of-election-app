/*
 * Translate: choose your language and see when the interpreter is on air.
 * Ported from js/screens/translate.js. The AUDIO itself (Amazon IVS / Cloudflare) comes
 * in a later step (Tomás, Nov 2026: "audio de traducción después"), so for now the
 * play button explains that.
 */
import 'package:flutter/material.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../i18n.dart';
import '../services/live.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    Live.I.start();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final i = app.i;
    // Default: the app's language (English = the ceremony itself, no channel).
    final selected = _selected ?? (app.lang == 'es' ? 'es' : 'en');
    final opts = <Channel>[englishOption, ...channels];

    return ValueListenableBuilder<Map<String, bool>>(
      valueListenable: Live.I.onair,
      builder: (context, onair, _) {
        final anyLive = channels.any((c) => onair[c.id] == true);
        final ch = opts.firstWhere((c) => c.id == selected, orElse: () => englishOption);
        final live = onair[ch.id] == true;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            AppCard(
              title: i.t('chooseChannel'),
              child: Column(children: [
                for (final c in opts) _channelRow(i, app, c, selected == c.id, onair[c.id] == true, anyLive),
              ]),
            ),
            AppCard(
              child: Column(children: [
                // Grey (looks off) until the interpreter is on air, like the web app;
                // green with a gold ring when there is something to listen to.
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: live ? C.green : const Color(0xFFAFC0B8),
                    border: Border.all(color: live ? C.gold : const Color(0xFFE9D9B8), width: 6),
                  ),
                  child: Icon(Icons.play_arrow_rounded, size: 64, color: live ? C.white : const Color(0xFFF3E6CC)),
                ),
                const SizedBox(height: 12),
                Text(
                  ch.none
                      ? i.s('Not available', 'No disponible')
                      : live
                          ? i.t('statusOnAir')
                          : i.t('statusNotLive'),
                  textAlign: TextAlign.center,
                  style: T.head(18, color: live ? C.red : C.green),
                ),
                const SizedBox(height: 6),
                Text(
                  i.s('Live audio arrives in the next version of the app.', 'El audio en vivo llega en la próxima versión de la app.'),
                  textAlign: TextAlign.center,
                  style: T.body(13, color: C.muted),
                ),
              ]),
            ),
            AppCard(
              title: i.s('How to listen', 'Cómo escuchar'),
              child: Column(children: [
                _step(1, Icons.play_circle_outline, i.s('Tap Play', 'Toca Play'), i.s('The round button above', 'El botón redondo de arriba')),
                _step(2, Icons.phone_in_talk_outlined, i.s('Hold the phone to your ear', 'Ponte el teléfono en la oreja'), i.s('Like a phone call', 'Como en una llamada')),
                _step(3, Icons.headphones_outlined, i.s('Have earbuds?', '¿Tienes auriculares?'),
                    i.s("Even better — you'll hear it clearer", 'Mejor todavía: escuchas más claro')),
              ]),
            ),
            // Separate dark-green TIP box (Tomás, Oct 18)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.lock_outline, color: C.gold2, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.s('Save battery', 'Ahorra batería').toUpperCase(), style: T.label(color: C.gold2)),
                    Text(i.s('You can lock your screen', 'Puedes bloquear la pantalla'), style: T.body(16, color: C.white, weight: FontWeight.w700)),
                    Text(i.s('The audio will keep playing', 'El audio seguirá sonando'), style: T.body(13.5, color: C.white)),
                  ]),
                ),
              ]),
            ),
          ],
        );
      },
    );
  }

  Widget _channelRow(I18n i, AppState app, Channel c, bool sel, bool live, bool anyLive) {
    final dim = anyLive && !live;
    return Opacity(
      opacity: dim ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: sel ? C.green : C.paper,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() => _selected = c.id);
              // The language also switches the whole app (only English/Spanish exist in it).
              if ((c.id == 'en' || c.id == 'es') && app.lang != c.id) app.setLang(c.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(Icons.translate, color: sel ? C.gold2 : C.green),
                const SizedBox(width: 12),
                Expanded(child: Text(c.label, style: T.head(19, color: sel ? C.white : C.ink))),
                if (live)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: C.red, borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.circle, size: 8, color: C.white),
                      const SizedBox(width: 5),
                      Text(i.s('LIVE', 'EN VIVO'), style: T.head(12, color: C.white, weight: FontWeight.w700)),
                    ]),
                  )
                else
                  Text(
                    c.none ? i.s('Not available', 'No disponible') : i.t('statusNotLive'),
                    style: T.body(12.5, color: sel ? C.gold2 : C.muted),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _step(int n, IconData icon, String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: C.green, size: 28),
            ),
            Positioned(
              left: -6,
              top: -6,
              child: CircleAvatar(radius: 11, backgroundColor: C.gold, child: Text('$n', style: T.head(12, color: C.white))),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.body(16, weight: FontWeight.w700)),
              Text(sub, style: T.body(13.5, color: C.muted)),
            ]),
          ),
        ]),
      );
}
