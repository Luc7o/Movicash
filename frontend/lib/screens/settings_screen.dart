import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _recordatoriosPago = true;
  bool _notificacionesCirculos = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          SwitchListTile(
            activeThumbColor: MoviCashColors.lilaInnovacion,
            title: const Text('Recordatorio de pago diario'),
            subtitle: const Text('Te avisamos cada día antes de las 6pm si tienes un pago pendiente'),
            value: _recordatoriosPago,
            onChanged: (v) async {
              setState(() => _recordatoriosPago = v);
              if (v) {
                await NotificationService.programarRecordatorioDiario();
              } else {
                await NotificationService.cancelarRecordatorios();
              }
            },
          ),
          SwitchListTile(
            activeThumbColor: MoviCashColors.lilaInnovacion,
            title: const Text('Avisos de círculos de ahorro'),
            subtitle: const Text('Cuando te toque tu turno o alguien aporte a tu círculo'),
            value: _notificacionesCirculos,
            onChanged: (v) => setState(() => _notificacionesCirculos = v),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text('Acerca de', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: MoviCashColors.textoGris),
            title: Text('Versión de la app'),
            trailing: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
