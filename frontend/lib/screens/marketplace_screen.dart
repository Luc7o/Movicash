import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _entidades = [];
  List<dynamic> _solicitudes = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final entidades = await ApiService.entidadesMarketplace();
      final solicitudes = await ApiService.misSolicitudesMarketplace();
      setState(() {
        _entidades = entidades as List<dynamic>;
        _solicitudes = solicitudes as List<dynamic>;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _solicitar(Map entidad) async {
    final montoCtrl = TextEditingController(text: '500');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Solicitar con ${entidad['nombre']}'),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Monto solicitado (S/)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enviar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.solicitarEnMarketplace(entidad['id'], double.parse(montoCtrl.text));
      _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Solicitud enviada. Te avisaremos cuando la revisen.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MoviCashColors.lilaInnovacion,
          indicatorColor: MoviCashColors.lilaInnovacion,
          tabs: const [Tab(text: 'Entidades'), Tab(text: 'Mis solicitudes')],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_listaEntidades(), _listaSolicitudes()],
            ),
    );
  }

  Widget _listaEntidades() {
    if (_entidades.isEmpty) {
      return const Center(child: Text('Todavía no hay entidades aliadas disponibles.'));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _entidades.length,
        itemBuilder: (context, i) {
          final e = _entidades[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: MoviCashColors.celesteSeguridad.withValues(alpha: 0.15),
                    child: const Icon(Icons.account_balance_outlined, color: MoviCashColors.celesteSeguridad),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(e['tipo'] ?? '', style: const TextStyle(color: MoviCashColors.textoGris)),
                      ],
                    ),
                  ),
                  OutlinedButton(onPressed: () => _solicitar(e), child: const Text('Solicitar')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _listaSolicitudes() {
    if (_solicitudes.isEmpty) {
      return const Center(child: Text('Aún no has enviado solicitudes al marketplace.'));
    }
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _solicitudes.length,
        itemBuilder: (context, i) {
          final s = _solicitudes[i];
          final entidad = s['entidades_marketplace'];
          Color color;
          switch (s['estado']) {
            case 'aprobada':
              color = MoviCashColors.verdeMenta;
              break;
            case 'rechazada':
              color = Colors.redAccent;
              break;
            default:
              color = MoviCashColors.amarilloPastel;
          }
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(entidad?['nombre'] ?? 'Entidad'),
              subtitle: Text('S/ ${s['monto_solicitado']}'),
              trailing: Chip(
                label: Text(s['estado']),
                backgroundColor: color.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: color),
              ),
            ),
          );
        },
      ),
    );
  }
}
