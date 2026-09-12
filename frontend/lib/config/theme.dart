import 'package:flutter/material.dart';

/// Paleta oficial de MoviCash (tal cual aparece en el mockup)
class MoviCashColors {
  static const verdeMenta = Color(0xFF4CBFA4); // Confianza
  static const lilaInnovacion = Color(0xFF8B7FD6); // Innovación
  static const amarilloPastel = Color(0xFFF2C46D); // Progreso
  static const celesteSeguridad = Color(0xFF6FB6D9); // Seguridad
  static const rosaComunidad = Color(0xFFE08A9B); // Comunidad

  static const fondoClaro = Color(0xFFF7F8FC);
  static const textoOscuro = Color(0xFF1F2430);
  static const textoGris = Color(0xFF767C8C);
}

final ThemeData moviCashTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: MoviCashColors.fondoClaro,
  primaryColor: MoviCashColors.lilaInnovacion,
  colorScheme: ColorScheme.fromSeed(
    seedColor: MoviCashColors.lilaInnovacion,
    primary: MoviCashColors.lilaInnovacion,
    secondary: MoviCashColors.verdeMenta,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: MoviCashColors.textoOscuro,
    centerTitle: false,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: MoviCashColors.lilaInnovacion,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    margin: EdgeInsets.zero,
  ),
);
