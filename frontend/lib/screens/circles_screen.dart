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
  List<dynamic> _disponibles = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final mios = await ApiService.misCirculos();
      final disponibles = await ApiService.circulosDisponibles();
      setState(() {
        _misCirculos = mios as List<dynamic>;
        _disponibles = disponibles as List<dynamic>;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _crearCirculo() async {
    final nombreCtrl = TextEditingController();
    final gremioCtrl = TextEditingController();
    final montoCtrl = TextEditingController(text: '50');

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear círculo de ahorro'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del círculo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gremioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Gremio (ej. Mototaxistas)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: montoCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto por turno (S/)',
                  prefixText: 'S/ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok != true) return;
    if (nombreCtrl.text.isEmpty || gremioCtrl.text.isEmpty) return;

    try {
      await ApiService.crearCirculo(nombreCtrl.text, gremioCtrl.text, double.parse(montoCtrl.text));
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Círculo creado!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _unirse(String circuloId) async {
    try {
      await ApiService.unirseACirculo(circuloId);
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Te uniste al círculo!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _aportar(String circuloId) async {
    final montoCtrl = TextEditingController(text: '20');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aportar al círculo'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto a aportar (S/)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aportar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.aportarACirculo(circuloId, double.parse(montoCtrl.text));
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('¡Aporte registrado! Tu MoviScore sube 📈')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final idsUnidos = _misCirculos.map((m) => m['circulo_id']).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Círculos de ahorro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearCirculo,
        backgroundColor: MoviCashColors.lilaInnovacion,
        icon: const Icon(Icons.add),
        label: const Text('Crear círculo'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Card(
                    color: MoviCashColors.lilaInnovacion,
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Junta Digital',
                              style: TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text('Ahorra en comunidad y haz crecer tus oportunidades',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Mis círculos', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (_misCirculos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Aún no perteneces a ningún círculo.',
                          style: TextStyle(color: MoviCashColors.textoGris)),
                    ),
                  ..._misCirculos.map((m) {
                    final circulo = m['circulos_ahorro'];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: MoviCashColors.verdeMenta.withOpacity(0.13),
                          child: const Icon(Icons.groups_outlined, color: MoviCashColors.verdeMenta),
                        ),
                        title: Text(circulo?['nombre'] ?? 'Círculo'),
                        subtitle: Text('S/ ${circulo?['monto_por_turno'] ?? '-'} por turno'),
                        trailing: TextButton(
                          onPressed: () => _aportar(circulo['id']),
                          child: const Text('Aportar'),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text('Círculos disponibles', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (_disponibles.where((c) => !idsUnidos.contains(c['id'])).isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('No hay más círculos disponibles por ahora.',
                          style: TextStyle(color: MoviCashColors.textoGris)),
                    ),
                  ..._disponibles.where((c) => !idsUnidos.contains(c['id'])).map((c) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: MoviCashColors.lilaInnovacion.withOpacity(0.13),
                            child: const Icon(Icons.groups_outlined, color: MoviCashColors.lilaInnovacion),
                          ),
                          title: Text(c['nombre']),
                          subtitle: Text('${c['gremio'] ?? ''} • S/ ${c['monto_por_turno']} por turno'),
                          trailing: OutlinedButton(
                            onPressed: () => _unirse(c['id']),
                            child: const Text('Unirme'),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
