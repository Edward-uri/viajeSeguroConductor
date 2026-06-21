import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/documento.dart';
import '../provider/documents_viewmodel.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  XFile? _selectedFile;
  Uint8List? _fileBytes;
  bool _isUploading = false;
  String _detectedExt = '';
  String? _formatError;

  static bool _isHeic(Uint8List bytes) {
    if (bytes.length < 12) return false;
    final h = bytes.sublist(0, 12);
    // ftyp...heic or ftyp...heix
    if (h[0] == 0x66 && h[1] == 0x74 && h[2] == 0x79 && h[3] == 0x70) {
      for (int i = 4; i + 4 <= 12; i++) {
        if (h[i] == 0x68 && h[i + 1] == 0x65) return true; // hei
      }
    }
    // avif
    if (h[0] == 0x00 && h[1] == 0x00 && h[2] == 0x00 && h[3] == 0x1C &&
        h[4] == 0x66 && h[5] == 0x74 && h[6] == 0x79 && h[7] == 0x70 &&
        h[8] == 0x61 && h[9] == 0x76 && h[10] == 0x69 && h[11] == 0x66) {
      return true;
    }
    return false;
  }

  static String _detectExtension(Uint8List bytes) {
    if (bytes.length < 4) return 'bin';
    final h = bytes.sublist(0, 4);
    if (h[0] == 0xFF && h[1] == 0xD8) return 'jpg';
    if (h[0] == 0x89 && h[1] == 0x50) return 'png';
    if (h[0] == 0x47 && h[1] == 0x49) return 'gif';
    if (h[0] == 0x52 && h[1] == 0x49) return 'webp';
    if (h[0] == 0x25 && h[1] == 0x50) return 'pdf';
    return 'bin';
  }

  static String _formatLabel(Uint8List bytes) {
    if (bytes.length < 4) return 'desconocido';
    final h = bytes.sublist(0, 4);
    if (h[0] == 0xFF && h[1] == 0xD8) return 'JPEG';
    if (h[0] == 0x89 && h[1] == 0x50) return 'PNG';
    if (h[0] == 0x47 && h[1] == 0x49) return 'GIF';
    if (h[0] == 0x52 && h[1] == 0x49) return 'WEBP';
    if (h[0] == 0x66 && h[1] == 0x74) return 'HEIC/HEIF';
    if (h[0] == 0x00 && h[1] == 0x00) return 'HEIC/HEIF';
    if (h[0] == 0x25 && h[1] == 0x50) return 'PDF';
    return '0x${h[0].toRadixString(16)} 0x${h[1].toRadixString(16)} ...';
  }

  (Uint8List, String) _toJpeg(Uint8List bytes, String ext) {
    final image = img.decodeImage(bytes);
    if (image != null) {
      return (img.encodeJpg(image, quality: 85), 'jpg');
    }
    debugPrint('[Upload] decodeImage falló — conservando formato $ext');
    return (bytes, ext);
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _formatError = null);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();

      if (_isHeic(bytes)) {
        debugPrint('[Upload] HEIC/HEIF detectado — no se puede convertir a JPEG');
        setState(() {
          _formatError = 'Formato HEIC no compatible. iOS convierte automáticamente a JPEG al usar la cámara. Intenta de nuevo o elige de la galería.';
        });
        return;
      }

      final origExt = _detectExtension(bytes);
      final label = _formatLabel(bytes);
      debugPrint('[Upload] Origen: $label (.$origExt, ${bytes.length} bytes)');
      final (converted, finalExt) = _toJpeg(bytes, origExt);
      debugPrint('[Upload] Salida: .$finalExt (${converted.length} bytes)');
      setState(() {
        _selectedFile = picked;
        _fileBytes = converted;
        _detectedExt = finalExt;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null || _fileBytes == null) return;
    final doc = ModalRoute.of(context)?.settings.arguments as Documento?;
    if (doc == null) return;

    final format = _formatLabel(_fileBytes!);
    debugPrint('[Upload] Subiendo ${doc.id}.$_detectedExt — formato real: $format (${_fileBytes!.length} bytes)');

    setState(() => _isUploading = true);
    try {
      await ref.read(documentsViewModelProvider).subirDocumento(
            doc.id,
            _fileBytes!,
            '${doc.id}.$_detectedExt',
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = ModalRoute.of(context)?.settings.arguments as Documento?;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(doc?.nombre ?? 'Subir documento')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toma una foto clara ${doc?.nombre.toLowerCase() ?? 'del documento'}.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.camera),
                child: Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: scheme.outlineVariant,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    image: _fileBytes != null
                        ? DecorationImage(
                            image: MemoryImage(_fileBytes!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _fileBytes == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 64,
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tocar para tomar foto',
                                style: text.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir de la galería'),
              ),
              if (_formatError != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEAE6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 20, color: Color(0xFFD84315)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _formatError!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFD84315)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Tips para una aprobación rápida:',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _tipRow('Buena iluminación, sin reflejos'),
              _tipRow('El documento completo y enfocado'),
              _tipRow('Todos los datos legibles'),
              const SizedBox(height: 8),
              Text(
                'JPG, PNG o PDF - máx. 5 MB',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GradientButton(
                label: _isUploading ? 'Subiendo...' : 'Subir documento',
                onPressed: _selectedFile != null && !_isUploading && _formatError == null ? _upload : null,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 16, color: const Color(0xFF1E8E5A)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
