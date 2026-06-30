import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/data/providers/municipio_provider.dart';
import '../../../../shared/utils/image_utils.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../provider/driver_profile_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  int? _selectedMunicipioId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(driverProfileViewModelProvider).user;
      if (user != null) {
        _emailController.text = user.correoElectronico ?? '';
        _phoneController.text = user.telefono ?? '';
        _selectedMunicipioId = user.idMunicipio;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(driverProfileViewModelProvider);
    final municipiosAsync = ref.watch(municipiosProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: _PhotoEditor(
                    url: vm.user?.fotoPerfilUrl,
                    initials: _initials(vm.user?.correoElectronico),
                    isUploading: vm.isUploadingPhoto,
                    onTap: _cambiarFoto,
                  ),
                ),
                const SizedBox(height: 28),
                Text('Correo electrónico',
                    style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('correo@ejemplo.com'),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) {
                      return 'Correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Teléfono',
                    style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Número de teléfono'),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length < 10) {
                      return 'Teléfono inválido (mín 10 dígitos)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text('Municipio',
                    style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                municipiosAsync.when(
                  data: (municipios) => DropdownButtonFormField<int>(
                    value: _selectedMunicipioId,
                    decoration: _inputDecoration('Selecciona un municipio'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Sin seleccionar'),
                      ),
                      ...municipios.map((m) => DropdownMenuItem<int>(
                            value: m.idMunicipio,
                            child: Text(m.nombre),
                          )),
                    ],
                    onChanged: (v) => setState(() => _selectedMunicipioId = v),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error al cargar municipios'),
                ),
                const SizedBox(height: 40),
                if (vm.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(vm.errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer)),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Guardar cambios',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? 'N/A' : v.substring(0, 1).toUpperCase();
  }

  Future<void> _cambiarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 88);
    if (picked == null) return;
    final jpeg = await compressToJpeg(await picked.readAsBytes());
    if (!mounted) return;
    final ok = await ref
        .read(driverProfileViewModelProvider)
        .uploadPhoto(bytes: jpeg, fileName: 'perfil.jpg');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Foto actualizada' : 'No pudimos actualizar tu foto. Intenta de nuevo.')),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{};
    if (_emailController.text.isNotEmpty) {
      data['correoElectronico'] = _emailController.text;
    }
    if (_phoneController.text.isNotEmpty) {
      data['telefono'] = _phoneController.text;
    }
    if (_selectedMunicipioId != null) {
      data['idMunicipio'] = _selectedMunicipioId;
    }

    await ref.read(driverProfileViewModelProvider.notifier).updateProfile(data);
    if (mounted && ref.read(driverProfileViewModelProvider).errorMessage == null) {
      context.pop();
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: Color(0xFFB6B3B1),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF8F00)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _PhotoEditor extends StatelessWidget {
  const _PhotoEditor({
    required this.url,
    required this.initials,
    required this.isUploading,
    required this.onTap,
  });

  final String? url;
  final String initials;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: Container(
              width: 104,
              height: 104,
              color: scheme.secondaryContainer,
              alignment: Alignment.center,
              child: AuthedImage(
                path: url,
                size: 104,
                fallback: Text(
                  initials,
                  style: text.headlineMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (isUploading)
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00),
                shape: BoxShape.circle,
                border: Border.all(color: scheme.surface, width: 2),
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
