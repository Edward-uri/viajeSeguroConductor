import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/reputation_chips.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/theme.dart';
import '../provider/ride_inbox_viewmodel.dart';

class RideRequestScreen extends ConsumerStatefulWidget {
  const RideRequestScreen({super.key});

  @override
  ConsumerState<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends ConsumerState<RideRequestScreen> {
  static const _segundos = 15;
  int _countdown = _segundos;
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
        await ref.read(rideInboxViewModelProvider.notifier).rejectRide();
        if (mounted) context.pop();
        return false;
      }
      return _countdown > 0;
    });
  }

  Future<void> _rechazar() async {
    await ref.read(rideInboxViewModelProvider.notifier).rejectRide();
    if (mounted) context.pop();
  }

  Future<void> _aceptar() async {
    setState(() => _aceptando = true);
    final viaje = await ref.read(rideInboxViewModelProvider.notifier).acceptRide();
    if (!mounted) return;
    if (viaje != null) {
      context.pushReplacement(AppRoutes.rideInProgress, extra: viaje);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final request =
        ref.watch(rideInboxViewModelProvider.select((s) => s.currentRequest));

    if (request == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final urgente = _countdown <= 5;
    final acento = urgente ? scheme.error : JalaBrand.success;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Cuenta regresiva: barra que se vacía + segundos ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _countdown / _segundos,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(acento),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_countdown}s',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: urgente ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NUEVA SOLICITUD',
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            // ─── Contenido ───
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarifa protagonista
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '\$${request.monto.toStringAsFixed(2)}',
                            style: text.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'MXN · ${request.metodoPago}',
                            style: text.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Pasajero
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: scheme.primaryContainer,
                            child: Text(
                              request.pasajeroIniciales.isNotEmpty
                                  ? request.pasajeroIniciales
                                  : '?',
                              style: text.titleMedium?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.nombreCompleto.isNotEmpty
                                      ? request.nombreCompleto
                                      : 'Pasajero',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 15, color: scheme.tertiary),
                                    const SizedBox(width: 3),
                                    Text(
                                      request.pasajeroCalificacion
                                          .toStringAsFixed(1),
                                      style: text.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                ReputationChips(
                                  idUsuario: request.idPasajero,
                                  rol: 'pasajero',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ruta
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _routePoint(
                            true,
                            request.origen,
                            'Recoger · ${request.origenDistancia}',
                            scheme,
                            text,
                          ),
                          _routeConnector(scheme),
                          _routePoint(
                            false,
                            request.destino,
                            'Destino del pasajero',
                            scheme,
                            text,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Meta
                    Row(
                      children: [
                        _chip(Icons.route_rounded,
                            '${request.distanciaKm.toStringAsFixed(1)} km',
                            scheme, text),
                        const SizedBox(width: 8),
                        _chip(Icons.schedule_rounded,
                            '${request.duracionMin} min', scheme, text),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ─── Acciones ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _aceptando ? null : _rechazar,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: BorderSide(color: scheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: GradientButton(
                        label: _aceptando ? 'Aceptando…' : 'Aceptar viaje',
                        onPressed: _aceptando ? null : _aceptar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routePoint(bool origen, String title, String subtitle,
      ColorScheme scheme, TextTheme text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: origen
              ? Icon(Icons.trip_origin, size: 16, color: JalaBrand.success)
              : Icon(Icons.location_on, size: 18, color: scheme.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isNotEmpty
                    ? title
                    : (origen ? 'Punto de encuentro' : 'Destino'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style:
                    text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _routeConnector(ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(left: 7),
      alignment: Alignment.centerLeft,
      child: Container(width: 2, height: 18, color: scheme.outlineVariant),
    );
  }

  Widget _chip(
      IconData icon, String label, ColorScheme scheme, TextTheme text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: text.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
