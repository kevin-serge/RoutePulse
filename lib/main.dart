import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'Login/login.dart';
import 'widget/rp_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fyfkwchvyghgfrpczgwr.supabase.co',
    anonKey: 'sb_publishable_xczb93KaZHAbey2jvLx9zQ_hIzfpXuL',
  );

  runApp(const RoutePulseApp());
}

class RoutePulseApp extends StatelessWidget {
  const RoutePulseApp({Key? key}) : super(key: key);

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
