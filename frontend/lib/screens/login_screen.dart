import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  bool _codigoEnviado = false;
  bool _cargando = false;
  String? _error;
  int _segundosParaReenviar = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _iniciarContador() {
    _segundosParaReenviar = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_segundosParaReenviar <= 1) {
        t.cancel();
        setState(() => _segundosParaReenviar = 0);
      } else {
        setState(() => _segundosParaReenviar--);
      }
    });
  }

  Future<void> _enviarCodigo() async {
    setState(() => _error = null);
    final telefono = _telefonoCtrl.text.trim();
    if (telefono.isEmpty || !telefono.startsWith('+') || telefono.length < 10) {
      setState(() => _error = 'Ingresa tu número con código de país, ej. +51987654321');
      return;
    }
    setState(() => _cargando = true);
    try {
      await AuthService.enviarCodigo(telefono);
      setState(() => _codigoEnviado = true);
      _iniciarContador();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _verificarCodigo() async {
    setState(() => _error = null);
    if (_codigoCtrl.text.trim().length < 4) {
      setState(() => _error = 'Ingresa el código completo que te enviamos');
      return;
    }
    setState(() => _cargando = true);
    try {
      await AuthService.verificarCodigo(_telefonoCtrl.text.trim(), _codigoCtrl.text.trim());
      await _irALaPantallaCorrecta();
    } catch (e) {
      setState(() => _error = 'Código incorrecto o vencido. Inténtalo de nuevo.');
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _irALaPantallaCorrecta() async {
    try {
      final perfil = await ApiService.obtenerPerfil();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => perfil == null ? const CompleteProfileScreen() : const HomeScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoviCashColors.fondoClaro,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Image.asset('assets/logo/movicash_logo.png', height: 130)),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_codigoEnviado) ...[
                              Row(
                                children: const [
                                  Icon(Icons.phone_iphone_outlined, size: 18, color: MoviCashColors.lilaInnovacion),
                                  SizedBox(width: 8),
                                  Text('Ingresa tu número de celular',
                                      style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _telefonoCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  hintText: '+51 9XX XXX XXX',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Incluye el código de país (+51 para Perú)',
                                  style: TextStyle(color: MoviCashColors.textoGris, fontSize: 12)),
                              const SizedBox(height: 18),
                              _botonPrincipal(
                                texto: 'Enviar código',
                                onPressed: _cargando ? null : _enviarCodigo,
                              ),
                            ] else ...[
                              Row(
                                children: const [
                                  Icon(Icons.lock_outline, size: 18, color: MoviCashColors.lilaInnovacion),
                                  SizedBox(width: 8),
                                  Text('Verifica tu número', style: TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Enviamos un código a ${_telefonoCtrl.text}',
                                  style: const TextStyle(color: MoviCashColors.textoGris, fontSize: 13)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _codigoCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, letterSpacing: 6, fontWeight: FontWeight.w600),
                                decoration: const InputDecoration(hintText: '••••••'),
                              ),
                              const SizedBox(height: 18),
                              _botonPrincipal(
                                texto: 'Verificar y entrar',
                                onPressed: _cargando ? null : _verificarCodigo,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _cargando
                                        ? null
                                        : () => setState(() {
                                              _codigoEnviado = false;
                                              _codigoCtrl.clear();
                                              _error = null;
                                            }),
                                    child: const Text('Cambiar número'),
                                  ),
                                  TextButton(
                                    onPressed: (_cargando || _segundosParaReenviar > 0) ? null : _enviarCodigo,
                                    child: Text(_segundosParaReenviar > 0
                                        ? 'Reenviar en ${_segundosParaReenviar}s'
                                        : 'Reenviar código'),
                                  ),
                                ],
                              ),
                            ],
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(_error!,
                                            style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonPrincipal({required String texto, required VoidCallback? onPressed}) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: MoviCashColors.lilaInnovacion,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MoviCashColors.lilaInnovacion.withOpacity(0.5),
        ),
        onPressed: onPressed,
        child: _cargando
            ? const SizedBox(
                height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
            : Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
