/// Bilingual text: { en, es }. Same shape as the web app's data.js.
class L {
  final String en;
  final String es;
  const L(this.en, this.es);
  const L.same(String s)
      : en = s,
        es = s;

  String of(String lang) => lang == 'es' ? (es.isNotEmpty ? es : en) : (en.isNotEmpty ? en : es);
  String other(String lang) => lang == 'es' ? en : es;
}

class ScheduleItem {
  final String id, time, end, accent, link;
  final L title, desc, place;
  const ScheduleItem({
    required this.id,
    required this.time,
    required this.end,
    required this.title,
    required this.desc,
    required this.place,
    required this.accent,
    required this.link,
  });
}

class Station {
  final int id;
  final L bishop;
  const Station(this.id, this.bishop);
}

class Parish {
  final String id, name, city, code, section, photoStart;
  final String? alias;
  final bool mission, mock;
  final int group, station, size;
  const Parish({
    required this.id,
    required this.name,
    required this.city,
    required this.code,
    required this.section,
    required this.photoStart,
    required this.group,
    required this.station,
    required this.size,
    this.alias,
    this.mission = false,
    this.mock = true,
  });

  bool get hasAssignment => section.isNotEmpty && photoStart.isNotEmpty;
  String get label => '$name — $city';
}

class Channel {
  final String id, label, lang;
  final bool none; // English: the ceremony itself, no translation channel
  const Channel(this.id, this.label, this.lang, {this.none = false});
}

class Gate {
  final String id, short;
  final L label;
  const Gate(this.id, this.short, this.label);
}

class InfoItem {
  final String id;
  final L title, body;
  const InfoItem(this.id, this.title, this.body);
}

class Faq {
  final L q, a;
  const Faq(this.q, this.a);
}

class Video {
  final String id, url;
  final L title;
  const Video(this.id, this.title, this.url);
}

class NewsItem {
  final String id, type, date, source, image, link;
  final L title, summary;
  final bool pinned;
  const NewsItem({
    required this.id,
    required this.type,
    required this.date,
    required this.source,
    required this.title,
    required this.summary,
    required this.image,
    required this.link,
    this.pinned = false,
  });
}
