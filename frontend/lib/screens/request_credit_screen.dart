import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class RequestCreditScreen extends StatefulWidget {
  const RequestCreditScreen({super.key});

  @override
  State<RequestCreditScreen> createState() => _RequestCreditScreenState();
}

class _RequestCreditScreenState extends State<RequestCreditScreen> {
  double _monto = 200;
  String? _motivoSeleccionado;
  bool _enviando = false;

  final motivos = const [
    {'icon': Icons.local_gas_station_outlined, 'label': 'Combustible'},
    {'icon': Icons.build_outlined, 'label': 'Repuestos'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'Mercadería'},
    {'icon': Icons.more_horiz, 'label': 'Otros'},
  ];

  Future<void> _continuar() async {
    if (_motivoSeleccionado == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Elige para qué usarás el crédito')));
      return;
    }
    setState(() => _enviando = true);
    try {
      await ApiService.solicitarCredito(_monto, _motivoSeleccionado!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar crédito'), leading: const BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Cuánto necesitas?', style: TextStyle(color: MoviCashColors.textoGris)),
            Center(
              child: Text('S/ ${_monto.round()}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            ),
            Slider(
              value: _monto,
              min: 50,
              max: 500,
              divisions: 45,
              activeColor: MoviCashColors.lilaInnovacion,
              onChanged: (v) => setState(() => _monto = v),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('S/ 50'), Text('S/ 500')],
            ),
            const SizedBox(height: 24),
            const Text('¿Para qué lo usarás?', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...motivos.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(m['icon'] as IconData, color: MoviCashColors.lilaInnovacion),
                    title: Text(m['label'] as String),
                    trailing: Radio<String>(
                      value: m['label'] as String,
                      groupValue: _motivoSeleccionado,
                      onChanged: (v) => setState(() => _motivoSeleccionado = v),
                      activeColor: MoviCashColors.lilaInnovacion,
                    ),
                    onTap: () => setState(() => _motivoSeleccionado = m['label'] as String),
                  ),
                )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviando ? null : _continuar,
                child: _enviando
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Continuar'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: MoviCashColors.textoGris),
                  SizedBox(width: 6),
                  Text('Tu información está segura', style: TextStyle(color: MoviCashColors.textoGris)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
