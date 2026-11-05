/*
 * Info: practical details, FAQ, bishop videos (placeholders), contact and
 * "About this app". Ported from js/screens/info.js.
 */
import 'package:flutter/material.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'news.dart' show openLink;

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppCard(
          title: i.t('goodToKnow'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(children: [for (final it in infoItems) _Acc(i.pick(it.title), i.pick(it.body))]),
        ),
        AppCard(
          title: i.t('faqTitle'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Column(children: [for (final f in faqs) _Acc(i.pick(f.q), i.pick(f.a))]),
        ),
        AppCard(
          title: i.t('videosTitle'),
          child: Column(children: [for (final v in videos) _VideoTile(v)]),
        ),
        AppCard(
          title: i.t('contactTitle'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.pick(Contact.name), style: T.body(15, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (Contact.email.isEmpty && Contact.phone.isEmpty) Text(i.t('contactSoon'), style: T.body(14, color: C.muted)),
            if (Contact.email.isNotEmpty)
              InkWell(
                onTap: () => openLink('mailto:${Contact.email}'),
                child: Text(Contact.email, style: T.body(15, color: C.green, weight: FontWeight.w600)),
              ),
            if (Contact.phone.isNotEmpty)
              InkWell(
                onTap: () => openLink('tel:${Contact.phone.replaceAll(RegExp(r'[^\d+]'), '')}'),
                child: Text(Contact.phone, style: T.body(15, color: C.green, weight: FontWeight.w600)),
              ),
          ]),
        ),
        AppCard(
          child: Column(children: [
            const AssetLogo('diocese-logo.png', height: 72),
            const SizedBox(height: 10),
            Text(i.t('aboutTitle').toUpperCase(), style: T.head(17, color: C.green)),
            const SizedBox(height: 6),
            Text(i.t('aboutText'), textAlign: TextAlign.center, style: T.body(14, color: C.muted)),
            const SizedBox(height: 6),
            Text('${i.t('version', {'v': Config.appVersion})} · ${i.t('sampleData')}', style: T.body(12.5, color: C.muted)),
          ]),
        ),
      ],
    );
  }
}

/// Fold-open row (the web app's <details> accordion).
class _Acc extends StatelessWidget {
  final String title, body;
  const _Acc(this.title, this.body);

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          iconColor: C.gold,
          collapsedIconColor: C.green,
          expandedAlignment: Alignment.centerLeft,
          title: Text(title, style: T.body(15.5, weight: FontWeight.w600)),
          children: [Text(body, style: T.body(14.5, color: C.ink))],
        ),
      );
}

class _VideoTile extends StatelessWidget {
  final Video v;
  const _VideoTile(this.v);

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final ready = v.url.isNotEmpty;
    return Opacity(
      opacity: ready ? 1 : 0.7,
      child: InkWell(
        onTap: ready ? () => openLink(v.url) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              width: 76,
              height: 50,
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.play_arrow_rounded, color: C.gold2, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(i.pick(v.title), style: T.body(15, weight: FontWeight.w600)),
                Text(i.t(ready ? 'watchVideo' : 'comingSoon'), style: T.body(13, color: C.muted)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
