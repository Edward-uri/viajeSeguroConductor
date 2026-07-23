import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Muestra el mototaxi de la unidad según su color.
/// - Si existe `assets/mototaxi/mototaxi_<color>.svg` (variante que provee el
///   negocio), la usa; si no, cae a la silueta genérica tintada.
/// Las variantes son siluetas de un solo color, así que se les pone un halo
/// suave según el tema para que hasta el blanco/negro resalten en claro y oscuro.
class MototaxiImage extends StatelessWidget {
  const MototaxiImage({super.key, required this.colorNombre, this.size = 48});

  final String colorNombre;
  final double size;

  static const _default = 'assets/mototaxi/mototaxi_default.svg';

  /// color de unidad → (slug de archivo, color para tintar la silueta fallback)
  static const _mapa = <String, (String, Color)>{
    'blanco': ('blanco', Color(0xFFBDBDBD)),
    'rojo': ('rojo', Color(0xFFD84315)),
    'azul': ('azul', Color(0xFF1976D2)),
    'negro': ('negro', Color(0xFF212121)),
    'verde': ('verde', Color(0xFF2E7D32)),
    'amarillo': ('amarillo', Color(0xFFF9A825)),
    'gris': ('gris', Color(0xFF757575)),
    'naranja': ('naranja', Color(0xFFEF6C00)),
  };

  static final Map<String, bool> _cache = {};

  @override
  Widget build(BuildContext context) {
    final entry = _mapa[colorNombre.trim().toLowerCase()];
    final variante =
        entry == null ? null : 'assets/mototaxi/mototaxi_${entry.$1}.svg';

    // Sin color conocido → silueta tintada al onSurfaceVariant.
    if (variante == null) {
      final tint = Theme.of(context).colorScheme.onSurfaceVariant;
      return _conHalo(context, _default,
          tint: ColorFilter.mode(tint, BlendMode.srcIn));
    }

    final fallback = _conHalo(context, _default,
        tint: ColorFilter.mode(entry!.$2, BlendMode.srcIn));

    final known = _cache[variante];
    if (known == true) return _conHalo(context, variante);
    if (known == false) return fallback;

    return FutureBuilder<bool>(
      future: _bundled(variante),
      builder: (context, snap) =>
          snap.data == true ? _conHalo(context, variante) : fallback,
    );
  }

  /// SVG con un halo suave detrás (contrasta con el fondo según el tema).
  Widget _conHalo(BuildContext context, String path, {ColorFilter? tint}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final halo = dark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.35);
    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: size * 0.06, sigmaY: size * 0.06),
          child: SvgPicture.asset(
            path,
            width: size,
            height: size,
            colorFilter: ColorFilter.mode(halo, BlendMode.srcIn),
          ),
        ),
        SvgPicture.asset(path, width: size, height: size, colorFilter: tint),
      ],
    );
  }

  static Future<bool> _bundled(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    try {
      await rootBundle.load(path);
      _cache[path] = true;
    } catch (_) {
      _cache[path] = false;
    }
    return _cache[path]!;
  }
}
