import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Autenticación con correo y contraseña — 100% gratis con Supabase,
/// sin depender de un proveedor de SMS de pago como Twilio.
class AuthService {
  static Future<AuthResponse> registrarse(String email, String password) async {
    return supabase.auth.signUp(email: email, password: password);
  }

  static Future<AuthResponse> iniciarSesion(String email, String password) async {
    return supabase.auth.signInWithPassword(email: email, password: password);
  }

  static bool get estaAutenticado => supabase.auth.currentSession != null;

  static Future<void> cerrarSesion() => supabase.auth.signOut();

  static Future<void> recuperarContrasena(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }
}
