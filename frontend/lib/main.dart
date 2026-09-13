import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/complete_profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await SupabaseConfig.init();
  await NotificationService.init();
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
      home: const AuthGate(),
    );
  }
}

/// Decide a qué pantalla mandar al abrir la app:
/// - Sin sesión -> Login
/// - Con sesión pero sin perfil en la tabla "usuarios" -> Completar perfil
/// - Con sesión y perfil completo -> Home
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _cargando = true;
  Widget _destino = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _decidir();
  }

  Future<void> _decidir() async {
    if (!AuthService.estaAutenticado) {
      setState(() {
        _destino = const LoginScreen();
        _cargando = false;
      });
      return;
    }
    try {
      final perfil = await ApiService.obtenerPerfil();
      setState(() {
        _destino = perfil == null ? const CompleteProfileScreen() : const HomeScreen();
        _cargando = false;
      });
    } catch (_) {
      setState(() {
        _destino = const HomeScreen();
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _destino;
  }
}
