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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegistro = GlobalKey<FormState>();

  final _emailLoginCtrl = TextEditingController();
  final _passLoginCtrl = TextEditingController();

  final _emailRegistroCtrl = TextEditingController();
  final _passRegistroCtrl = TextEditingController();
  final _passConfirmarCtrl = TextEditingController();

  bool _cargando = false;
  bool _verPassword = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    setState(() => _error = null);
    if (!_formKeyLogin.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      await AuthService.iniciarSesion(_emailLoginCtrl.text.trim(), _passLoginCtrl.text);
      await _irALaPantallaCorrecta();
    } on AuthException catch (e) {
      setState(() => _error = _traducirError(e.message));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _crearCuenta() async {
    setState(() => _error = null);
    if (!_formKeyRegistro.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      final res = await AuthService.registrarse(_emailRegistroCtrl.text.trim(), _passRegistroCtrl.text);
      if (res.session == null) {
        // El proyecto tiene activada la confirmación por correo: no hay
        // sesión todavía hasta que el usuario haga click en el enlace.
        setState(() {
          _error = null;
          _cargando = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Confirma tu correo'),
              content: Text(
                  'Te enviamos un enlace de confirmación a ${_emailRegistroCtrl.text.trim()}. Ábrelo y luego vuelve aquí para iniciar sesión.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _tabController.animateTo(0);
                    _emailLoginCtrl.text = _emailRegistroCtrl.text.trim();
                  },
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
        }
        return;
      }
      await _irALaPantallaCorrecta();
    } on AuthException catch (e) {
      setState(() => _error = _traducirError(e.message));
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _traducirError(String msg) {
    if (msg.contains('Invalid login credentials')) return 'Correo o contraseña incorrectos.';
    if (msg.contains('User already registered')) return 'Ya existe una cuenta con ese correo. Inicia sesión.';
    if (msg.contains('Password should be')) return 'La contraseña debe tener al menos 6 caracteres.';
    return msg;
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
                  Center(child: Image.asset('assets/logo/movicash_logo.png', height: 120)),
                  const SizedBox(height: 20),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          labelColor: MoviCashColors.lilaInnovacion,
                          unselectedLabelColor: MoviCashColors.textoGris,
                          indicatorColor: MoviCashColors.lilaInnovacion,
                          tabs: const [
                            Tab(text: 'Iniciar sesión'),
                            Tab(text: 'Crear cuenta'),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(22),
                          child: SizedBox(
                            height: _tabController.index == 0 ? 260 : 320,
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [_formularioLogin(), _formularioRegistro()],
                            ),
                          ),
                        ),
                      ],
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

  Widget _formularioLogin() {
    return Form(
      key: _formKeyLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailLoginCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passLoginCtrl,
            obscureText: !_verPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                if (_emailLoginCtrl.text.trim().isEmpty) {
                  setState(() => _error = 'Escribe tu correo arriba primero para recuperar tu contraseña.');
                  return;
                }
                await AuthService.recuperarContrasena(_emailLoginCtrl.text.trim());
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Te enviamos un enlace para recuperar tu contraseña.')));
                }
              },
              child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12)),
            ),
          ),
          if (_error != null) _mensajeError(),
          const SizedBox(height: 8),
          _botonPrincipal('Iniciar sesión', _cargando ? null : _iniciarSesion),
        ],
      ),
    );
  }

  Widget _formularioRegistro() {
    return Form(
      key: _formKeyRegistro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailRegistroCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Correo', prefixIcon: Icon(Icons.email_outlined)),
            validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passRegistroCtrl,
            obscureText: !_verPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passConfirmarCtrl,
            obscureText: !_verPassword,
            decoration: const InputDecoration(
                labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
            validator: (v) => (v != _passRegistroCtrl.text) ? 'Las contraseñas no coinciden' : null,
          ),
          if (_error != null) _mensajeError(),
          const SizedBox(height: 14),
          _botonPrincipal('Crear cuenta', _cargando ? null : _crearCuenta),
        ],
      ),
    );
  }

  Widget _mensajeError() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _botonPrincipal(String texto, VoidCallback? onPressed) {
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
