/*
 * Shared building blocks: cards, section titles, logos and the parish picker.
 */
import 'package:flutter/material.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../state.dart';
import '../theme.dart';

/// White card with the gold-tinted border used all over the web app.
class AppCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const AppCard({super.key, this.title, required this.child, this.padding = const EdgeInsets.all(16), this.color = C.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.cardBorder),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!.toUpperCase(), style: T.head(17, color: C.green)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
        child: Text(text.toUpperCase(), style: T.head(17, color: C.green)),
      );
}

/// Image from assets/images; if the file is missing the app simply hides it.
class AssetLogo extends StatelessWidget {
  final String file;
  final double height;
  const AssetLogo(this.file, {super.key, required this.height});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/$file',
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(height: height),
      );
}

/// Small rounded button (green, or gold).
class SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool gold;
  const SmallButton(this.label, {super.key, required this.onTap, this.gold = false});

  @override
  Widget build(BuildContext context) => Material(
        color: gold ? C.gold : C.green,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(label, textAlign: TextAlign.center, style: T.head(14, color: C.white, weight: FontWeight.w700)),
          ),
        ),
      );
}

/// "Section 124" / "Photo time 9:00–9:30 AM" fact box.
class Fact extends StatelessWidget {
  final String label, value;
  const Fact(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: C.paper, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: T.label()),
            const SizedBox(height: 4),
            Text(value, style: T.head(20, color: C.green)),
          ],
        ),
      );
}

/// Parish picker. The list unfolds right under the button, on the same page
/// (Tomás, Oct 18: a full-screen sheet made people feel lost).
class ParishPicker extends StatefulWidget {
  final String selectedId;
  final ValueChanged<String> onPick;
  const ParishPicker({super.key, required this.selectedId, required this.onPick});

  @override
  State<ParishPicker> createState() => _ParishPickerState();
}

class _ParishPickerState extends State<ParishPicker> {
  bool _open = false;
  String _q = '';

  static String _key(Parish p) =>
      '${p.name.replaceFirst(RegExp(r'^Saint\s+', caseSensitive: false), 'St. ').replaceFirst(RegExp(r'^Ss\.\s+'), 'St. ')} ${p.city}'.toLowerCase();

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áà]'), 'a')
      .replaceAll(RegExp('[éè]'), 'e')
      .replaceAll(RegExp('[íì]'), 'i')
      .replaceAll(RegExp('[óò]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .replaceAll('ñ', 'n');

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final p = parishById(widget.selectedId);
    final list = [...parishes]..sort((a, b) => _key(a).compareTo(_key(b)));
    final q = _fold(_q.trim());
    final shown = q.isEmpty ? list : list.where((x) => _fold('${x.name} ${x.city}').contains(q)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: C.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _open ? C.gold : const Color(0xFFDDD3C0), width: _open ? 2 : 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _open = !_open;
              _q = '';
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Expanded(
                  child: p == null
                      ? Text(i.t('pickParish'), style: T.body(16, color: C.muted))
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: T.body(16, weight: FontWeight.w700)),
                          Text(p.city, style: T.body(13, color: C.muted)),
                        ]),
                ),
                Icon(_open ? Icons.expand_less : Icons.expand_more, color: C.green),
              ]),
            ),
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 8),
          TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: i.t('search'), prefixIcon: const Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(color: C.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.cardBorder)),
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(i.s('No parishes found', 'No se encontraron parroquias'), style: T.body(14, color: C.muted)),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: shown.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: C.cardBorder),
                    itemBuilder: (_, n) {
                      final x = shown[n];
                      final sel = x.id == p?.id;
                      return ListTile(
                        dense: true,
                        selected: sel,
                        selectedTileColor: const Color(0x14C59344),
                        title: Text(x.name, style: T.body(15, weight: sel ? FontWeight.w700 : FontWeight.w500)),
                        subtitle: Text(x.mission ? '${x.city} · ${i.s('Mission', 'Misión')}' : x.city, style: T.body(12.5, color: C.muted)),
                        trailing: sel ? const Icon(Icons.check, color: C.green) : null,
                        onTap: () {
                          setState(() => _open = false);
                          widget.onPick(x.id);
                        },
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

/// Note shown on screens still being ported from the web app.
class ComingSoon extends StatelessWidget {
  final String title;
  const ComingSoon(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    return ListView(padding: const EdgeInsets.all(16), children: [
      AppCard(
        title: title,
        child: Text(i.s('This screen is coming soon in the app.', 'Esta pantalla llega pronto a la app.'), style: T.body(15, color: C.muted)),
      ),
      Center(child: Text(i.t('version', {'v': Config.appVersion}), style: T.body(12, color: C.muted))),
    ]);
  }
}
