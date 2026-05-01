import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/Login/login.dart';
import 'widget/rp_widgets.dart';

// ──────────────────────────────────────────────────────────────
// CONFIGURATION SUPABASE
//
// Remplace les defaultValue ci-dessous par tes vraies valeurs.
// Trouve-les dans : Supabase Dashboard > Project Settings > API
//
// Ou passe-les à la compilation sans toucher au code :
//   flutter run -d <device> \
//     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
// ──────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://wenvxpitemewneycolvj.supabase.co', // ← REMPLACE
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'sb_publishable_PakMbtHyYe0oT3NC5iH3Jw_V47twY0t', // ← REMPLACE
    ),
  );

  runApp(const RoutePulseApp());
}

class RoutePulseApp extends StatelessWidget {
  const RoutePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoutePulse',
      debugShowCheckedModeBanner: false,
      theme: RPTheme.theme,
      home: const LoginScreen(),
    );
  }
}
