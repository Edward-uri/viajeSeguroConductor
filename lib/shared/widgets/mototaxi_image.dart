import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

/// Muestra el mototaxi de la unidad según su color, dentro de un chip con fondo
/// que contrasta (los SVG son siluetas de un solo color): color claro → fondo
/// oscuro, color oscuro → fondo claro. Sin sombras.
class MototaxiImage extends StatelessWidget {
  const MototaxiImage({super.key, required this.colorNombre, this.size = 48});

  final String colorNombre;
  final double size;

  static const _default = 'assets/mototaxi/mototaxi_default.svg';

  /// color de unidad → (slug de archivo, color representativo para el contraste)
  static const _mapa = <String, (String, Color)>{
    'blanco': ('blanco', Color(0xFFF5F5F5)),
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
    final tint = entry?.$2 ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final variante =
        entry == null ? null : 'assets/mototaxi/mototaxi_${entry.$1}.svg';

    // Fondo contrastante fijo (independiente del tema) para que cualquier color resalte.
    final bg = tint.computeLuminance() > 0.45
        ? const Color(0xFF33373E)
        : const Color(0xFFE8EAED);

    final fallback = _svg(_default, ColorFilter.mode(tint, BlendMode.srcIn));
    Widget contenido;
    if (variante == null) {
      contenido = fallback;
    } else {
      final known = _cache[variante];
      if (known == true) {
        contenido = _svg(variante, null);
      } else if (known == false) {
        contenido = fallback;
      } else {
        contenido = FutureBuilder<bool>(
          future: _bundled(variante),
          builder: (context, snap) =>
              snap.data == true ? _svg(variante, null) : fallback,
        );
      }
    }

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: contenido,
    );
  }

  Widget _svg(String path, ColorFilter? filter) =>
      SvgPicture.asset(path, fit: BoxFit.contain, colorFilter: filter);

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
