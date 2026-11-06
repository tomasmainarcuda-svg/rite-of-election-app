/*
 * STAFF APP — separate app for the event team (Tomás, Nov 6): "Llamado a fotos".
 * One person on a tablet runs the 3 photo stations with "Siguiente / Atrás".
 * Same code base as the participants' app (theme, data, texts), different entry point:
 *   flutter build web -t lib/main_staff.dart
 * Front only for now: see services/photo_calls.dart for the backend hook.
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/photo_calls.dart';
import 'staff/photo_call_screen.dart';
import 'state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  await PhotoCalls.I.load();
  runApp(AppScope(state: state, child: const StaffApp()));
}

class StaffApp extends StatelessWidget {
  const StaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    final i = AppScope.of(context).i;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: MaterialApp(
        title: i.s('Staff · Photo calls', 'Staff · Llamado a fotos'),
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const PhotoCallScreen(),
      ),
    );
  }
}
