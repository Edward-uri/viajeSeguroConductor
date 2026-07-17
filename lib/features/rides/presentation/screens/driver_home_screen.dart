import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../core/di/core_module.dart';
import '../../../../features/auth/di/auth_module.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/utils/svg_to_mapbox.dart';
import '../../../../shared/widgets/jala_map_view.dart';
import '../../../../theme/theme.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../provider/home_viewmodel.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  // ponytail: los viewmodels/servicios siguen en LatLng (latlong2); la
  // conversión a Point de Mapbox se hace solo aquí, en la frontera de la UI.
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointManager;
  CircleAnnotationManager? _zonasManager;
  PointAnnotation? _driverMarker;
  bool _pinLoaded = false;
  bool _socketInitialized = false;
  DateTime? _onlineSince;
  Timer? _onlineTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = ref.read(homeViewModelProvider);
      vm.loadData();

      final activo = await vm.getViajeActivoConductor();
      if (activo != null) {
        if (!mounted) return;
        context.push(AppRoutes.rideInProgress, extra: activo);
      }

      await vm.initLocation();
      _centerOnDriver();

      if (!_socketInitialized) {
        _socketInitialized = true;
        final storage = ref.read(authStorageProvider);
        final token = await storage.readAccessToken();
        if (token != null && token.isNotEmpty) {
          vm.initSocket(token: token);
        }

        try {
          final deviceReg = ref.read(deviceRegistrationServiceProvider);
          await deviceReg.registerCurrentDevice();
        } catch (_) {}
      }

      if (vm.isOnline) {
        _onlineSince = DateTime.now();
        _onlineTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  void dispose() {
    _onlineTimer?.cancel();
    super.dispose();
  }

  void _onOnlineChanged(bool isOnline) {
    if (isOnline) {
      _onlineSince = DateTime.now();
      _onlineTimer?.cancel();
      _onlineTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _onlineSince = null;
      _onlineTimer?.cancel();
      _onlineTimer = null;
    }
    if (mounted) setState(() {});
  }

  void _centerOnDriver() {
    final pos = ref.read(homeViewModelProvider).currentPosition;
    if (pos != null) {
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 16.0,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // El mapa puede recrearse (cambio de tema): el estilo nuevo no conserva
    // imágenes ni anotaciones anteriores.
    _driverMarker = null;
    _pinLoaded = false;
    try {
      _pointManager =
          await mapboxMap.annotations.createPointAnnotationManager();
    } catch (e) {
      debugPrint('[Home] PointAnnotation no disponible: $e');
    }
    try {
      _zonasManager =
          await mapboxMap.annotations.createCircleAnnotationManager();
    } catch (e) {
      debugPrint('[Home] CircleAnnotation no disponible: $e');
    }

    await addPngPinToMap(
      mapboxMap,
      'mototaxi-mapa',
      'lib/shared/icons/map-icons/MototaxiMapa.png',
      width: 40,
      height: 40,
    );
    _pinLoaded = true;

    final pos = ref.read(homeViewModelProvider).currentPosition;
    if (pos != null) {
      _updateDriverMarker(pos);
      _centerOnDriver();
    }
    _drawZonas();
  }

  void _updateDriverMarker(LatLng pos) async {
    final manager = _pointManager;
    if (manager == null || !_pinLoaded) return;
    final point = Point(coordinates: Position(pos.longitude, pos.latitude));
    try {
      if (_driverMarker == null) {
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
      debugPrint('[Home] Error actualizando marcador del conductor: $e');
    }
  }

  Future<void> _drawZonas() async {
    final manager = _zonasManager;
    if (manager == null) return;
    final vm = ref.read(homeViewModelProvider);
    try {
      await manager.deleteAll();
      if (vm.zonasCalientes.isEmpty) return;

      final zoom = (await _mapboxMap?.getCameraState())?.zoom ?? 14.0;
      final options = <CircleAnnotationOptions>[];
      for (var i = 0; i < vm.zonasCalientes.length; i++) {
        final z = vm.zonasCalientes[i];
        final base = vm.heatZoneColors[i];
        // metros → píxeles al zoom actual (Web Mercator).
        // ponytail: el radio no se re-escala al hacer zoom; si algún día
        // importa la fidelidad, migrar a una capa GeoJSON con radio en metros.
        final metersPerPixel =
            156543.03392 * math.cos(z.lat * math.pi / 180) / math.pow(2, zoom);
        options.add(CircleAnnotationOptions(
          geometry: Point(coordinates: Position(z.lng, z.lat)),
          circleColor: base.toARGB32(),
          circleRadius: z.radioM / metersPerPixel,
          circleOpacity: 0.18 + z.intensidad * 0.17,
          circleStrokeColor: base.toARGB32(),
          circleStrokeWidth: 2.0,
        ));
      }
      await manager.createMulti(options);
    } catch (e) {
      debugPrint('[Home] zonas calientes no disponibles en el mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    ref.listen<String?>(homeViewModelProvider.select((v) => v.errorMessage), (_, msg) {
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

    ref.listen<SolicitudViaje?>(
      homeViewModelProvider.select((v) => v.currentRequest),
      (_, request) {
        if (request != null && context.mounted) {
          context.push(AppRoutes.rideRequest);
        }
      },
    );

    ref.listen<bool>(
      homeViewModelProvider.select((v) => v.isOnline),
      (_, isOnline) => _onOnlineChanged(isOnline),
    );

    // El mapa ya no se reconstruye con el estado: marcador y zonas se
    // actualizan imperativamente sobre las anotaciones de Mapbox.
    ref.listen<LatLng?>(
      homeViewModelProvider.select((v) => v.currentPosition),
      (prev, pos) {
        if (pos == null) return;
        _updateDriverMarker(pos);
        if (prev == null) _centerOnDriver();
      },
    );

    ref.listen(
      homeViewModelProvider.select((v) => v.zonasCalientes),
      (_, _) => _drawZonas(),
    );

    final text = Theme.of(context).textTheme;

    final onlineElapsed = _onlineSince != null
        ? DateTime.now().difference(_onlineSince!)
        : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // El mototaxi del conductor se dibuja como anotación
                  // (pin PNG de map-icons), no como pin de "mi ubicación".
                  JalaMapView(
                    onMapCreated: _onMapCreated,
                    showCurrentLocationPin: false,
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      onPressed: _centerOnDriver,
                      backgroundColor: scheme.surfaceContainerHigh,
                      child: Icon(
                        Icons.my_location,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (isLandscape)
                    vm.esConductor
                        ? _LandscapeBottomBar(
                            stats: vm.stats,
                            pendientes: vm.pendientes,
                            onSelect: vm.seleccionarViaje,
                            isOnline: vm.isOnline,
                            onToggle: (_) => vm.toggleOnline(),
                            onlineElapsed: onlineElapsed,
                            text: text,
                            scheme: scheme,
                          )
                        : Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: () => context.push(AppRoutes.documents),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                color: scheme.surfaceContainerLow,
                                child: Text(
                                  'Completa tu registro de conductor para recibir viajes →',
                                  style: text.bodyMedium
                                      ?.copyWith(color: scheme.primary),
                                ),
                              ),
                            ),
                          ),
                ],
              ),
            ),
            if (!isLandscape)
              vm.esConductor
                  ? _BottomSheet(
                      pendientes: vm.pendientes,
                      onSelect: vm.seleccionarViaje,
                      isOnline: vm.isOnline,
                      onToggle: (_) => vm.toggleOnline(),
                      stats: vm.stats,
                      onlineElapsed: onlineElapsed,
                      text: text,
                      scheme: scheme,
                    )
                  : InkWell(
                      onTap: () => context.push(AppRoutes.documents),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        color: scheme.surfaceContainerLow,
                        child: Text(
                          'Completa tu registro de conductor para recibir viajes →',
                          style: text.bodyMedium?.copyWith(color: scheme.primary),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeBottomBar extends StatelessWidget {
  final DriverStats? stats;
  final List<SolicitudViaje> pendientes;
  final ValueChanged<SolicitudViaje> onSelect;
  final bool isOnline;
  final ValueChanged<bool> onToggle;
  final Duration? onlineElapsed;
  final TextTheme text;
  final ColorScheme scheme;

  const _LandscapeBottomBar({
    required this.stats,
    required this.pendientes,
    required this.onSelect,
    required this.isOnline,
    required this.onToggle,
    required this.onlineElapsed,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final hayPendientes = pendientes.isNotEmpty;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? JalaBrand.success : scheme.outline,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              isOnline ? 'En línea' : 'Offline',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 28,
              child: Switch(
                value: isOnline,
                onChanged: onToggle,
                activeTrackColor: JalaBrand.success.withValues(alpha: 0.4),
                activeThumbColor: JalaBrand.success,
              ),
            ),
            if (hayPendientes) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pendientes.length}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: GestureDetector(
                onTap: hayPendientes ? () => onSelect(pendientes.first) : null,
                child: Text(
                  hayPendientes ? 'Viaje solicitado' : 'Esperando viajes…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            if (stats != null) ...[
              Text(
                '\$${stats!.gananciasHoy.toStringAsFixed(0)}',
                style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final List<SolicitudViaje> pendientes;
  final ValueChanged<SolicitudViaje> onSelect;
  final bool isOnline;
  final ValueChanged<bool> onToggle;
  final DriverStats? stats;
  final Duration? onlineElapsed;
  final TextTheme text;
  final ColorScheme scheme;

  const _BottomSheet({
    required this.pendientes,
    required this.onSelect,
    required this.isOnline,
    required this.onToggle,
    required this.stats,
    required this.onlineElapsed,
    required this.text,
    required this.scheme,
  });

  String _resumen() {
    final s = stats!;
    final partes = [
      '\$${s.gananciasHoy.toStringAsFixed(0)} hoy',
      '${s.viajesHoy} viajes',
    ];
    if (onlineElapsed != null) {
      final h = onlineElapsed!.inHours;
      final m = onlineElapsed!.inMinutes.remainder(60);
      partes.add(h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m');
    } else {
      partes.add('${s.horasEnLinea} h');
    }
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? JalaBrand.success : scheme.outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Estás en línea' : 'Estás offline',
                      style: text.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (stats != null)
                      Text(
                        _resumen(),
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              Switch(
                value: isOnline,
                onChanged: onToggle,
                activeTrackColor: JalaBrand.success.withValues(alpha: 0.4),
                activeThumbColor: JalaBrand.success,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PendingTrips(
            pendientes: pendientes,
            onSelect: onSelect,
            text: text,
            scheme: scheme,
          ),
        ],
      ),
    );
  }
}

class _PendingTrips extends StatelessWidget {
  final List<SolicitudViaje> pendientes;
  final ValueChanged<SolicitudViaje> onSelect;
  final TextTheme text;
  final ColorScheme scheme;

  const _PendingTrips({
    required this.pendientes,
    required this.onSelect,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final hay = pendientes.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                hay ? 'Viajes para ti' : 'Viajes disponibles',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hay)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${pendientes.length}',
                    style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!hay)
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.radar, color: scheme.onSurfaceVariant, size: 24),
                  const SizedBox(height: 12),
                  Text('Buscando viajes cerca de ti',
                      style: text.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Mantente en línea, te avisaremos al instante.',
                      textAlign: TextAlign.center,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: pendientes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _TripCard(
                viaje: pendientes[i],
                onTap: () => onSelect(pendientes[i]),
                text: text,
                scheme: scheme,
              ),
            ),
          ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  final SolicitudViaje viaje;
  final VoidCallback onTap;
  final TextTheme text;
  final ColorScheme scheme;

  const _TripCard({
    required this.viaje,
    required this.onTap,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final nombre =
        viaje.nombreCompleto.isNotEmpty ? viaje.nombreCompleto : 'Pasajero';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      viaje.pasajeroIniciales.isNotEmpty
                          ? viaje.pasajeroIniciales
                          : '?',
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        if (viaje.pasajeroCalificacion > 0)
                          Row(
                            children: [
                              Icon(Icons.star_rounded,
                                  size: 14, color: scheme.tertiary),
                              const SizedBox(width: 2),
                              Text(
                                  viaje.pasajeroCalificacion
                                      .toStringAsFixed(1),
                                  style: text.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('\$${viaje.monto.toStringAsFixed(0)}',
                      style: text.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
              _RouteLine(
                origen: viaje.origen,
                destino: viaje.destino,
                scheme: scheme,
                text: text,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${viaje.distanciaKm.toStringAsFixed(1)} km · ${viaje.duracionMin} min · ${viaje.metodoPago}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Origen → destino con puntos y conector vertical, estilo apps de viaje.
class _RouteLine extends StatelessWidget {
  final String origen;
  final String destino;
  final ColorScheme scheme;
  final TextTheme text;

  const _RouteLine({
    required this.origen,
    required this.destino,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            Container(width: 2, height: 18, color: scheme.outlineVariant),
            Icon(Icons.location_on, size: 12, color: scheme.error),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origen.isNotEmpty ? origen : 'Punto de encuentro',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(destino.isNotEmpty ? destino : 'Destino',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
