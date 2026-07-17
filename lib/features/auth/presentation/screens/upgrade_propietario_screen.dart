import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/logo_badge.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/jala_theme.dart';
import '../../di/auth_module.dart';
import '../provider/upgrade_propietario_viewmodel.dart';

/// Cuenta solo-pasajero (registrada en la app pasajero) que inicia sesión en
/// la app del conductor: no tiene rol conductor ni propietario, así que en
/// vez de driverHome se le ofrece registrarse como propietario de mototaxis.
class UpgradePropietarioScreen extends ConsumerWidget {
  const UpgradePropietarioScreen({super.key});

  Future<void> _onActivar(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(upgradePropietarioViewModelProvider).activar();
    if (!context.mounted) return;
    if (result.name == 'ok') {
      context.go(AppRoutes.driverHome);
    } else if (result.name == 'okSinRefresh') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Cuenta activada. Cierra sesión y vuelve a entrar para ver los cambios.'),
          backgroundColor: context.brand.warning,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Cerrar sesión',
            onPressed: () => _onLogout(context, ref),
          ),
        ),
      );
    }
  }

  Future<void> _onLogout(BuildContext context, WidgetRef ref) async {
    await ref.read(sessionServiceProvider).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(upgradePropietarioViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    ref.listen<String?>(
        upgradePropietarioViewModelProvider.select((v) => v.errorMessage),
        (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LogoBadge(size: 100),
                  const SizedBox(height: 24),
                  Text(
                    'Esta cuenta es de pasajero',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Quieres registrarte como propietario para gestionar '
                    'mototaxis?',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    label: 'Registrarme como propietario',
                    isLoading: vm.isWorking,
                    onPressed:
                        vm.isWorking ? null : () => _onActivar(context, ref),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed:
                        vm.isWorking ? null : () => _onLogout(context, ref),
                    child: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
