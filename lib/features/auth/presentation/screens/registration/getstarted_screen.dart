import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../core/widgets/logo_badge.dart';
import '../../../../../routes/app_routes.dart';

class GetstartedScreen extends ConsumerWidget {
  const GetstartedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const LogoBadge(size: 148),
              const SizedBox(height: 28),
              Text(
                'Jala',
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Conduce con Jala',
                style: text.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              GradientButton(
                label: 'Iniciar sesión',
                onPressed: () => context.push(AppRoutes.login),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push(AppRoutes.registerEmail),
                child: const Text('¿No tenés cuenta? Registrarse'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
