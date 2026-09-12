import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseConfig.init();
  runApp(const MoviCashApp());
}

class MoviCashApp extends StatelessWidget {
  const MoviCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoviCash',
      debugShowCheckedModeBanner: false,
      theme: moviCashTheme,
      home: AuthService.estaAutenticado ? const HomeScreen() : const LoginScreen(),
    );
  }
}
