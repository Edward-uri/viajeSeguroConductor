import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/reputation_chips.dart';
import '../../../../routes/app_routes.dart';
import '../provider/home_viewmodel.dart';

class RideRequestScreen extends ConsumerStatefulWidget {
  const RideRequestScreen({super.key});

  @override
  ConsumerState<RideRequestScreen> createState() =>
      _RideRequestScreenState();
}

class _RideRequestScreenState extends ConsumerState<RideRequestScreen> {
  int _countdown = 15;
  bool _aceptando = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
      }
      if (_countdown <= 0 && !_aceptando) {
        await ref.read(homeViewModelProvider).rejectRide();
        if (mounted) context.pop();
        return false;
      }
      return _countdown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final request = vm.currentRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de viaje')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nueva solicitud',
                            style: text.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          if (request != null)
                            Text(
                              '\$${request.monto.toStringAsFixed(2)}',
                              style: text.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (request != null) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.money,
                                      size: 14,
                                      color: scheme.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.metodoPago,
                                    style: text.bodyMedium?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${request.distanciaKm.toStringAsFixed(1)} km · ${request.duracionMin} min',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: _countdown / 15,
                                strokeWidth: 6,
                                backgroundColor: scheme.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    scheme.primary),
                              ),
                              Center(
                                child: Text(
                                  '${_countdown}s',
                                  style: text.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: _countdown <= 3
                                        ? scheme.error
                                        : scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (request != null) ...[
                          Center(
                            child: CircleAvatar(
                              radius: 32,
                              backgroundColor: scheme.primary,
                              child: Text(
                                request.pasajeroIniciales,
                                style: text.titleLarge?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                          Center(
                            child: Text(
                              request.nombreCompleto,
                              style: text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star,
                                    size: 16, color: scheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${request.pasajeroCalificacion.toStringAsFixed(1)} · Pasajera',
                                  style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: ReputationChips(
                              idUsuario: request.idPasajero,
                              rol: 'pasajero',
                            ),
                          ),
                        const SizedBox(height: 24),
                        _locationRow(
                          Icons.circle_outlined,
                          request.origen,
                          'Recoger · ${request.origenDistancia}',
                          scheme.primary,
                          scheme,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 11),
                          child: Container(
                            width: 2,
                            height: 24,
                            color: scheme.outlineVariant,
                          ),
                        ),
                        _locationRow(
                          Icons.location_on_outlined,
                          request.destino,
                          'Destino del pasajero',
                          scheme.primary,
                          scheme,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _aceptando
                          ? null
                          : () async {
                        await vm.rejectRide();
                        if (!context.mounted) return;
                        context.pop();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: BorderSide(color: scheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: GradientButton(
                        label: _aceptando ? 'Aceptando…' : 'Aceptar viaje',
                        onPressed: _aceptando
                            ? null
                            : () async {
                                setState(() => _aceptando = true);
                                final viaje = await vm.acceptRide();
                                if (!context.mounted) return;
                                if (viaje != null) {
                                  context.pushReplacement(
                                    AppRoutes.rideInProgress,
                                    extra: viaje,
                                  );
                                } else {
                                  context.pop();
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationRow(
      IconData icon, String title, String subtitle, Color color, ColorScheme scheme) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
