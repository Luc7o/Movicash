import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../config/supabase_config.dart';
import '../services/api_service.dart';

class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key});

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _ocupacionCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  bool _cargando = true;
  bool _guardando = false;
  String? _dniFotoPath;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final perfil = await ApiService.obtenerPerfil();
      _nombreCtrl.text = perfil['nombre'] ?? '';
      _ubicacionCtrl.text = perfil['ubicacion'] ?? '';
      _ocupacionCtrl.text = perfil['ocupacion'] ?? '';
      _dniCtrl.text = perfil['dni'] ?? '';
      _dniFotoPath = perfil['dni_foto_path'];
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      // El DNI ya no se edita aquí: es el identificador con el que el
      // usuario inicia sesión (verificado una sola vez contra RENIEC
      // durante el registro).
      await ApiService.actualizarPerfil({
        'nombre': _nombreCtrl.text,
        'ubicacion': _ubicacionCtrl.text,
        'ocupacion': _ocupacionCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos guardados ✓')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Sube la foto del DNI a Supabase Storage (bucket privado "kyc-documents")
  /// y guarda solo la referencia en el backend. Base sencilla de KYC.
  Future<void> _subirFotoDni() async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (foto == null) return;

    setState(() => _guardando = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final path = '$userId/dni_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('kyc-documents').upload(path, File(foto.path));
      await ApiService.guardarFotoDni(path);
      setState(() => _dniFotoPath = path);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Foto de DNI subida correctamente ✓')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo')),
          const SizedBox(height: 14),
          TextField(
            controller: _dniCtrl,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'DNI (verificado con RENIEC)',
              suffixIcon: Icon(Icons.lock_outline, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextField(controller: _ubicacionCtrl, decoration: const InputDecoration(labelText: 'Ubicación')),
          const SizedBox(height: 14),
          TextField(
            controller: _ocupacionCtrl,
            decoration: const InputDecoration(labelText: 'Ocupación (ej. mototaxista, delivery)'),
          ),
          const SizedBox(height: 24),
          const Text('Verificación de identidad', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Card(
            color: _dniFotoPath != null
                ? MoviCashColors.verdeMenta.withValues(alpha: 0.1)
                : MoviCashColors.amarilloPastel.withValues(alpha: 0.15),
            child: ListTile(
              leading: Icon(
                _dniFotoPath != null ? Icons.check_circle : Icons.camera_alt_outlined,
                color: _dniFotoPath != null ? MoviCashColors.verdeMenta : MoviCashColors.textoOscuro,
              ),
              title: Text(_dniFotoPath != null ? 'Foto de DNI subida' : 'Sube una foto de tu DNI'),
              subtitle: const Text('Ayuda a que tu solicitud de crédito se procese más rápido'),
              trailing: TextButton(onPressed: _subirFotoDni, child: const Text('Tomar foto')),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                  : const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}
