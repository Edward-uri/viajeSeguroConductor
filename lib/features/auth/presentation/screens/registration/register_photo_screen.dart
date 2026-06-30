import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../profile/presentation/provider/profile_viewmodel.dart';

/// Último paso del registro: foto de perfil (opcional). El usuario ya está
/// autenticado tras completar el registro, así que la subida usa el token actual.
class RegisterPhotoScreen extends ConsumerStatefulWidget {
  const RegisterPhotoScreen({super.key});

  @override
  ConsumerState<RegisterPhotoScreen> createState() =>
      _RegisterPhotoScreenState();
}

const _kDark = Color(0xFF1A1410);
const _kGrey = Color(0xFF6B6661);
const _kOrange = Color(0xFFFF8F00);

class _RegisterPhotoScreenState extends ConsumerState<RegisterPhotoScreen> {
  Uint8List? _bytes;
  bool _subiendo = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 88);
    if (picked == null) return;
    final raw = await picked.readAsBytes();
    final decoded = img.decodeImage(raw);
    setState(() => _bytes = decoded != null ? img.encodeJpg(decoded, quality: 88) : raw);
  }

  void _irADocumentos() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.documents,
      (route) => false,
    );
  }

  Future<void> _subir() async {
    if (_bytes == null) {
      _irADocumentos();
      return;
    }
    setState(() => _subiendo = true);
    final ok = await ref.read(profileViewModelProvider).uploadNewPhoto(bytes: _bytes!);
    if (!mounted) return;
    setState(() => _subiendo = false);
    if (ok) {
      _irADocumentos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir la foto. Puedes hacerlo luego desde tu perfil.')),
      );
      _irADocumentos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu foto')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Agrega tu foto',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ayuda a los pasajeros a reconocerte. Puedes omitirla y agregarla después.',
                style: TextStyle(fontSize: 14, color: _kGrey, height: 1.4),
              ),
              const SizedBox(height: 36),
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
                          ? DecorationImage(image: MemoryImage(_bytes!), fit: BoxFit.cover)
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
              const Spacer(),
              GradientButton(
                label: _subiendo
                    ? 'Subiendo…'
                    : (_bytes != null ? 'Continuar' : 'Omitir por ahora'),
                onPressed: _subiendo ? null : _subir,
              ),
              const SizedBox(height: 8),
              if (_bytes != null)
                TextButton(
                  onPressed: _subiendo ? null : _irADocumentos,
                  child: const Text('Omitir por ahora',
                      style: TextStyle(color: _kOrange, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
