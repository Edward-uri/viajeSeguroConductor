import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../theme/theme.dart';

/// Portada de la app del conductor: marca + propuesta de valor.
/// Sin ilustraciones — la página cuenta qué hace la app por el chofer
/// con el mismo lenguaje tipográfico del resto de la app.
class GetstartedScreen extends StatefulWidget {
  const GetstartedScreen({super.key});

  @override
  State<GetstartedScreen> createState() => _GetstartedScreenState();
}

class _GetstartedScreenState extends State<GetstartedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  late final Animation<double> _marcaFade;
  late final Animation<Offset> _marcaSlide;
  late final List<Animation<double>> _filas;

  static const _valores = [
    (
      Icons.near_me_outlined,
      'Viajes cerca de ti',
      'Recibe solicitudes de tu zona y acéptalas al instante.',
    ),
    (
      Icons.payments_outlined,
      'Ganancias claras',
      'Lo que ganas, día por día y sin sorpresas.',
    ),
    (
      Icons.work_outline,
      'Bolsa de trabajo',
      '¿Sin mototaxi? Conecta con propietarios que buscan conductor.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _marcaFade = CurvedAnimation(
      parent: _entrada,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _marcaSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_marcaFade);
    _filas = List.generate(
      _valores.length,
      (i) => CurvedAnimation(
        parent: _entrada,
        curve: Interval(0.25 + i * 0.15, 0.6 + i * 0.15,
            curve: Curves.easeOut),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _entrada.value = 1;
      } else {
        _entrada.forward();
      }
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    // orientationOf: no re-construye esta pantalla (queda viva bajo la de
    // login) en cada frame de la animación del teclado.
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final accent = isLight ? JalaBrand.amberDeep : JalaBrand.amberLight;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Marca: wordmark + tag CONDUCTOR + claim ───
              FadeTransition(
                opacity: _marcaFade,
                child: SlideTransition(
                  position: _marcaSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Jala',
                            style: text.displayLarge?.copyWith(
                              fontSize: isLandscape ? 44 : 64,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: isLandscape ? 8 : 14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: JalaBrand.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'CONDUCTOR',
                                style: text.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          text: 'Conduce por tu pueblo,\n',
                          style: text.titleLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: scheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: 'gana a tu ritmo.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ─── Propuesta de valor (solo portrait) ───
              if (!isLandscape)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _valores.length; i++) ...[
                        if (i > 0) const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _filas[i],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.12),
                              end: Offset.zero,
                            ).animate(_filas[i]),
                            child: _ValueRow(
                              icon: _valores[i].$1,
                              titulo: _valores[i].$2,
                              detalle: _valores[i].$3,
                              accent: accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                const Spacer(),
              // ─── Acciones ───
              GradientButton(
                label: 'Comenzar',
                icon: Icons.arrow_forward,
                onPressed: () => context.push(AppRoutes.registerEmail),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => context.push(AppRoutes.login),
                child: const Text('Ya tengo cuenta · Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String detalle;
  final Color accent;

  const _ValueRow({
    required this.icon,
    required this.titulo,
    required this.detalle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: JalaBrand.amber.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                detalle,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
