import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette from the diocesan promo kit (only these colors), same as the web app.
class C {
  static const green = Color(0xFF1F4A3B);
  static const green2 = Color(0xFF2A5E4B);
  static const gold = Color(0xFFC59344);
  static const gold2 = Color(0xFFE2BE7C);
  static const goldDark = Color(0xFFA8772F); // readable gold for small italic text
  static const paper = Color(0xFFF3EFE7);
  static const ink = Color(0xFF1D2B25);
  static const muted = Color(0xFF6B7A72);
  static const white = Color(0xFFFFFFFF);
  static const line = Color(0x40C59344);
  static const cardSoft = Color(0xFFFFFDF8);
  static const cardBorder = Color(0xFFE9E1D0);
  static const red = Color(0xFFC62828);
  static const parking = Color(0xFF2F6FB5);
}

/// Text styles. Headings: Roboto Condensed (bold, uppercase in the web app).
/// Accent / booklet: Gelasio (serif). News: Poppins (the Catholic Sun's typeface).
/// All three ship INSIDE the app (pubspec.yaml `fonts:`), so nothing is downloaded from
/// Google when the app opens (Tomás, Nov 8). Body text uses the phone's own system font.
class T {
  static TextStyle head(double size, {Color color = C.ink, FontWeight weight = FontWeight.w800, double spacing = 0}) =>
      TextStyle(fontFamily: 'RobotoCondensed', fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing, height: 1.15);

  /// Serif for the booklet and accents. Gelasio is metric-compatible with Georgia (the web
  /// app's serif), so it looks the same on iPhone, Android and in the web preview.
  static TextStyle serif(double size, {Color color = C.ink, bool italic = false, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: 'Gelasio',
        fontSize: size,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: weight,
        height: 1.35,
      );

  static TextStyle body(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400, double height = 1.45}) =>
      TextStyle(fontSize: size, color: color, fontWeight: weight, height: height);

  static TextStyle poppins(double size, {Color color = C.ink, FontWeight weight = FontWeight.w400, double height = 1.35}) =>
      TextStyle(fontFamily: 'Poppins', fontSize: size, color: color, fontWeight: weight, height: height);

  /// Small uppercase label (form labels, card titles).
  static TextStyle label({Color color = C.muted}) => head(12, color: color, weight: FontWeight.w700, spacing: 1);
}

/// The bundled fonts' licenses (SIL Open Font License) — the license asks that it travel
/// with the fonts. Registered so they appear in the app's licenses page.
void registerFontLicenses() {
  const files = {
    'Roboto Condensed': 'assets/licenses/robotocondensed-OFL.txt',
    'Gelasio': 'assets/licenses/gelasio-OFL.txt',
    'Poppins': 'assets/licenses/poppins-OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final e in files.entries) {
      try {
        yield LicenseEntryWithLineBreaks([e.key], await rootBundle.loadString(e.value));
      } catch (_) {/* file missing in a dev build: skip */}
    }
  });
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.green, primary: C.green, secondary: C.gold, surface: C.white),
    scaffoldBackgroundColor: C.paper,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    splashFactory: InkRipple.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD3C0), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDD3C0), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.gold, width: 2)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.green : C.white),
    ),
  );
}
