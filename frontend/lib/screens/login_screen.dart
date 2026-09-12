import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _telefonoCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  bool _codigoEnviado = false;
  bool _cargando = false;

  Future<void> _enviarCodigo() async {
    setState(() => _cargando = true);
    try {
      await AuthService.enviarCodigo(_telefonoCtrl.text.trim());
      setState(() => _codigoEnviado = true);
    } catch (e) {
      _mostrarError('$e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _verificarCodigo() async {
    setState(() => _cargando = true);
    try {
      await AuthService.verificarCodigo(_telefonoCtrl.text.trim(), _codigoCtrl.text.trim());
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _mostrarError('$e');
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_balance_wallet, size: 48, color: MoviCashColors.lilaInnovacion),
              const SizedBox(height: 12),
              const Text('MoviCash', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Text('Tu dinero, a tu ritmo', style: TextStyle(color: MoviCashColors.textoGris)),
              const SizedBox(height: 32),
              if (!_codigoEnviado) ...[
                const Text('Ingresa tu número de celular'),
                const SizedBox(height: 8),
                TextField(
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+51 9XX XXX XXX',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargando ? null : _enviarCodigo,
                  child: Text(_cargando ? 'Enviando...' : 'Enviar código'),
                ),
              ] else ...[
                const Text('Ingresa el código que te enviamos por SMS'),
                const SizedBox(height: 8),
                TextField(
                  controller: _codigoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '123456', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _cargando ? null : _verificarCodigo,
                  child: Text(_cargando ? 'Verificando...' : 'Verificar y entrar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
