import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class MoviscoreScreen extends StatefulWidget {
  const MoviscoreScreen({super.key});

  @override
  State<MoviscoreScreen> createState() => _MoviscoreScreenState();
}

class _MoviscoreScreenState extends State<MoviscoreScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    ApiService.obtenerMoviscore().then((d) => setState(() => _data = d));
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final score = _data!['moviscore_actual'] ?? 500;
    final nivel = _data!['nivel_moviscore'] ?? 'Nuevo';
    final historial = (_data!['historial'] as List<dynamic>? ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('MoviScore')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Text('$score', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                Text(nivel, style: const TextStyle(color: MoviCashColors.verdeMenta, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            color: MoviCashColors.verdeMenta.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '¡Vas por buen camino! Tu historial de pagos te permite acceder a mejores condiciones.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Historial reciente', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (historial.isEmpty) const Text('Aún no hay movimientos de MoviScore.'),
          ...historial.map((h) => ListTile(
                leading: Icon(
                  (h['variacion'] ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: (h['variacion'] ?? 0) >= 0 ? MoviCashColors.verdeMenta : Colors.red,
                ),
                title: Text(_etiquetaEvento(h['evento'])),
                trailing: Text('${(h['variacion'] ?? 0) >= 0 ? '+' : ''}${h['variacion']}'),
              )),
        ],
      ),
    );
  }

  String _etiquetaEvento(String? evento) {
    switch (evento) {
      case 'pago_puntual':
        return 'Pago puntual';
      case 'credito_completado':
        return 'Crédito completado';
      case 'aporte_circulo':
        return 'Aporte a círculo de ahorro';
      default:
        return evento ?? 'Movimiento';
    }
  }
}
