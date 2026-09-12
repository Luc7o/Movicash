import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/supabase_config.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'request_credit_screen.dart';
import 'circles_screen.dart';
import 'moviscore_screen.dart';
import 'movements_screen.dart';
import 'profile_screen.dart';
import 'my_credit_screen.dart';
import 'community_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  Map<String, dynamic>? _moviscore;
  Map<String, dynamic>? _creditoActivo;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final score = await ApiService.obtenerMoviscore();
      final credito = await ApiService.creditoActivo();
      setState(() {
        _moviscore = score;
        _creditoActivo = credito;
      });
    } catch (_) {
      // en producción: mostrar snackbar de error / reintentar
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = supabase.auth.currentUser?.userMetadata?['nombre'] ?? 'Carlos';

    final pantallas = [
      _buildHome(nombre),
      const MovementsScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: pantallas[_tab]),
      bottomNavigationBar: MoviCashBottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }

  Widget _buildHome(String nombre) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    final score = _moviscore?['moviscore_actual'] ?? 500;
    final nivel = _moviscore?['nivel_moviscore'] ?? 'Nuevo';
    final credMin = (_moviscore?['credito_disponible_min'] ?? 50).toString();
    final credMax = (_moviscore?['credito_disponible_max'] ?? 200).toString();

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Hola, $nombre 👋',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: MoviCashColors.textoOscuro),
              ),
            ],
          ),
          const Text('¡Qué bueno verte de nuevo!', style: TextStyle(color: MoviCashColors.textoGris)),
          const SizedBox(height: 20),

          // Card MoviScore
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoviscoreScreen())),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: MoviCashColors.lilaInnovacion.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_outlined, color: MoviCashColors.lilaInnovacion),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('MoviScore', style: TextStyle(color: MoviCashColors.textoGris)),
                          Text('$score',
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          Text(nivel, style: const TextStyle(color: MoviCashColors.verdeMenta)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: MoviCashColors.textoGris),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card Crédito disponible / activo
          Card(
            color: MoviCashColors.verdeMenta.withOpacity(0.12),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_creditoActivo == null) ...[
                    const Text('Crédito disponible', style: TextStyle(color: MoviCashColors.textoGris)),
                    Text('S/ $credMin - S/ $credMax',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: MoviCashColors.verdeMenta),
                        onPressed: () async {
                          await Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RequestCreditScreen()));
                          _cargarDatos();
                        },
                        child: const Text('Solicitar crédito'),
                      ),
                    ),
                  ] else ...[
                    const Text('Crédito activo', style: TextStyle(color: MoviCashColors.textoGris)),
                    Text('S/ ${_creditoActivo!['saldo_pendiente']} pendiente',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Pago diario sugerido: S/ ${_creditoActivo!['pago_diario_sugerido']}'),
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Accesos rápidos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _accesoRapido(Icons.account_balance_wallet_outlined, 'Mi crédito',
                  () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const MyCreditScreen()));
                _cargarDatos();
              }),
              _accesoRapido(Icons.groups_outlined, 'Círculos de\nahorro',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CirclesScreen()))),
              _accesoRapido(Icons.speed_outlined, 'MoviScore',
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MoviscoreScreen()))),
            ],
          ),

          if (_creditoActivo != null) ...[
            const SizedBox(height: 20),
            Card(
              color: MoviCashColors.amarilloPastel.withOpacity(0.18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: MoviCashColors.amarilloPastel.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today_outlined, size: 18, color: MoviCashColors.textoOscuro),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Próximo pago', style: TextStyle(color: MoviCashColors.textoGris)),
                        Text('S/ ${_creditoActivo!['pago_diario_sugerido']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const MyCreditScreen()));
                        _cargarDatos();
                      },
                      child: const Text('Pagar ahora'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accesoRapido(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: MoviCashColors.lilaInnovacion.withOpacity(0.12),
            child: Icon(icon, color: MoviCashColors.lilaInnovacion),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
