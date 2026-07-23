import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Muestra el mototaxi de la unidad según su color, dentro de un chip con fondo
/// que contrasta (los SVG son siluetas de un solo color): color claro → fondo
/// oscuro, color oscuro → fondo claro. Sin sombras ni sondeos async.
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

  @override
  Widget build(BuildContext context) {
    final entry = _mapa[colorNombre.trim().toLowerCase()];
    final tint = entry?.$2 ?? Theme.of(context).colorScheme.onSurfaceVariant;

    // Color conocido → ilustración a color; desconocido → silueta genérica tintada.
    final path =
        entry != null ? 'assets/mototaxi/mototaxi_${entry.$1}.svg' : _default;
    final filter =
        entry != null ? null : ColorFilter.mode(tint, BlendMode.srcIn);

    // Fondo contrastante fijo para que cualquier color resalte.
    final bg = tint.computeLuminance() > 0.45
        ? const Color(0xFF33373E)
        : const Color(0xFFE8EAED);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: SvgPicture.asset(path, fit: BoxFit.contain, colorFilter: filter),
    );
  }
}
