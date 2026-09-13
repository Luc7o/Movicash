import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'circles_screen.dart';
import 'marketplace_screen.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Juntos construimos\nun mejor futuro',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Beneficios de tu comunidad', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                  child: _beneficio(Icons.account_balance_wallet_outlined, 'Acceso a\ncréditos',
                      MoviCashColors.verdeMenta),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CirclesScreen())),
                  child: _beneficio(Icons.groups_outlined, 'Mejores\ncondiciones', MoviCashColors.lilaInnovacion),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                  child: _beneficio(Icons.verified_outlined, 'Más\nconfianza', MoviCashColors.celesteSeguridad),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: MoviCashColors.rosaComunidad.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tu comunidad también es tu fuerza',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text(
                    'Los círculos de ahorro te ayudan a construir historial y a no estar solo en los momentos difíciles.',
                    style: TextStyle(color: MoviCashColors.textoGris),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: MoviCashColors.lilaInnovacion),
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const CirclesScreen())),
                    child: const Text('Ver mis círculos'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _beneficio(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
