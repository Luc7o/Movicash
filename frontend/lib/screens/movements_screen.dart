import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _creditos = [];
  List<dynamic> _aportes = [];
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
      final creditos = await ApiService.historialCreditos();
      final aportes = await ApiService.misAportes();
      setState(() {
        _creditos = creditos as List<dynamic>;
        _aportes = aportes as List<dynamic>;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MoviCashColors.lilaInnovacion,
          indicatorColor: MoviCashColors.lilaInnovacion,
          tabs: const [Tab(text: 'Créditos'), Tab(text: 'Ahorros')],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: TabBarView(
                controller: _tabController,
                children: [_listaCreditos(), _listaAportes()],
              ),
            ),
    );
  }

  Widget _listaCreditos() {
    if (_creditos.isEmpty) {
      return ListView(children: const [
        Padding(
          padding: EdgeInsets.all(30),
          child: Text('Sin movimientos de crédito todavía.', textAlign: TextAlign.center),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _creditos.length,
      itemBuilder: (context, i) {
        final c = _creditos[i];
        final pagos = (c['pagos'] as List<dynamic>? ?? []);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: MoviCashColors.lilaInnovacion.withOpacity(0.12),
              child: const Icon(Icons.account_balance_wallet_outlined, color: MoviCashColors.lilaInnovacion),
            ),
            title: Text('Crédito S/ ${c['monto']}', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${pagos.length} pagos registrados'),
            trailing: Chip(label: Text(c['estado'])),
          ),
        );
      },
    );
  }

  Widget _listaAportes() {
    if (_aportes.isEmpty) {
      return ListView(children: const [
        Padding(
          padding: EdgeInsets.all(30),
          child: Text('Aún no tienes aportes registrados a círculos de ahorro.', textAlign: TextAlign.center),
        ),
      ]);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _aportes.length,
      itemBuilder: (context, i) {
        final a = _aportes[i];
        final circulo = a['circulos_ahorro'];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: MoviCashColors.verdeMenta.withOpacity(0.12),
              child: const Icon(Icons.savings_outlined, color: MoviCashColors.verdeMenta),
            ),
            title: Text(circulo?['nombre'] ?? 'Círculo de ahorro'),
            subtitle: Text('Turno ${a['turno']}'),
            trailing: Text('+ S/ ${a['monto']}',
                style: const TextStyle(color: MoviCashColors.verdeMenta, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}
