import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// Botón principal de la app. Conserva el nombre histórico, pero hoy es un
/// botón plano ámbar de marca (sin degradado ni sombra), como en el Figma.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  /// Icono opcional a la derecha del texto (Figma: "Comenzar →").
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: (onPressed != null && !isLoading) ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: JalaBrand.amber,
          foregroundColor: Colors.white,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: scheme.onSurfaceVariant,
                ),
              )
            : (icon == null
                ? Text(label)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      const SizedBox(width: 8),
                      Icon(icon, size: 20),
                    ],
                  )),
      ),
    );
  }
}
