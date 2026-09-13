import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Autenticación por DNI + contraseña.
///
/// Supabase Auth solo soporta identificarse con correo o teléfono, no con
/// un documento de identidad directamente. Para no depender de un
/// proveedor de SMS de pago (Twilio) y para que el DNI sea lo único que
/// el usuario necesita recordar, generamos internamente un correo
/// "sintético" a partir del DNI (`<dni>@dni.movicash.pe`) y lo usamos
/// como identificador técnico dentro de Supabase. El usuario nunca ve
/// ni escribe ese correo: solo ingresa su DNI y su contraseña.
class AuthService {
  static const _dominioSintetico = 'dni.movicash.pe';

  static String correoDesdeDni(String dni) => '$dni@$_dominioSintetico';

  /// Registra una cuenta nueva. [nombreCompleto] viene de la consulta a
  /// RENIEC y se guarda como metadata del usuario para poder prellenar
  /// la pantalla de "Completar perfil" incluso si el usuario cierra la
  /// app antes de terminar el registro.
  static Future<AuthResponse> registrarse({
    required String dni,
    required String password,
    required String nombreCompleto,
  }) {
    return supabase.auth.signUp(
      email: correoDesdeDni(dni),
      password: password,
      data: {'dni': dni, 'nombre_completo': nombreCompleto},
    );
  }

  static Future<AuthResponse> iniciarSesion(String dni, String password) {
    return supabase.auth.signInWithPassword(
      email: correoDesdeDni(dni),
      password: password,
    );
  }

  static bool get estaAutenticado => supabase.auth.currentSession != null;

  static Future<void> cerrarSesion() => supabase.auth.signOut();

  /// El DNI y nombre guardados al registrarse (metadata del usuario de
  /// Supabase), disponibles para prellenar pantallas posteriores.
  static String? get dniActual => supabase.auth.currentUser?.userMetadata?['dni'] as String?;
  static String? get nombreActual =>
      supabase.auth.currentUser?.userMetadata?['nombre_completo'] as String?;
}
