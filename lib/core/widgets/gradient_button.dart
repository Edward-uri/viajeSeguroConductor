import 'package:flutter/material.dart';

import '../../theme/theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final effective = onPressed != null && !isLoading;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: effective
              ? const LinearGradient(
                  colors: [Color(0xFFFF8F00), Color(0xFFFFB300)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: effective
              ? null
              : scheme.outlineVariant.withValues(alpha: 0.4),
          boxShadow: effective
              ? [
                  BoxShadow(
                    color: JalaBrand.amber.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effective ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: scheme.onPrimary,
                      ),
                    )
                  : Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: effective
                                ? Colors.white
                                : scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
