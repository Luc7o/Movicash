import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class CirclesScreen extends StatefulWidget {
  const CirclesScreen({super.key});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  List<dynamic> _misCirculos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final data = await ApiService.misCirculos();
      setState(() => _misCirculos = data as List<dynamic>);
    } catch (_) {
      // manejar error en UI
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Círculos de ahorro')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    color: MoviCashColors.lilaInnovacion,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Junta Digital',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          const Text('Ahorra en comunidad y haz crecer tus oportunidades',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            onPressed: () {
                              // TODO: navegar a pantalla "unirme/crear circulo"
                            },
                            child: const Text('Unirme a un círculo',
                                style: TextStyle(color: MoviCashColors.lilaInnovacion)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Mis círculos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (_misCirculos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Aún no perteneces a ningún círculo.',
                          style: TextStyle(color: MoviCashColors.textoGris)),
                    ),
                  ..._misCirculos.map((m) {
                    final circulo = m['circulos_ahorro'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0x224CBFA4),
                          child: Icon(Icons.groups_outlined, color: MoviCashColors.verdeMenta),
                        ),
                        title: Text(circulo?['nombre'] ?? 'Círculo'),
                        subtitle: Text('S/ ${circulo?['monto_por_turno'] ?? '-'} por turno'),
                        trailing: Chip(
                          label: const Text('Activo'),
                          backgroundColor: MoviCashColors.verdeMenta.withOpacity(0.15),
                          labelStyle: const TextStyle(color: MoviCashColors.verdeMenta),
                        ),
                        onTap: () async {
                          try {
                            await ApiService.aportarACirculo(circulo['id'], 20);
                            _cargar();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text('$e')));
                            }
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
