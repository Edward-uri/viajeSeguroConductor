import 'package:flutter/material.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../theme/theme.dart';

/// Plantilla de los pasos del registro: eyebrow "PASO X DE N" + título +
/// caption alineados a la izquierda, contenido scrolleable y CTA fijo al
/// fondo que sube con el teclado (mismo lenguaje que el login/portada).
class PasoRegistroScaffold extends StatelessWidget {
  static const totalPasos = 6;

  final int paso;
  final String titulo;
  final String caption;
  final List<Widget> children;
  final String ctaLabel;
  final VoidCallback? onCta;

  /// Acción secundaria bajo el CTA (reenviar código, omitir, etc.).
  final Widget? belowCta;

  const PasoRegistroScaffold({
    super.key,
    required this.paso,
    required this.titulo,
    required this.caption,
    required this.children,
    required this.ctaLabel,
    required this.onCta,
    this.belowCta,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = isLight ? JalaBrand.amberDeep : JalaBrand.amberLight;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PASO $paso DE $totalPasos',
                style: text.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                caption,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientButton(label: ctaLabel, onPressed: onCta),
                if (belowCta != null) ...[
                  const SizedBox(height: 4),
                  belowCta!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
