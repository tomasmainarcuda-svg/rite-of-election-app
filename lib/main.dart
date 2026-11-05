/*
 * Rite of Election — official app (Flutter). Entry point and app shell:
 * language = the phone's language (no question), green header with the TILMA logo (tap → Diocese crest),
 * swipeable tabs and the bottom tab bar. Ported from the web app's js/app.js.
 */
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'screens/commit.dart';
import 'screens/home.dart';
import 'screens/info.dart';
import 'screens/map.dart';
import 'screens/news.dart';
import 'screens/photos.dart';
import 'screens/program.dart';
import 'screens/translate.dart';
import 'services/live.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  Live.I.start(); // staff panel live data (announcement, "now" in Program, interpreters on air)
  runApp(AppScope(state: state, child: const RoeApp()));
}

class RoeApp extends StatelessWidget {
  const RoeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return MaterialApp(
      title: app.i.t('appAccent'),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scrollBehavior: const _AppScroll(),
      home: const Shell(),
    );
  }
}

/// Every screen can be pulled down (to refresh) even when it's short, and in the web
/// preview the tabs can also be swiped with the mouse, like the web app's iPhone preview.
class _AppScroll extends MaterialScrollBehavior {
  const _AppScroll();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => AlwaysScrollableScrollPhysics(parent: super.getScrollPhysics(context));

  @override
  Set<PointerDeviceKind> get dragDevices => {...super.dragDevices, PointerDeviceKind.mouse, PointerDeviceKind.trackpad};
}

