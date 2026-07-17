import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      vm.setCorreo(user.correoElectronico ?? '');
    });

    _nombreController.addListener(_onNombreChanged);
    _apellidoPaternoController.addListener(_onApellidoPaternoChanged);
    _apellidoMaternoController.addListener(_onApellidoMaternoChanged);
    _correoController.addListener(_onCorreoChanged);
  }

  void _onNombreChanged() =>
      ref.read(editProfileViewModelProvider).setNombre(_nombreController.text);
  void _onApellidoPaternoChanged() =>
      ref.read(editProfileViewModelProvider).setApellidoPaterno(_apellidoPaternoController.text);
  void _onApellidoMaternoChanged() =>
      ref.read(editProfileViewModelProvider).setApellidoMaterno(_apellidoMaternoController.text);
  void _onCorreoChanged() =>
      ref.read(editProfileViewModelProvider).setCorreo(_correoController.text);

  @override
  void dispose() {
    _nombreController.removeListener(_onNombreChanged);
    _apellidoPaternoController.removeListener(_onApellidoPaternoChanged);
    _apellidoMaternoController.removeListener(_onApellidoMaternoChanged);
    _correoController.removeListener(_onCorreoChanged);
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
                    child: ClipOval(
                      child: Consumer(
                        builder: (context, ref, _) {
                          final user = ref.watch(driverProfileViewModelProvider).user;
                          final initials = (user?.nombre ?? user?.correoElectronico ?? 'N/A')
                              .substring(0, 1)
                              .toUpperCase();
                          return Container(
                            width: 96,
                            height: 96,
                            color: JalaBrand.amber,
                            alignment: Alignment.center,
                            child: AuthedImage(
                              path: user?.fotoPerfilUrl,
                              size: 96,
                              fallback: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
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
                  TextField(
                    controller: _correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.alternate_email),
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
