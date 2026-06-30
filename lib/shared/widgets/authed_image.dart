import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/core_module.dart';
import '../../core/env/api_config.dart';

/// Carga una imagen protegida del backend (manda el Bearer token) y la muestra
/// con [Image.memory]. Si falla o no hay imagen, muestra [fallback] — nunca se
/// queda girando indefinidamente. Acepta rutas relativas (les antepone baseUrl).
class AuthedImage extends ConsumerStatefulWidget {
  const AuthedImage({
    super.key,
    required this.path,
    required this.size,
    required this.fallback,
  });

  final String? path;
  final double size;
  final Widget fallback;

  @override
  ConsumerState<AuthedImage> createState() => _AuthedImageState();
}

class _AuthedImageState extends ConsumerState<AuthedImage> {
  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(AuthedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _bytes = _load();
  }

  Future<Uint8List?> _load() async {
    final path = widget.path;
    if (path == null || path.isEmpty) return null;
    final url = path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';
    try {
      final token = await ref.read(authStorageProvider).readAccessToken();
      final res = await ref.read(httpClientProvider).get(
        Uri.parse(url),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return res.bodyBytes;
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final bytes = snapshot.data;
        if (bytes == null) return widget.fallback;
        return Image.memory(
          bytes,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}
