/*
 * News — stories from The Catholic Sun (+ pinned Rite of Election items).
 * Filters by type; stories open on catholicsun.org. Ported from js/screens/news.js.
 */
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/event_data.dart';
import '../data/models.dart';
import '../state.dart';
import '../theme.dart';
import '../util/time.dart';

const _sun = 'The Catholic Sun';

Future<void> openLink(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class NewsScreen extends StatefulWidget {
  /// For internal links ("program", "map"…) of pinned items.
  final ValueChanged<String> onGo;
  const NewsScreen({super.key, required this.onGo});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final pinned = news.where((n) => n.pinned).toList();
    final rest = news.where((n) => !n.pinned && (_filter == 'all' || n.type == _filter)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        for (final n in pinned) _NewsCard(item: n, big: true, onGo: widget.onGo),
        // Filters
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            for (final f in const ['all', 'article', 'video'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(i.t('newsF_$f')),
                  selected: _filter == f,
                  showCheckmark: false,
                  selectedColor: C.green,
                  backgroundColor: C.white,
                  labelStyle: T.head(14, color: _filter == f ? C.white : C.green, weight: FontWeight.w700),
                  side: const BorderSide(color: C.green),
                  shape: const StadiumBorder(),
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ),
          ]),
        ),
        if (rest.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(i.t('newsEmpty'), textAlign: TextAlign.center, style: T.body(15, color: C.muted)),
          )
        else ...[
          _NewsCard(item: rest.first, big: true, onGo: widget.onGo),
          for (final n in rest.skip(1)) _NewsCard(item: n, big: false, onGo: widget.onGo),
        ],
        const SizedBox(height: 8),
        Text(i.t('newsCredit'), textAlign: TextAlign.center, style: T.poppins(12.5, color: C.muted)),
      ],
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final bool big;
  final ValueChanged<String> onGo;
  const _NewsCard({required this.item, required this.big, required this.onGo});

  IconData get _typeIcon => switch (item.type) {
        'video' => Icons.play_circle_outline,
        'podcast' => Icons.headphones_outlined,
        'event' => Icons.place_outlined,
        _ => Icons.newspaper_outlined,
      };

  Widget _media(double h) {
    final ph = Container(
      height: h,
      color: C.green,
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_typeIcon, color: C.gold2, size: big ? 44 : 28),
        const SizedBox(height: 4),
        Text(_sun, style: T.poppins(big ? 12 : 9, color: C.gold2, weight: FontWeight.w600)),
      ]),
    );
    if (item.image.isEmpty) return ph;
    return Stack(fit: StackFit.passthrough, children: [
      Image.network(
        item.image,
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ph,
        loadingBuilder: (_, child, p) => p == null ? child : ph,
      ),
      if (item.type == 'video')
        Positioned.fill(
          child: Center(child: Icon(Icons.play_circle_fill, color: C.white, size: big ? 56 : 30)),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final external = item.link.startsWith('http');
    void tap() => external ? openLink(item.link) : onGo(item.link);

    final meta = Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: item.pinned ? C.gold : C.paper, borderRadius: BorderRadius.circular(999)),
        child: Text(
          item.pinned ? i.t('newsPinned') : i.t('newsType_${item.type}'),
          style: T.poppins(11, color: item.pinned ? C.white : C.green, weight: FontWeight.w600),
        ),
      ),
      const SizedBox(width: 8),
      Text(formatShortDate(item.date, i.lang), style: T.poppins(12, color: C.muted)),
    ]);
    final source = Text(item.source == _sun ? _sun : '${item.source} · $_sun', style: T.poppins(11.5, color: C.goldDark, weight: FontWeight.w600));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: C.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.pinned ? C.gold : C.cardBorder, width: item.pinned ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: big
            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _media(190),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    meta,
                    const SizedBox(height: 8),
                    Text(i.pick(item.title), style: T.poppins(18, weight: FontWeight.w700, height: 1.25)),
                    const SizedBox(height: 6),
                    Text(i.pick(item.summary), style: T.poppins(14, color: C.muted)),
                    const SizedBox(height: 8),
                    source,
                  ]),
                ),
              ])
            : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 110, child: _media(96)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      meta,
                      const SizedBox(height: 6),
                      Text(i.pick(item.title), maxLines: 3, overflow: TextOverflow.ellipsis, style: T.poppins(14.5, weight: FontWeight.w600, height: 1.25)),
                      const SizedBox(height: 4),
                      source,
                    ]),
                  ),
                ),
              ]),
      ),
    );
  }
}
