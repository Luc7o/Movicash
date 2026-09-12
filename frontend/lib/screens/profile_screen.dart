import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/supabase_config.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

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
                  Text(user?.userMetadata?['nombre'] ?? 'Usuario MoviCash',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(user?.phone ?? '', style: const TextStyle(color: MoviCashColors.textoGris)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _opcion(Icons.badge_outlined, 'Mis datos'),
          _opcion(Icons.settings_outlined, 'Configuración'),
          _opcion(Icons.help_outline, 'Ayuda'),
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

  Widget _opcion(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: MoviCashColors.textoGris),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
