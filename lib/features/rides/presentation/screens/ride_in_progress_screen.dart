import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/env/api_config.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../provider/home_viewmodel.dart';
import '../provider/ride_progress_viewmodel.dart';

class RideInProgressScreen extends ConsumerStatefulWidget {
  const RideInProgressScreen({super.key});

  @override
  ConsumerState<RideInProgressScreen> createState() =>
      _RideInProgressScreenState();
}

class _RideInProgressScreenState extends ConsumerState<RideInProgressScreen> {
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ride = GoRouterState.of(context).extra as SolicitudViaje?;
      if (ride != null) {
        ref.read(rideProgressViewModelProvider).setRide(ride);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(rideProgressViewModelProvider);
    final ride = vm.ride;
    final scheme = Theme.of(context).colorScheme;

    ref.listen<bool>(
      rideProgressViewModelProvider.select((v) => v.canceladoPorPasajero),
      (_, cancelado) {
        if (cancelado && context.mounted) _avisarCancelado();
      },
    );

    if (ride == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(vm, ride, scheme),
            Expanded(child: _buildMap(vm, ride, scheme)),
            _buildBottomSheet(vm, ride, scheme),
          ],
        ),
      ),
    );
  }

  Future<void> _avisarCancelado() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Viaje cancelado'),
        content: const Text('El pasajero canceló el viaje.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _onSoltar(RideProgressViewModel vm, SolicitudViaje ride) async {
    final enCurso = vm.hasStarted;
    final soltar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(enCurso ? '¿Cancelar este viaje?' : '¿Soltar este viaje?'),
        content: Text(enCurso
            ? 'El viaje en curso se cancelará. Avísale al pasajero el motivo.'
            : 'El viaje volverá a estar disponible para otros conductores.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(enCurso ? 'Cancelar viaje' : 'Soltar'),
          ),
        ],
      ),
    );
    if (soltar != true) return;
    final ok = await vm.soltarViaje();
    if (!mounted) return;
    if (ok) {
      ref.read(homeViewModelProvider).ignorarViaje(ride.id);
      context.go(AppRoutes.driverHome);
    }
  }

  Future<void> _onBackTap(RideProgressViewModel vm) async {
    // Tras iniciar, confirmar antes de abandonar el viaje en curso.
    if (vm.hasStarted) {
      final salir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Salir del viaje?'),
          content: const Text('El viaje sigue en curso. ¿Seguro que quieres salir?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Seguir'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salir'),
            ),
          ],
        ),
      );
      if (salir != true) return;
    }
    if (mounted) context.pop();
  }

  Widget _buildHeader(RideProgressViewModel vm, SolicitudViaje ride, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: vm.hasStarted ? const Color(0xFF1E8E5A) : scheme.surface,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onBackTap(vm),
            child: Icon(
              Icons.arrow_back,
              color: vm.hasStarted ? Colors.white : scheme.onSurface,
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                vm.hasStarted ? 'Viaje en curso' : 'Llegada al origen',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      vm.hasStarted ? Colors.white : scheme.onSurface,
                ),
              ),
              if (!vm.hasStarted)
                Text(
                  '${ride.origenDistancia.isNotEmpty ? ride.origenDistancia : '—'} para llegar',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMap(RideProgressViewModel vm, SolicitudViaje ride, ColorScheme scheme) {
    final markers = <Marker>[];

    if (vm.currentPosition != null) {
      markers.add(
        Marker(
          point: vm.currentPosition!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E8E5A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.motorcycle_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    if (ride.origenLat != null && ride.origenLng != null) {
      markers.add(
        Marker(
          point: LatLng(ride.origenLat!, ride.origenLng!),
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    if (ride.destinoLat != null && ride.destinoLng != null) {
      markers.add(
        Marker(
          point: LatLng(ride.destinoLat!, ride.destinoLng!),
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.error,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.flag, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: vm.currentPosition ??
            LatLng(
              ride.origenLat ?? 19.4326,
              ride.origenLng ?? -99.1332,
            ),
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: ApiConfig.mapboxTilesUrlFor(
              Theme.of(context).brightness),
          userAgentPackageName: 'com.uriel.viajeseguroapp',
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildBottomSheet(RideProgressViewModel vm, SolicitudViaje ride, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              ride.pasajeroIniciales.isNotEmpty
                  ? ride.pasajeroIniciales
                  : '?',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ride.pasajeroNombre.isNotEmpty ? ride.pasajeroNombre : 'Pasajero',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${ride.origen} → ${ride.destino}',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!vm.hasStarted) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: vm.isLoading ? null : () => vm.startRide(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  vm.isLoading ? 'Iniciando…' : 'Iniciar viaje',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.isLoading ? null : () => _onSoltar(vm, ride),
              child: Text(
                'Soltar viaje',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ),
          ]
          else ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        final rideId = vm.ride?.id;
                        await vm.completeRide();
                        if (!mounted) return;
                        if (vm.errorMessage == null) {
                          if (rideId != null) {
                            context.pushReplacement(
                              AppRoutes.rideEvaluation,
                              extra: rideId,
                            );
                          } else {
                            context.pop();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E8E5A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  vm.isLoading ? 'Completando…' : 'Completar viaje',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.isLoading ? null : () => _onSoltar(vm, ride),
              child: Text(
                'Cancelar viaje',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                vm.errorMessage!,
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
