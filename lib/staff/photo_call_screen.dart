/*
 * STAFF APP — "Llamado a fotos" screen (approved mockup, Nov 6).
 * One card per station: AHORA (big group + parish), guide time, SIGUE (next group),
 * big green "SIGUIENTE GRUPO" + small "↩" to undo. "ESTACIÓN TERMINADA" at the end.
 * Tablet landscape: the 3 cards side by side; phone: stacked.
 */
import 'package:flutter/material.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../i18n.dart';
import '../services/photo_calls.dart';
import '../state.dart';
import '../theme.dart';
import '../util/time.dart';
import '../widgets/common.dart';

class PhotoCallScreen extends StatefulWidget {
  const PhotoCallScreen({super.key});

  @override
  State<PhotoCallScreen> createState() => _PhotoCallScreenState();
}

class _PhotoCallScreenState extends State<PhotoCallScreen> {
  // (Clock removed from the header — Tomás, Nov 8.)

  Future<void> _confirmReset(I18n i) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i.s('Start over?', '¿Empezar de nuevo?')),
        content: Text(i.s('All 3 stations go back to their first group.', 'Las 3 estaciones vuelven a su primer grupo.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(i.s('Cancel', 'Cancelar'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(i.s('Start over', 'Empezar de nuevo')),
          ),
        ],
      ),
    );
    if (ok == true) PhotoCalls.I.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    return Scaffold(
      backgroundColor: C.paper,
      body: Column(children: [
        // Green header with title and the TILMA logo (top right, like every screen).
        Container(
          color: C.green,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(i.s('Staff · The Rite of Election', 'Staff · El Rito de Elección'), style: T.serif(14, color: C.gold2, italic: true)),
                    Text(i.s('PHOTO CALLS', 'LLAMADO A FOTOS'), style: T.head(26, color: C.white)),
                  ]),
                ),
                const AssetLogo('tilma-logo.webp', height: 44),
              ]),
            ),
          ),
        ),
        // Status bar: are the taps being sent? (signed in → LIVE; otherwise TEST MODE + sign-in)
        _StatusBar(i: i),
        Expanded(
          child: ValueListenableBuilder<Map<int, int>>(
            valueListenable: PhotoCalls.I.pos,
            builder: (context, _, __) => LayoutBuilder(builder: (context, box) {
              final wide = box.maxWidth >= 820;
              final cards = [for (final s in stations) _StationCard(station: s, i: i)];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (wide)
                    IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (var n = 0; n < cards.length; n++) ...[
                          if (n > 0) const SizedBox(width: 16),
                          Expanded(child: cards[n]),
                        ],
                      ]),
                    )
                  else
                    for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
                  const SizedBox(height: 8),
                  Text(
                    i.s('One person runs the 3 stations. "Next" calls the next group in line; "↩" undoes a mistake.',
                        'Una sola persona opera las 3 estaciones. "Siguiente" llama al próximo grupo de la fila; "↩" corrige si te pasaste.'),
                    textAlign: TextAlign.center,
                    style: T.body(12.5, color: C.muted),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _confirmReset(i),
                      icon: const Icon(Icons.restart_alt, size: 18, color: C.muted),
                      label: Text(i.s('Start over', 'Empezar de nuevo'), style: T.body(13, color: C.muted)),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ]),
    );
  }
}

class _StationCard extends StatelessWidget {
  final Station station;
  final I18n i;
  const _StationCard({required this.station, required this.i});

  String _parish(Parish p) => '${p.name} · ${p.city}';

