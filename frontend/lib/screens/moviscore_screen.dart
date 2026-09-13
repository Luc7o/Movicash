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
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await ApiService.obtenerMoviscore();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('MoviScore')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: MoviCashColors.textoGris),
                const SizedBox(height: 12),
                const Text('No pudimos cargar tu MoviScore', textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: MoviCashColors.textoGris, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    final score = _data?['moviscore_actual'] ?? 500;
    final nivel = _data?['nivel_moviscore'] ?? 'Nuevo';
    final historial = (_data?['historial'] as List<dynamic>? ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text('MoviScore')),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: MoviCashColors.verdeMenta.withOpacity(0.1),
                      border: Border.all(color: MoviCashColors.verdeMenta, width: 4),
                    ),
                    child: Center(
                      child: Text('$score',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(nivel,
                      style: const TextStyle(
                          color: MoviCashColors.verdeMenta, fontSize: 16, fontWeight: FontWeight.w600)),
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
            if (historial.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Aún no hay movimientos de MoviScore.',
                    style: TextStyle(color: MoviCashColors.textoGris)),
              ),
            ...historial.map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      (h['variacion'] ?? 0) >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: (h['variacion'] ?? 0) >= 0 ? MoviCashColors.verdeMenta : Colors.redAccent,
                    ),
                    title: Text(_etiquetaEvento(h['evento'])),
                    trailing: Text('${(h['variacion'] ?? 0) >= 0 ? '+' : ''}${h['variacion']}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )),
          ],
        ),
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
