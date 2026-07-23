import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/utils/image_utils.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../theme/jala_theme.dart';
import '../provider/driver_profile_viewmodel.dart';
import '../provider/edit_profile_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _correoController = TextEditingController();

  // Foto recién elegida: se muestra al instante (la URL por-id no cambia).
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(driverProfileViewModelProvider).user;
      if (user == null) return;

      final vm = ref.read(editProfileViewModelProvider);

      _nombreController.text = user.nombre ?? '';
      _apellidoPaternoController.text = user.apellidoPaterno ?? '';
      _apellidoMaternoController.text = user.apellidoMaterno ?? '';
      _correoController.text = user.correoElectronico ?? '';

      vm.setNombre(user.nombre ?? '');
      vm.setApellidoPaterno(user.apellidoPaterno ?? '');
      vm.setApellidoMaterno(user.apellidoMaterno ?? '');
    });

    _nombreController.addListener(_onNombreChanged);
    _apellidoPaternoController.addListener(_onApellidoPaternoChanged);
    _apellidoMaternoController.addListener(_onApellidoMaternoChanged);
  }

  void _onNombreChanged() =>
      ref.read(editProfileViewModelProvider).setNombre(_nombreController.text);
  void _onApellidoPaternoChanged() =>
      ref.read(editProfileViewModelProvider).setApellidoPaterno(_apellidoPaternoController.text);
  void _onApellidoMaternoChanged() =>
      ref.read(editProfileViewModelProvider).setApellidoMaterno(_apellidoMaternoController.text);

  @override
  void dispose() {
    _nombreController.removeListener(_onNombreChanged);
    _apellidoPaternoController.removeListener(_onApellidoPaternoChanged);
    _apellidoMaternoController.removeListener(_onApellidoMaternoChanged);
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(editProfileViewModelProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final driverVm =
                            ref.watch(driverProfileViewModelProvider);
                        final user = driverVm.user;
                        final initials =
                            (user?.nombre ?? user?.correoElectronico ?? 'N/A')
                                .substring(0, 1)
                                .toUpperCase();
                        return GestureDetector(
                          onTap: driverVm.isUploadingPhoto ? null : _cambiarFoto,
                          child: Stack(
                            children: [
                              ClipOval(
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  color: JalaBrand.amber,
                                  alignment: Alignment.center,
                                  child: _pickedBytes != null
                                      ? Image.memory(
                                          _pickedBytes!,
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        )
                                      : AuthedImage(
                                          path: user?.fotoPerfilUrl,
                                          size: 96,
                                          version: driverVm.photoVersion,
                                          fallback: Text(
                                            initials,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: JalaBrand.amber,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (driverVm.isUploadingPhoto)
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Tus datos',
                      style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apellidoPaternoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido paterno',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apellidoMaternoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido materno (opcional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Cuenta',
                      style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  // El correo es de solo lectura (igual que en la app
                  // pasajero): se muestra pero no se envía al backend.
                  TextField(
                    controller: _correoController,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: const Icon(Icons.alternate_email),
                      helperText: 'El correo no se puede modificar',
                      filled: true,
                      fillColor: context.brand.surfaceLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (vm.errorMessage != null)
                    _ErrorBanner(message: vm.errorMessage!),
                  if (vm.errorMessage != null) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: vm.canSubmit && !vm.isLoading
                          ? _guardar
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: JalaBrand.amber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
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

  Future<void> _guardar() async {
    final vm = ref.read(editProfileViewModelProvider);
    final ok = await vm.submit();
    if (!mounted) return;
    if (ok) {
      context.pop();
    }
  }

  Future<void> _cambiarFoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 88);
    if (picked == null) return;
    final jpeg = await compressToJpeg(await picked.readAsBytes());
    if (!mounted) return;
    setState(() => _pickedBytes = jpeg);

    final ok = await ref
        .read(driverProfileViewModelProvider)
        .uploadPhoto(bytes: jpeg, fileName: 'perfil.jpg');
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada')),
      );
    } else {
      setState(() => _pickedBytes = null); // revierte a la foto del servidor
      final msg = ref.read(driverProfileViewModelProvider).errorMessage ??
          'No se pudo actualizar la foto';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