  @override
  Widget build(BuildContext context) {
    final pc = PhotoCalls.I;
    final done = pc.done(station.id);
    final now = pc.now(station.id);
    final next = pc.next(station.id);
    final total = pc.queue(station.id).length;
    final at = pc.pos.value[station.id] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6DDCB)),
        boxShadow: const [BoxShadow(color: Color(0x141F4A3B), blurRadius: 18, offset: Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: C.green2,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.s('Station ${station.id}', 'Estación ${station.id}'), style: T.head(20, color: C.white)),
                Text(i.pick(station.bishop), style: T.body(13, color: C.gold2)),
              ]),
            ),
            Text('${at.clamp(0, total)}/$total', style: T.head(14, color: C.gold2, weight: FontWeight.w700)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(children: [
            if (now == null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(999)),
                child: Text(i.s('STATION FINISHED', 'ESTACIÓN TERMINADA'), style: T.head(14, color: C.white, weight: FontWeight.w800, spacing: 1)),
              ),
              const SizedBox(height: 10),
              Text(i.s('Every group has gone through.', 'Todos los grupos ya pasaron.'), style: T.body(15)),
            ] else ...[
              Text(i.s('NOW CALLING', 'AHORA LLAMANDO'), style: T.label()),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(i.s('Group ${now.group}', 'Grupo ${now.group}'), style: T.head(56, color: C.green).copyWith(height: 1)),
              ),
              const SizedBox(height: 6),
              Text(_parish(now), textAlign: TextAlign.center, style: T.body(15, color: C.goldDark, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(i.s('Guide time: ${formatTime(now.photoStart)}', 'Horario guía: ${formatTime(now.photoStart)}'), style: T.body(13, color: C.muted)),
            ],
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                Text(i.s('NEXT', 'SIGUE'), style: T.label()),
                const SizedBox(height: 2),
                Text(
                  next != null
                      ? i.s('Group ${next.group} · ${next.name}', 'Grupo ${next.group} · ${next.name}')
                      : (done ? '—' : i.s('Last group in line', 'Último grupo de la fila')),
                  textAlign: TextAlign.center,
                  style: T.body(14, color: C.muted),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              SizedBox(
                width: 54,
                height: 54,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    side: const BorderSide(color: Color(0xFFD9CFBB), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: at > 0 ? () => pc.back(station.id) : null,
                  child: Semantics(label: i.s('Back', 'Atrás'), child: const Icon(Icons.undo, color: C.muted)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.green,
                      disabledBackgroundColor: const Color(0xFFCFD8D3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: done ? null : () => pc.advance(station.id),
                    child: Text(i.s('NEXT GROUP', 'SIGUIENTE GRUPO'), style: T.head(19, color: C.white, weight: FontWeight.w800, spacing: .5)),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// Says clearly whether the taps reach Firebase, and lets the staff sign in / out.
class _StatusBar extends StatelessWidget {
  final I18n i;
  const _StatusBar({required this.i});

  @override
  Widget build(BuildContext context) {
    final pc = PhotoCalls.I;
    return AnimatedBuilder(
      animation: Listenable.merge([pc.user, pc.sent, pc.problem]),
      builder: (context, _) {
        final u = pc.user.value;
        final failed = pc.sent.value == false;
        final live = u != null && !failed;
        final bg = failed ? C.red : (live ? const Color(0xFF2E7D32) : C.gold2);
        final fg = (failed || live) ? C.white : const Color(0xFF5A3E12);
        final text = failed
            ? i.s('NOT SENT · this account has no staff permission', 'NO SE ENVIÓ · esta cuenta no tiene permiso de staff')
            : live
                ? i.s('LIVE · every tap goes to the participants\' app · ${u?.email ?? ''}',
                    'EN VIVO · cada toque se envía a la app de la gente · ${u?.email ?? ''}')
                : i.s('TEST MODE · nothing is sent · sign in with the staff Google account to send',
                    'MODO PRUEBA · no se envía nada · entrá con el Google del staff para enviar');
        return Container(
          width: double.infinity,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                if (live) const Icon(Icons.circle, size: 10, color: C.white),
                Text(text, textAlign: TextAlign.center, style: T.body(13, color: fg, weight: FontWeight.w700)),
                if (u == null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.green,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: pc.signIn,
                    icon: const Icon(Icons.login, size: 16),
                    label: Text(i.s('Sign in with Google', 'Entrar con Google')),
                  )
                else
                  TextButton(
                    onPressed: pc.signOut,
                    style: TextButton.styleFrom(foregroundColor: fg, visualDensity: VisualDensity.compact),
                    child: Text(i.s('Sign out', 'Salir')),
                  ),
              ],
            ),
            if (pc.problem.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(pc.problem.value!, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.body(11.5, color: fg)),
              ),
          ]),
        );
      },
    );
  }
}
