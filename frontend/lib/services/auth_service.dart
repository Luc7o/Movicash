import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Autenticación con OTP por SMS — el método más natural para el
/// segmento objetivo (mototaxistas, delivery, comerciantes), que no
/// siempre maneja correo electrónico activamente.
class AuthService {
  static Future<void> enviarCodigo(String telefono) async {
    await supabase.auth.signInWithOtp(phone: telefono);
  }

  static Future<AuthResponse> verificarCodigo(String telefono, String codigo) async {
    if (telefono.isEmpty || codigo.isEmpty) {
      throw Exception('Falta el número de teléfono o el código');
    }
    // ignore: avoid_print
    print('DEBUG verificarCodigo -> telefono="$telefono" codigo="$codigo" (largo=${codigo.length})');
    return supabase.auth.verifyOTP(
      phone: telefono,
      token: codigo,
      type: OtpType.sms,
    );
  }

  static Future<void> completarPerfil({
    required String nombre,
    required String telefono,
    String? ubicacion,
  }) async {
    final userId = supabase.auth.currentUser!.id;
    await supabase.from('usuarios').upsert({
      'id': userId,
      'nombre': nombre,
      'telefono': telefono,
      'ubicacion': ubicacion,
    });
  }

  static bool get estaAutenticado => supabase.auth.currentSession != null;

  static Future<void> cerrarSesion() => supabase.auth.signOut();
}
