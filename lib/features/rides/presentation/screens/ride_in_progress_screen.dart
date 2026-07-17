import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:url_launcher/url_launcher.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/utils/svg_to_mapbox.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/jala_map_view.dart';
import '../../../../theme/theme.dart';
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
  // ponytail: los viewmodels/servicios siguen en LatLng (latlong2); la
  // conversión a Point de Mapbox se hace solo aquí, en la frontera de la UI.
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  PointAnnotationManager? _driverMarkerManager;
  PointAnnotation? _driverMarker;
  PointAnnotationManager? _pinMarkerManager;
  CircleAnnotationManager? _pasajeroManager;
  PolylineAnnotation? _routeLine;
  bool _pinImagesLoaded = false;

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

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // El mapa puede recrearse (cambio de tema): el estilo nuevo no conserva
    // imágenes ni anotaciones anteriores.
    _pinImagesLoaded = false;
    _routeLine = null;
    _driverMarker = null;
    try {
      _polylineManager =
          await mapboxMap.annotations.createPolylineAnnotationManager();
    } catch (e) {
      debugPrint('[RideInProgress] PolylineAnnotation no disponible: $e');
    }
    try {
      _driverMarkerManager =
          await mapboxMap.annotations.createPointAnnotationManager();
    } catch (e) {
      debugPrint('[RideInProgress] DriverMarkerManager no disponible: $e');
    }
    try {
      _pinMarkerManager =
          await mapboxMap.annotations.createPointAnnotationManager();
    } catch (e) {
      debugPrint('[RideInProgress] PinMarkerManager no disponible: $e');
    }
    try {
      _pasajeroManager =
          await mapboxMap.annotations.createCircleAnnotationManager();
    } catch (e) {
      debugPrint('[RideInProgress] CircleAnnotation no disponible: $e');
    }

    await _loadPinImages();

    // Dibujar de inmediato lo que ya conozca el viewmodel.
    final vm = ref.read(rideProgressViewModelProvider);
    _drawOriginDestinationPins();
    _drawRoute(vm.routePoints);
    if (vm.currentPosition != null) {
      _updateDriverMarker(vm.currentPosition!);
      _followDriver(vm.currentPosition!);
    }
    if (vm.pasajeroPosition != null) _updatePasajeroMarker(vm.pasajeroPosition!);
  }

  Future<void> _loadPinImages() async {
    final map = _mapboxMap;
    if (_pinImagesLoaded || map == null) return;
    try {
      await addPngPinToMap(
        map,
        'pin-verde',
        'lib/shared/icons/map-icons/Pin-Verde.png',
        width: 30,
        height: 36,
      );
      await addPngPinToMap(
        map,
        'pin-naranja',
        'lib/shared/icons/map-icons/Pin-Naranja.png',
        width: 30,
        height: 36,
      );
      await addPngPinToMap(
        map,
        'mototaxi-mapa',
        'lib/shared/icons/map-icons/MototaxiMapa.png',
        width: 40,
        height: 40,
      );
      _pinImagesLoaded = true;
    } catch (e) {
      debugPrint('[RideInProgress] Error cargando pines PNG: $e');
    }
  }

  void _drawOriginDestinationPins() {
    final ride = ref.read(rideProgressViewModelProvider).ride;
    final manager = _pinMarkerManager;
    if (ride == null || manager == null || !_pinImagesLoaded) return;
    try {
      manager.deleteAll();
      if (ride.origenLat != null && ride.origenLng != null) {
        manager.create(PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(ride.origenLng!, ride.origenLat!),
          ),
          iconImage: 'pin-verde',
          iconSize: 1.0,
        ));
      }
      if (ride.destinoLat != null && ride.destinoLng != null) {
        manager.create(PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(ride.destinoLng!, ride.destinoLat!),
          ),
          iconImage: 'pin-naranja',
          iconSize: 1.0,
        ));
      }
    } catch (e) {
      debugPrint('[RideInProgress] Error dibujando pines: $e');
    }
  }

  void _updateDriverMarker(LatLng pos) async {
    final manager = _driverMarkerManager;
    // Si el icono aún no está cargado, el siguiente tick de posición lo dibuja.
    if (manager == null || !_pinImagesLoaded) return;
    final point = Point(coordinates: Position(pos.longitude, pos.latitude));
    try {
      if (_driverMarker == null) {
        // Mototaxi del conductor (mismo icono de map-icons que la app pasajero).
        _driverMarker = await manager.create(PointAnnotationOptions(
          geometry: point,
          iconImage: 'mototaxi-mapa',
          iconSize: 1.0,
        ));
      } else {
        // Mover el marcador existente (no recrear: evita parpadeo).
        _driverMarker!.geometry = point;
        await manager.update(_driverMarker!);
      }
    } catch (e) {
      debugPrint('[RideInProgress] Error actualizando marcador: $e');
    }
  }

  /// Punto ámbar con borde blanco (mismo estilo de "ubicación" del pasajero).
  void _updatePasajeroMarker(LatLng pos) async {
    final manager = _pasajeroManager;
    if (manager == null) return;
    try {
      await manager.deleteAll();
      await manager.create(CircleAnnotationOptions(
        geometry: Point(coordinates: Position(pos.longitude, pos.latitude)),
        circleColor: JalaBrand.amber.toARGB32(),
        circleRadius: 10.0,
        circleOpacity: 0.9,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3.0,
      ));
    } catch (e) {
      debugPrint('[RideInProgress] Error con marcador del pasajero: $e');
    }
  }

  void _drawRoute(List<LatLng> points) async {
    final manager = _polylineManager;
    if (manager == null || points.length < 2) return;
    final coords =
        points.map((p) => Position(p.longitude, p.latitude)).toList();
    try {
      if (_routeLine == null) {
        _routeLine = await manager.create(PolylineAnnotationOptions(
          geometry: LineString(coordinates: coords),
          lineColor: JalaBrand.amber.toARGB32(),
          lineWidth: 5.0,
          lineOpacity: 0.9,
        ));
      } else {
        _routeLine!.geometry = LineString(coordinates: coords);
        await manager.update(_routeLine!);
      }
    } catch (e) {
      debugPrint('[RideInProgress] No se pudo dibujar la ruta: $e');
    }
  }

  void _followDriver(LatLng pos) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(pos.longitude, pos.latitude)),
      ),
      MapAnimationOptions(duration: 800, startDelay: 0),
    );
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

    // La cámara sigue al conductor conforme avanza; el marcador se actualiza
    // imperativamente (el mapa ya no se reconstruye con el estado).
    ref.listen<LatLng?>(
      rideProgressViewModelProvider.select((v) => v.currentPosition),
      (_, pos) {
        if (pos == null) return;
        _updateDriverMarker(pos);
        _followDriver(pos);
      },
    );

    ref.listen<LatLng?>(
      rideProgressViewModelProvider.select((v) => v.pasajeroPosition),
      (_, pos) {
        if (pos != null) _updatePasajeroMarker(pos);
      },
    );

    ref.listen<List<LatLng>>(
      rideProgressViewModelProvider.select((v) => v.routePoints),
      (_, points) => _drawRoute(points),
    );

    // El detalle enriquecido puede traer coordenadas que el listado no tenía.
    ref.listen<SolicitudViaje?>(
      rideProgressViewModelProvider.select((v) => v.ride),
      (_, _) => _drawOriginDestinationPins(),
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

  /// "8 min · 2.1 km" con datos de la ruta; cae a la distancia base si aún no llega la ruta.
  String? _avanceTexto(RideProgressViewModel vm) {
    if (vm.etaMin != null && vm.remainingKm != null) {
      final km = vm.remainingKm!.toStringAsFixed(1);
      final destino = vm.hasStarted ? 'al destino' : 'para llegar';
      return '${vm.etaMin} min · $km km $destino';
    }
    if (!vm.hasStarted) {
      final r = vm.ride;
      if (r != null && r.origenDistancia.isNotEmpty) {
        return '${r.origenDistancia} para llegar';
      }
    }
    return null;
  }

  Widget _buildHeader(RideProgressViewModel vm, SolicitudViaje ride, ColorScheme scheme) {
    final text = Theme.of(context).textTheme;
    final activo = vm.hasStarted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: activo ? JalaBrand.success : scheme.surface,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _onBackTap(vm),
            child: Icon(
              Icons.arrow_back,
              color: activo ? Colors.white : scheme.onSurface,
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                activo ? 'Viaje en curso' : 'Llegada al origen',
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: activo ? Colors.white : scheme.onSurface,
                ),
              ),
              if (_avanceTexto(vm) != null)
                Text(
                  _avanceTexto(vm)!,
                  style: text.bodySmall?.copyWith(
                    color: activo ? Colors.white70 : scheme.onSurfaceVariant,
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
    final initial = vm.currentPosition ??
        LatLng(ride.origenLat ?? 19.4326, ride.origenLng ?? -99.1332);
    return JalaMapView(
      onMapCreated: _onMapCreated,
      initialLatitude: initial.latitude,
      initialLongitude: initial.longitude,
      autoLocate: false,
      showCurrentLocationPin: false,
    );
  }

  Future<void> _llamarPasajero(String telefono) async {
    final uri = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el teléfono')),
      );
    }
  }

  Widget _buildBottomSheet(RideProgressViewModel vm, SolicitudViaje ride, ColorScheme scheme) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: AuthedImage(
              path: ride.pasajeroFotoUrl,
              size: 48,
              fallback: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                color: scheme.primaryContainer,
                child: Text(
                  ride.pasajeroIniciales.isNotEmpty ? ride.pasajeroIniciales : '?',
                  style: text.titleMedium
                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ride.pasajeroNombre.isNotEmpty ? ride.pasajeroNombre : 'Pasajero',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (ride.pasajeroTelefono != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _llamarPasajero(ride.pasajeroTelefono!),
              icon: const Icon(Icons.phone, size: 18),
              label: const Text('Llamar al pasajero'),
              style: OutlinedButton.styleFrom(foregroundColor: scheme.primary),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${ride.origen} → ${ride.destino}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
                  style: text.titleMedium
                      ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.isLoading ? null : () => _onSoltar(vm, ride),
              child: Text(
                'Soltar viaje',
                style: text.labelLarge
                    ?.copyWith(color: scheme.error, fontWeight: FontWeight.w600),
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
                  backgroundColor: JalaBrand.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  vm.isLoading ? 'Completando…' : 'Completar viaje',
                  style: text.titleMedium
                      ?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: vm.isLoading ? null : () => _onSoltar(vm, ride),
              child: Text(
                'Cancelar viaje',
                style: text.labelLarge
                    ?.copyWith(color: scheme.error, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                vm.errorMessage!,
                style: text.bodySmall?.copyWith(color: scheme.error),
              ),
            ),
        ],
      ),
    );
  }
}
