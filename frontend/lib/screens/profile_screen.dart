import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/supabase_config.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'my_data_screen.dart';
import 'settings_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 32, child: Icon(Icons.person, size: 32)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AuthService.nombreActual ?? user?.userMetadata?['nombre'] ?? 'Usuario MoviCash',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    AuthService.dniActual != null ? 'DNI ${AuthService.dniActual}' : '',
                    style: const TextStyle(color: MoviCashColors.textoGris),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _opcion(context, Icons.badge_outlined, 'Mis datos', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyDataScreen()));
          }),
          _opcion(context, Icons.settings_outlined, 'Configuración', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          _opcion(context, Icons.help_outline, 'Ayuda', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
          }),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await AuthService.cerrarSesion();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _opcion(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: MoviCashColors.textoGris),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
