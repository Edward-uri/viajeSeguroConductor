import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/core_module.dart';
import '../../../core/http/api_exception.dart';
import '../../../core/widgets/logo_badge.dart';
import '../../../features/documents/di/documents_module.dart';
import '../../../features/documents/presentation/utils/document_route_helper.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/theme.dart';


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
    // Mantiene la sesión: si hay token válido entra directo según el estado de
    // documentos (no aprobado → siempre ve el estado de sus documentos). Si la
    // sesión venció (refresh también falló) → login. Sin sesión → bienvenida.
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
    final repo = ref.read(documentoRepositoryProvider);
    String route;
    try {
      route = await resolveDocumentsRoute(repo);
    } on UnauthorizedException {
      await session.logout();
      route = AppRoutes.login;
    }
    if (!mounted) return;
    context.go(route);
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
