import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../config/supabase_config.dart';
import 'home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  String? _ocupacion;
  bool _aceptaTerminos = false;
  bool _guardando = false;
  String? _error;

  final ocupaciones = const [
    {'label': 'Mototaxista', 'icon': Icons.two_wheeler_outlined},
    {'label': 'Delivery', 'icon': Icons.delivery_dining_outlined},
    {'label': 'Comerciante', 'icon': Icons.storefront_outlined},
    {'label': 'Otro', 'icon': Icons.work_outline},
  ];

  Future<void> _continuar() async {
    setState(() => _error = null);

    if (!_formKey.currentState!.validate()) return;

    if (_ocupacion == null) {
      setState(() => _error = 'Elige a qué te dedicas para continuar.');
      return;
    }
    if (!_aceptaTerminos) {
      setState(() => _error = 'Debes aceptar los Términos y Condiciones para continuar.');
      return;
    }

    setState(() => _guardando = true);
    try {
      await ApiService.crearPerfil({
        'nombre': _nombreCtrl.text.trim(),
        'dni': _dniCtrl.text.trim(),
        'ubicacion': _ubicacionCtrl.text.trim(),
        'ocupacion': _ocupacion ?? '',
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'No pudimos guardar tu registro: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: MoviCashColors.fondoClaro,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: MoviCashColors.lilaInnovacion.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.badge_outlined, color: MoviCashColors.lilaInnovacion, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Completa tu registro',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Esto nos ayuda a verificarte y ofrecerte mejores condiciones de crédito desde el inicio.',
                style: TextStyle(color: MoviCashColors.textoGris),
              ),
              const SizedBox(height: 24),

              // ---- Tarjeta: datos personales ----
              _seccion(
                titulo: 'Datos personales',
                icon: Icons.person_outline,
                children: [
                  if (email.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18, color: MoviCashColors.textoGris),
                          const SizedBox(width: 8),
                          Text('Cuenta: $email',
                              style: const TextStyle(color: MoviCashColors.textoGris, fontSize: 13)),
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle, size: 16, color: MoviCashColors.verdeMenta),
                        ],
                      ),
                    ),
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre completo' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _dniCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'DNI',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu DNI';
                      if (v.trim().length != 8) return 'El DNI debe tener 8 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ubicacionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad (ej. Tingo María, Huánuco)',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu ciudad' : null,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---- Tarjeta: ocupación ----
              _seccion(
                titulo: '¿A qué te dedicas?',
                icon: Icons.work_outline,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ocupaciones.map((o) {
                      final selected = _ocupacion == o['label'];
                      return ChoiceChip(
                        avatar: Icon(o['icon'] as IconData,
                            size: 18, color: selected ? Colors.white : MoviCashColors.textoGris),
                        label: Text(o['label'] as String),
                        selected: selected,
                        selectedColor: MoviCashColors.lilaInnovacion,
                        labelStyle: TextStyle(color: selected ? Colors.white : MoviCashColors.textoOscuro),
                        onSelected: (_) => setState(() => _ocupacion = o['label'] as String),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---- Términos y condiciones ----
              CheckboxListTile(
                value: _aceptaTerminos,
                onChanged: (v) => setState(() => _aceptaTerminos = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: MoviCashColors.lilaInnovacion,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepto los Términos y Condiciones y la Política de Privacidad de MoviCash',
                  style: TextStyle(fontSize: 13),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MoviCashColors.lilaInnovacion,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: MoviCashColors.lilaInnovacion.withOpacity(0.5),
                  ),
                  onPressed: _guardando ? null : _continuar,
                  child: _guardando
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('Empezar a usar MoviCash',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion({required String titulo, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: MoviCashColors.lilaInnovacion),
                const SizedBox(width: 8),
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
