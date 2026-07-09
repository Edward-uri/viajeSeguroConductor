import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../shared/utils/image_utils.dart';
import '../../../../profile/presentation/provider/profile_viewmodel.dart';
import 'paso_registro_scaffold.dart';

/// Último paso del registro: foto de perfil (opcional). El usuario ya está
/// autenticado tras completar el registro, así que la subida usa el token actual.
class RegisterPhotoScreen extends ConsumerStatefulWidget {
  const RegisterPhotoScreen({super.key});

  @override
  ConsumerState<RegisterPhotoScreen> createState() =>
      _RegisterPhotoScreenState();
}

class _RegisterPhotoScreenState extends ConsumerState<RegisterPhotoScreen> {
  Uint8List? _bytes;
  bool _subiendo = false;

  Future<void> _pick(ImageSource source) async {
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 88);
    if (picked == null) return;
    final jpeg = await compressToJpeg(await picked.readAsBytes());
    if (!mounted) return;
    setState(() => _bytes = jpeg);
  }

  void _irAlHome() {
    context.go(AppRoutes.driverHome);
  }

  Future<void> _subir() async {
    if (_bytes == null) {
      _irAlHome();
      return;
    }
    setState(() => _subiendo = true);
    final ok =
        await ref.read(profileViewModelProvider).uploadNewPhoto(bytes: _bytes!);
    if (!mounted) return;
    setState(() => _subiendo = false);
    if (ok) {
      _irAlHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No se pudo subir la foto. Puedes hacerlo luego desde tu perfil.')),
      );
      _irAlHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PasoRegistroScaffold(
      paso: 6,
      titulo: 'Agrega tu foto',
      caption:
          'Ayuda a los pasajeros a reconocerte. Puedes omitirla y agregarla después.',
      ctaLabel: _subiendo
          ? 'Subiendo…'
          : (_bytes != null ? 'Continuar' : 'Omitir por ahora'),
      onCta: _subiendo ? null : _subir,
      belowCta: _bytes != null
          ? TextButton(
              onPressed: _subiendo ? null : _irAlHome,
              child: const Text('Omitir por ahora'),
            )
          : null,
      children: [
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () => _pick(ImageSource.camera),
            child: Container(
              width: 168,
              height: 168,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant, width: 2),
                image: _bytes != null
                    ? DecorationImage(
                        image: MemoryImage(_bytes!), fit: BoxFit.cover)
                    : null,
              ),
              child: _bytes == null
                  ? Icon(Icons.camera_alt_outlined,
                      size: 56,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4))
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
              ),
              TextButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