/* -------------------------------------------------------------------- shell */
const _tabs = [
  ['home', 'tabHome', 'titleHome'],
  ['program', 'tabProgram', 'titleProgram'],
  ['photos', 'tabPhotos', 'titlePhotos'],
  ['map', 'tabMap', 'titleMap'],
  ['translate', 'tabTranslate', 'titleTranslate'],
  ['news', 'navNews', 'titleNews'], // "News" replaced the old "More" tab (Tomás, Oct 16)
];

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> with WidgetsBindingObserver {
  final _pages = PageController();
  int _index = 0;
  bool _diocese = false; // header logo: TILMA ↔ Diocese crest

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // Phone unlocked / app back in front → reconnect the live data right away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) Live.I.resume();
  }

  /// Altar call / Info: not tabs. They open INSIDE the app (same green header with the
  /// TILMA logo, tab bar still at the bottom), like the web app — not as a separate page.
  String? _extra;

  void go(String route) {
    final n = _tabs.indexWhere((t) => t[0] == route);
    if (n >= 0) {
      setState(() => _extra = null);
      _pages.animateToPage(n, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      return;
    }
    setState(() => _extra = route);
  }

  /// Pull down at the top of any screen to refresh (Tomás, Oct 18): reconnects the live
  /// data (announcements, "now", interpreters) and redraws the screen.
  Widget _pull(Widget child) => RefreshIndicator(
        color: C.green,
        backgroundColor: C.white,
        onRefresh: () async {
          Live.I.resume();
          await Future<void>.delayed(const Duration(milliseconds: 700));
          if (mounted) setState(() {});
        },
        child: child,
      );

  void _goHome() {
    setState(() => _extra = null);
    _pages.jumpToPage(0);
  }

  Widget _screen(String route) {
    final i = AppScope.of(context).i;
    return switch (route) {
      'home' => HomeScreen(onGo: go),
      'program' => const ProgramScreen(),
      'photos' => const PhotosScreen(),
      'map' => const MapScreen(),
      'translate' => const TranslateScreen(),
      'news' => NewsScreen(onGo: go),
      _ => ComingSoon(i.t(_tabs.firstWhere((t) => t[0] == route)[2])),
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    final route = _extra ?? _tabs[_index][0];
    final title = switch (_extra) {
      'commit' => i.t('titleCommit'),
      'info' => i.t('titleInfo'),
      _ => i.t(_tabs[_index][2]),
    };
    return PopScope(
      // Phone "back" (Android) closes Altar call / Info first.
      canPop: _extra == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _extra = null);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(children: [
          // Green header, also behind the iPhone status bar. Content centered in the same
          // column as the screens (max 480 px, like the web app) on iPad / computer.
          Container(
            color: C.green,
            child: SafeArea(
              bottom: false,
              child: _col(SizedBox(
                height: 70,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Expanded(
                      child: route == 'news'
                          ? Align(alignment: Alignment.centerLeft, child: _sunLogo())
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(i.t('appAccent'), maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: T.serif(19, color: C.gold2, italic: true).copyWith(height: 1.1)),
                              Text(title.toUpperCase(), maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: T.head(27, color: C.white)),
                            ]),
                    ),
                    // Logo ALWAYS top right (Tomás's rule). Tap: TILMA ↔ Diocese of Phoenix crest.
                    GestureDetector(
                      onTap: () => setState(() => _diocese = !_diocese),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: AssetLogo(_diocese ? 'diocese-logo.png' : 'tilma-logo.webp', key: ValueKey(_diocese), height: 52),
                      ),
                    ),
                  ]),
                ),
              )),
            ),
          ),
          // Gold-stroked wave under the header: green above, parchment below (web app).
          const SizedBox(width: double.infinity, height: 22, child: CustomPaint(painter: _WavePainter())),
          // Live announcement from the staff panel, on every screen.
          ValueListenableBuilder<LiveState>(
            valueListenable: Live.I.state,
            builder: (context, live, _) {
              final text = live.announcementText(AppScope.of(context).lang);
              if (text.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: C.gold,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Padding(padding: EdgeInsets.only(top: 3), child: Icon(Icons.campaign_outlined, color: C.white, size: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(i.t('announcement').toUpperCase(), style: T.label(color: C.green)),
                      Text(text, style: T.body(15, color: C.white, weight: FontWeight.w700)),
                    ]),
                  ),
                ]),
              );
            },
          ),
          Expanded(
            child: _col(Stack(children: [
              PageView(
                controller: _pages,
                onPageChanged: (n) => setState(() => _index = n),
                children: [for (final t in _tabs) _KeepAlive(child: _pull(_screen(t[0])))],
              ),
              if (_extra != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: C.paper,
                    child: _pull(_extra == 'commit' ? CommitScreen(onHome: _goHome) : const InfoScreen()),
                  ),
                ),
            ])),
          ),
        ]),
        // Bottom tab bar like the web app: icon + small uppercase label, gold line under
        // the active tab (none while Altar call / Info is open).
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(color: C.white, border: Border(top: BorderSide(color: Color(0xFFE7E0D2)))),
          child: SafeArea(
            top: false,
            child: _col(SizedBox(
              height: 62,
              child: Row(children: [
                for (var n = 0; n < _tabs.length; n++)
                  Expanded(
                    child: Semantics(
                      selected: _extra == null && n == _index,
                      button: true,
                      child: InkWell(
                        onTap: () {
                          setState(() => _extra = null);
                          _pages.jumpToPage(n);
                        },
                        child: Builder(builder: (_) {
                          final on = _extra == null && n == _index;
                          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(routeIcon(_tabs[n][0]), size: 22, color: on ? C.green : C.muted),
                            const SizedBox(height: 3),
                            Text(i.t(_tabs[n][1]).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: T.head(10.5, color: on ? C.green : C.muted, weight: FontWeight.w700, spacing: 0.3)),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: on ? 22 : 0,
                              height: 3,
                              decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(2)),
                            ),
                          ]);
                        }),
                      ),
                    ),
                  ),
              ]),
            )),
          ),
        ),
      ),
      ),
    );
  }

  /// Same column width as the web app (480 px), centered on wide screens.
  // heightFactor 1: only center sideways — never grow taller than the content (the tab bar
  // would otherwise take the whole screen).
  static Widget _col(Widget child) =>
      Center(heightFactor: 1, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: child));

  // On News the Catholic Sun logo (white) replaces the title (Tomás, Oct 16).
  Widget _sunLogo() => SvgPicture.asset(
        'assets/images/catholic-sun-logo.svg',
        height: 34,
        colorFilter: const ColorFilter.mode(C.white, BlendMode.srcIn),
        placeholderBuilder: (_) => Text('THE CATHOLIC SUN', style: T.head(22, color: C.white)),
      );
}

/// Keeps each tab alive while swiping (no reload, keeps scroll position).
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// The web app's header wave: path "M0 0 H480 V10 C340 40 170 -6 0 24 Z" (viewBox 480×36,
/// stretched to the screen width) in green, with the gold line along its lower edge.
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 480, sy = size.height / 36;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final fill = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(p(480, 10).dx, p(480, 10).dy)
      ..cubicTo(p(340, 40).dx, p(340, 40).dy, p(170, -6).dx, p(170, -6).dy, p(0, 24).dx, p(0, 24).dy)
      ..close();
    canvas.drawPath(fill, Paint()..color = C.green);
    final line = Path()
      ..moveTo(p(0, 24).dx, p(0, 24).dy)
      ..cubicTo(p(170, -6).dx, p(170, -6).dy, p(340, 40).dx, p(340, 40).dy, p(480, 10).dx, p(480, 10).dy);
    canvas.drawPath(
        line,
        Paint()
          ..color = C.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
