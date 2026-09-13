import 'package:flutter/material.dart';
import '../config/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const faqs = [
    {
      'pregunta': '¿Cómo solicito un crédito?',
      'respuesta':
          'Ve a Inicio > Solicitar crédito, elige el monto entre S/50 y S/500, indica para qué lo usarás, y confirma. El dinero queda disponible según tu MoviScore.'
    },
    {
      'pregunta': '¿Qué pasa si un día no puedo pagar la cuota?',
      'respuesta':
          'No hay penalidad inmediata: puedes pagar menos o nada ese día. Eso sí, pagar seguido y a tiempo es lo que hace subir tu MoviScore.'
    },
    {
      'pregunta': '¿Cómo funciona un círculo de ahorro?',
      'respuesta':
          'Un grupo de personas aporta un monto fijo por turno. Cada cierto tiempo, uno de los miembros recibe el total ahorrado. Aportar a tiempo también sube tu MoviScore.'
    },
    {
      'pregunta': '¿Qué es el MoviScore?',
      'respuesta':
          'Es tu historial crediticio dentro de MoviCash (va de 300 a 850). Sube con pagos puntuales, créditos completados y aportes a círculos. Entre más alto, mejores condiciones de crédito tienes.'
    },
    {
      'pregunta': '¿Para qué sirve el Marketplace?',
      'respuesta':
          'Cuando tu MoviScore es alto, puedes usarlo para solicitar créditos más grandes directamente con cajas municipales y cooperativas aliadas.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Preguntas frecuentes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 10),
          ...faqs.map((f) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(f['pregunta']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Text(f['respuesta']!, style: const TextStyle(color: MoviCashColors.textoGris)),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          Card(
            color: MoviCashColors.lilaInnovacion.withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿No encontraste tu respuesta?', style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Escríbenos a soporte@movicash.pe y te ayudamos.',
                      style: TextStyle(color: MoviCashColors.textoGris)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
