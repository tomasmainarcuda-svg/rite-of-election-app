/*
 * App-wide state: language and "my parish", saved on the phone (shared_preferences).
 * Same keys idea as the web app's store.js.
 */
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/event_data.dart';
import 'data/models.dart';
import 'i18n.dart';

class AppState extends ChangeNotifier {
  static const _kLang = 'roe.lang';
  static const _kParish = 'roe.parish';

  SharedPreferences? _prefs;
  String lang = 'en';
  String parishId = '';

  I18n get i => I18n(lang);

  /// Language: the phone's own language (Spanish → es, anything else → en), no question
  /// on first open (Tomás, Nov 4). If the person switches it on Home, that choice is kept.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString(_kLang) ?? '';
    lang = saved.isNotEmpty ? saved : phoneLang();
    parishId = _prefs!.getString(_kParish) ?? '';
  }

  static String phoneLang() => PlatformDispatcher.instance.locale.languageCode == 'es' ? 'es' : 'en';

  void setLang(String l) {
    lang = l;
    _prefs?.setString(_kLang, l);
    notifyListeners();
  }

  /// "Change language" button on Home: switches English ↔ Español.
  void toggleLang() => setLang(lang == 'es' ? 'en' : 'es');

  void setParish(String id) {
    parishId = id;
    _prefs?.setString(_kParish, id);
    notifyListeners();
  }

  Parish? get parish => parishById(parishId);
}

/// Accepts the official directory id or the old web-app id (alias).
Parish? parishById(String id) {
  if (id.isEmpty) return null;
  for (final p in parishes) {
    if (p.id == id || p.alias == id) return p;
  }
  return null;
}

/// Gives every screen access to AppState and rebuilds them when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
