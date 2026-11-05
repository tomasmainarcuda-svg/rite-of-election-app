import '../data/event_data.dart';
import '../i18n.dart';

/// "HH:MM" on the event date → instant (Arizona, UTC-7, no daylight saving).
DateTime eventTime(String hhmm) {
  final d = EventInfo.date.split('-').map(int.parse).toList();
  final t = hhmm.split(':').map(int.parse).toList();
  return DateTime.utc(d[0], d[1], d[2], t[0], t[1]).subtract(Duration(hours: Config.tzOffsetHours));
}

String addMinutes(String hhmm, int minutes) {
  final p = hhmm.split(':').map(int.parse).toList();
  final total = (((p[0] * 60 + p[1] + minutes) % 1440) + 1440) % 1440;
  return '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';
}

/// "13:05" → "1:05 PM" (US format in both languages, like the web app).
String formatTime(String hhmm) {
  final p = hhmm.split(':').map(int.parse).toList();
  final h12 = p[0] % 12 == 0 ? 12 : p[0] % 12;
  return '$h12:${p[1].toString().padLeft(2, '0')} ${p[0] < 12 ? 'AM' : 'PM'}';
}

const _daysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _daysEs = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
const _monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _monthsEs = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const _shortEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _shortEs = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];

/// "Saturday, February 20, 2027" / "sábado, 20 de febrero de 2027"
String formatEventDate(String lang) {
  final d = EventInfo.date.split('-').map(int.parse).toList();
  final wd = DateTime.utc(d[0], d[1], d[2]).weekday - 1;
  if (lang == 'es') return '${_daysEs[wd]}, ${d[2]} de ${_monthsEs[d[1] - 1]} de ${d[0]}';
  return '${_daysEn[wd]}, ${_monthsEn[d[1] - 1]} ${d[2]}, ${d[0]}';
}

/// "2026-10-16" → "Oct 16, 2026" / "16 oct 2026"
String formatShortDate(String iso, String lang) {
  final d = iso.split('-').map(int.parse).toList();
  if (lang == 'es') return '${d[2]} ${_shortEs[d[1] - 1]} ${d[0]}';
  return '${_shortEn[d[1] - 1]} ${d[2]}, ${d[0]}';
}

/// Relative time until an instant ("in 3 days", "in 1 h 12 min").
String relTime(DateTime target, I18n i) {
  final mins = (target.difference(DateTime.now()).inSeconds / 60).round();
  if (mins <= 0) return i.t('relNow');
  if (mins >= 48 * 60) return i.plural('relDays', (mins / 1440).round());
  if (mins >= 60) return i.t('relHoursMin', {'h': mins ~/ 60, 'm': mins % 60});
  return i.t('relMin', {'m': mins});
}
