/*
 * Rite of Election — official app (Flutter). Entry point and app shell:
 * language = the phone's language (no question), green header with the TILMA logo (tap → Diocese crest),
 * swipeable tabs and the bottom tab bar. Ported from the web app's js/app.js.
 */
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
      home: const Shell(),
    );
  }
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

  void go(String route) {
    final n = _tabs.indexWhere((t) => t[0] == route);
    if (n >= 0) {
      _pages.animateToPage(n, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      return;
    }
    // Altar call and Info are not tabs: they open on top, from Home's quick links.
    final i = AppScope.of(context).i;
    final title = i.t(route == 'commit' ? 'titleCommit' : 'titleInfo');
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(backgroundColor: C.green, foregroundColor: C.white, title: Text(title.toUpperCase(), style: T.head(20, color: C.white))),
        body: route == 'commit' ? const CommitScreen() : const InfoScreen(),
      ),
    ));
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
    final route = _tabs[_index][0];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(children: [
          // Green header, also behind the iPhone status bar.
          Container(
            color: C.green,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(
                      child: route == 'news'
                          ? Align(alignment: Alignment.centerLeft, child: _sunLogo())
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(i.t('appAccent'), style: T.serif(13, color: C.gold2, italic: true)),
                              Text(i.t(_tabs[_index][2]).toUpperCase(), style: T.head(24, color: C.white)),
                            ]),
                    ),
                    // Logo ALWAYS top right (Tomás's rule). Tap: TILMA ↔ Diocese of Phoenix crest.
                    GestureDetector(
                      onTap: () => setState(() => _diocese = !_diocese),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: AssetLogo(_diocese ? 'diocese-logo.png' : 'tilma-logo.webp', key: ValueKey(_diocese), height: 46),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
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
            child: PageView(
              controller: _pages,
              onPageChanged: (n) => setState(() => _index = n),
              children: [for (final t in _tabs) _KeepAlive(child: _screen(t[0]))],
            ),
          ),
        ]),
        bottomNavigationBar: NavigationBar(
          backgroundColor: C.white,
          indicatorColor: const Color(0x33C59344),
          selectedIndex: _index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 66,
          onDestinationSelected: (n) => _pages.jumpToPage(n),
          destinations: [
            for (final t in _tabs)
              NavigationDestination(
                icon: Icon(routeIcon(t[0]), color: C.muted),
                selectedIcon: Icon(routeIcon(t[0]), color: C.green),
                label: i.t(t[1]),
              ),
          ],
        ),
      ),
    );
  }

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
