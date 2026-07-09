import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/core_module.dart';
import '../../../core/http/api_exception.dart';
import '../../../core/widgets/logo_badge.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';
import '../../profile/di/profile_module.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideRoute());
  }

  Future<void> _decideRoute() async {
    // Mantiene la sesión: si hay token entra directo al home (los documentos
    // ya no bloquean el acceso; son un opt-in desde "Quiero manejar"). Sin
    // sesión → bienvenida.
    final session = ref.read(sessionServiceProvider);
    final results = await Future.wait<dynamic>([
      session.hasSession(),
      Future<void>.delayed(const Duration(milliseconds: 600)),
    ]);
    final hasSession = results[0] as bool;
    if (!mounted) return;
    if (!hasSession) {
      context.go(AppRoutes.getstarted);
      return;
    }
    // Preflight: valida la sesión antes de entrar al home para no mostrar un
    // flash del home cuando el token ya está muerto (el auto-logout global
    // llegaría después de todos modos).
    try {
      final user = await ref.read(profileRepositoryProvider).getMe();
      if (!mounted) return;
      // Cuenta solo-pasajero (sin rol conductor ni propietario): no tiene
      // nada que hacer en driverHome, se le ofrece el upgrade.
      if (!user.esConductor && !user.esPropietario) {
        context.go(AppRoutes.upgradePropietario);
        return;
      }
      context.go(AppRoutes.driverHome);
    } on UnauthorizedException {
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (_) {
      // Sin red / timeout / error del servidor: no bloquear el arranque.
      if (!mounted) return;
      context.go(AppRoutes.driverHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 16),
              child: child,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LogoBadge(size: 148),
              const SizedBox(height: 28),
              Text(
                'Jala',
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Conduce con Jala',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: JalaBrand.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
