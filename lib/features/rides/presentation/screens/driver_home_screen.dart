import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../../../core/di/core_module.dart';
import '../../../../features/auth/di/auth_module.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/utils/svg_to_mapbox.dart';
import '../../../../shared/widgets/jala_map_view.dart';
import '../../../../theme/theme.dart';
import '../../../heatmap/data/models/heat_zone.dart';
import '../../../heatmap/presentation/provider/heatmap_viewmodel.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../provider/driver_availability_viewmodel.dart';
import '../provider/ride_inbox_viewmodel.dart';

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
  PointAnnotation? _driverMarker;
  bool _pinLoaded = false;
  bool _socketInitialized = false;
  // Tema con el que se pintaron las celdas de demanda (para repintar al cambiar).
  bool? _zonasDark;
  DateTime? _onlineSince;
  Timer? _onlineTimer;

  // Tamaños del panel inferior arrastrable (fracción de la altura del cuerpo).
  static const _sheetMin = 0.16;
  static const _sheetInitial = 0.30;
  static const _sheetMax = 0.88;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final disponibilidad =
          ref.read(driverAvailabilityViewModelProvider.notifier);
      disponibilidad.loadData();

      // La ubicación NO debe esperar al socket ni al registro FCM: el mototaxi
      // debe aparecer en cuanto haya fix de GPS. Se resuelve concurrente; el
      // listener de currentPosition dibuja el marcador y centra la cámara.
      unawaited(disponibilidad.initLocation().then((_) {
        if (!mounted) return;
        final pos =
            ref.read(driverAvailabilityViewModelProvider).currentPosition;
        if (kDebugMode) debugPrint('[Home] initLocation resuelto pos=$pos');
        _centerOnDriver();
      }));

      // Socket y registro del dispositivo (FCM) van PRIMERO y protegidos:
      // no dependen del GPS y no deben morir por un permiso de ubicación en
      // disputa ni por un fallo de red del resto de la cadena.
      if (!_socketInitialized) {
        _socketInitialized = true;
        final storage = ref.read(authStorageProvider);
        final token = await storage.readAccessToken();
        if (!mounted) return;
        if (token != null && token.isNotEmpty) {
          ref.read(rideInboxViewModelProvider.notifier).initSocket(token: token);
        }

        try {
          final deviceReg = ref.read(deviceRegistrationServiceProvider);
          await deviceReg.registerCurrentDevice();
        } catch (_) {}
        if (!mounted) return;
      }

      try {
        final activo = await disponibilidad.getViajeActivoConductor();
        if (!mounted) return;
        if (activo != null) {
          context.push(AppRoutes.rideInProgress, extra: activo);
        }
      } catch (_) {
        // Sin red no hay viaje activo que restaurar; el home sigue vivo.
      }

      if (!mounted) return;
      if (ref.read(driverAvailabilityViewModelProvider).isOnline) {
        _onlineSince = DateTime.now();
        _onlineTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cambió el tema: repinta las celdas con la rampa del tema actual (el mapa
    // ya no se recrea al cambiar tema, así que hay que hacerlo a mano).
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_zonasDark != null && _zonasDark != isDark) {
      _repintarZonas();
    }
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
    final pos =
        ref.read(driverAvailabilityViewModelProvider).currentPosition;
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
      if (kDebugMode) debugPrint('[Home] PointAnnotation no disponible: $e');
    }

    // Sólo marcar el pin como cargado si de verdad quedó registrado en el
    // estilo; si no, la anotación apuntaría a una imagen inexistente.
    await _ensurePin();
    if (kDebugMode) debugPrint('[Home] mototaxi pin cargado=$_pinLoaded');

    final pos =
        ref.read(driverAvailabilityViewModelProvider).currentPosition;
    if (pos != null) {
      _updateDriverMarker(pos);
      _centerOnDriver();
    }
    _drawZonas();
  }

  /// Registra el PNG del mototaxi en el estilo actual. Idempotente: si ya está
  /// cargado no hace nada. Se reintenta desde _updateDriverMarker por si la
  /// primera carga cayó en una carrera con la carga del estilo del mapa.
  Future<void> _ensurePin() async {
    final map = _mapboxMap;
    if (_pinLoaded || map == null) return;
    _pinLoaded = await addPngPinToMap(
      map,
      'mototaxi-mapa',
      'lib/shared/icons/map-icons/MototaxiMapa.png',
      width: 40,
      height: 40,
    );
  }

  void _updateDriverMarker(LatLng pos) async {
    final manager = _pointManager;
    if (manager == null) return;
    // El PNG pudo no quedar registrado al crear el estilo (carrera con la carga
    // del estilo): reintentar aquí hace que el marcador aparezca en cuanto haya
    // posición, en vez de quedarse invisible hasta un rebuild.
    if (!_pinLoaded) await _ensurePin();
    if (!_pinLoaded) {
      if (kDebugMode) debugPrint('[Home] mototaxi NO dibujado (pin no cargó, pos=$pos)');
      return;
    }
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
      if (kDebugMode) debugPrint('[Home] Error actualizando marcador del conductor: $e');
    }
  }

  // Fuente y capa de las zonas de alta demanda (celdas cuadradas).
  static const _zonasSourceId = 'zonas-src';
  static const _zonasFillId = 'zonas-fill';

  /// Pinta las zonas como celdas cuadradas rellenas (rejilla tipo DiDi: verde
  /// por demanda, con borde), no círculos. Todas del mismo tamaño → se leen como
  /// mosaicos y nunca una queda dentro de otra. Crea fuente/capa la primera vez
  /// y luego solo actualiza los datos; al recrearse el mapa (cambio de tema) el
  /// estilo se reinicia y se vuelven a crear.
  Future<void> _drawZonas() async {
    final map = _mapboxMap;
    if (map == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final zonas = ref.read(heatmapViewModelProvider).zonas;

    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [for (final z in zonas) _celdaFeature(z)],
    });

    try {
      if (await map.style.styleSourceExists(_zonasSourceId)) {
        await map.style.setStyleSourceProperty(_zonasSourceId, 'data', geojson);
        return;
      }
      // Aún no hay fuente: si tampoco hay zonas, no creamos nada todavía.
      if (zonas.isEmpty) return;
      await map.style
          .addSource(GeoJsonSource(id: _zonasSourceId, data: geojson));
      await map.style.addLayer(FillLayer(
        id: _zonasFillId,
        sourceId: _zonasSourceId,
        fillColorExpression: _zonaColorExpr(isDark),
        // En oscuro casi opaco: los verdes translúcidos se lavaban contra el
        // mapa nocturno y no se veían.
        fillOpacity: isDark ? 0.85 : 0.55,
        fillOutlineColor: isDark ? 0xFFDBFF6E : 0xFF2E7D32,
      ));
      _zonasDark = isDark;
    } catch (e) {
      if (kDebugMode) debugPrint('[Home] zonas de demanda no disponibles: $e');
    }
  }

  /// Rampa de verde por intensidad adaptada al tema. En oscuro va de verde claro
  /// brillante a lima (brillante y casi opaco para que resalte sobre el mapa
  /// nocturno); en claro de verde pálido a profundo. Así se distinguen los
  /// niveles en ambos temas.
  List<Object> _zonaColorExpr(bool isDark) => isDark
      ? [
          'interpolate', ['linear'], ['get', 'intensidad'],
          0.0, 'rgb(124, 214, 124)',
          0.5, 'rgb(168, 235, 108)',
          1.0, 'rgb(205, 255, 90)',
        ]
      : [
          'interpolate', ['linear'], ['get', 'intensidad'],
          0.0, 'rgb(197, 225, 165)',
          0.5, 'rgb(102, 187, 106)',
          1.0, 'rgb(27, 94, 32)',
        ];

  /// Al cambiar el tema el mapa NO se recrea (fix del jank), así que las celdas
  /// conservarían los colores viejos: se quitan y se vuelven a pintar con la
  /// rampa del tema actual.
  Future<void> _repintarZonas() async {
    final map = _mapboxMap;
    if (map == null) return;
    try {
      if (await map.style.styleLayerExists(_zonasFillId)) {
        await map.style.removeStyleLayer(_zonasFillId);
      }
      if (await map.style.styleSourceExists(_zonasSourceId)) {
        await map.style.removeStyleSource(_zonasSourceId);
      }
    } catch (_) {}
    _drawZonas();
  }

  /// Celda cuadrada (~260 m de lado) centrada en la zona, como polígono GeoJSON.
  /// Deja una separación fina entre celdas para que se lean como mosaicos.
  Map<String, dynamic> _celdaFeature(HeatZone z) {
    const halfM = 130.0; // media celda en metros
    final dLat = halfM / 111320.0;
    final dLng = halfM / (111320.0 * math.cos(z.lat * math.pi / 180.0));
    final n = z.lat + dLat, s = z.lat - dLat;
    final e = z.lng + dLng, w = z.lng - dLng;
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [w, s],
            [e, s],
            [e, n],
            [w, n],
            [w, s],
          ],
        ],
      },
      'properties': {'intensidad': z.intensidad},
    };
  }

  /// Tap sobre el mapa: si cae dentro de una zona de alta demanda, muestra su
  /// tarjeta traducida (nivel de demanda, solicitudes, competencia de motos).
  void _onMapTap(MapContentGestureContext gesture) {
    final zonas = ref.read(heatmapViewModelProvider).zonas;
    if (zonas.isEmpty) return;
    final lat = gesture.point.coordinates.lat.toDouble();
    final lng = gesture.point.coordinates.lng.toDouble();

    HeatZone? elegida;
    var mejor = double.infinity;
    for (final z in zonas) {
      final d = Geolocator.distanceBetween(lat, lng, z.lat, z.lng);
      // Margen generoso (mínimo 300 m) para que sea fácil de atinar con el dedo.
      final tol = (z.radioM * 1.4).clamp(300.0, 1000.0);
      if (d <= tol && d < mejor) {
        mejor = d;
        elegida = z;
      }
    }
    if (elegida != null) _mostrarTarjetaZona(elegida);
  }

  void _mostrarTarjetaZona(HeatZone z) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _colorNivel(z.intensidad),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Zona de demanda ${_nivelDemanda(z.intensidad)}',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _consejoZona(z.intensidad),
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // La intensidad (0..1) rankea las zonas entre sí.
  String _nivelDemanda(double i) =>
      i >= 0.66 ? 'alta' : (i >= 0.33 ? 'media' : 'baja');

  Color _colorNivel(double i) => i >= 0.66
      ? const Color(0xFF1B5E20)
      : (i >= 0.33 ? const Color(0xFF66BB6A) : const Color(0xFFC5E1A5));

  // Datos sintéticos por ahora: nada de cifras exactas (no significan nada
  // real todavía); solo lenguaje simple que se entienda de un vistazo.
  String _consejoZona(double i) {
    if (i >= 0.66) {
      return 'Aquí se están pidiendo más viajes de lo normal. Buen momento para acercarte.';
    }
    if (i >= 0.33) {
      return 'Hay buena actividad de viajes por esta zona.';
    }
    return 'Actividad de viajes moderada por aquí.';
  }

  void _mostrarError(String? msg) {
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibilidad = ref.watch(driverAvailabilityViewModelProvider);
    final inbox = ref.watch(rideInboxViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Los errores llegan de dos fuentes: disponibilidad (toggle/GPS/carga) y
    // bandeja de solicitudes (aceptar/rechazar/socket). Mismo snackbar.
    // Tras mostrarlo se limpia el mensaje: este listener sólo dispara con
    // CAMBIOS, así que sin limpiar, dos errores idénticos seguidos no
    // mostrarían nada la segunda vez.
    ref.listen<String?>(
      driverAvailabilityViewModelProvider.select((s) => s.errorMessage),
      (_, msg) {
        if (msg == null) return;
        _mostrarError(msg);
        ref.read(driverAvailabilityViewModelProvider.notifier).clearError();
      },
    );
    ref.listen<String?>(
      rideInboxViewModelProvider.select((s) => s.errorMessage),
      (_, msg) {
        if (msg == null) return;
        _mostrarError(msg);
        ref.read(rideInboxViewModelProvider.notifier).clearError();
      },
    );

    ref.listen<SolicitudViaje?>(
      rideInboxViewModelProvider.select((s) => s.currentRequest),
      (_, request) {
        if (request != null && context.mounted) {
          context.push(AppRoutes.rideRequest);
        }
      },
    );

    ref.listen<bool>(
      driverAvailabilityViewModelProvider.select((s) => s.isOnline),
      (_, isOnline) => _onOnlineChanged(isOnline),
    );

    // El mapa ya no se reconstruye con el estado: marcador y zonas se
    // actualizan imperativamente sobre las anotaciones de Mapbox.
    ref.listen<LatLng?>(
      driverAvailabilityViewModelProvider.select((s) => s.currentPosition),
      (prev, pos) {
        if (pos == null) return;
        _updateDriverMarker(pos);
        if (prev == null) _centerOnDriver();
      },
    );

    ref.listen(
      heatmapViewModelProvider.select((s) => s.zonas),
      (_, _) => _drawZonas(),
    );

    final text = Theme.of(context).textTheme;

    final onlineElapsed = _onlineSince != null
        ? DateTime.now().difference(_onlineSince!)
        : null;
    final hayZonas =
        ref.watch(heatmapViewModelProvider.select((s) => s.zonas.isNotEmpty));

    return Scaffold(
      body: Stack(
        children: [
          // Mapa a pantalla completa; el panel inferior se arrastra encima.
          Positioned.fill(
            child: JalaMapView(
              onMapCreated: _onMapCreated,
              showCurrentLocationPin: false,
              // La posición la resuelve el viewmodel de disponibilidad
              // (initLocation + listener de currentPosition centra la cámara);
              // autoLocate aquí duplicaría la petición de permiso y en iOS
              // revienta con PermissionRequestInProgress.
              autoLocate: false,
              onTap: _onMapTap,
            ),
          ),
          // Recentrar, por encima del panel colapsado.
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * _sheetInitial + 8,
            child: FloatingActionButton.small(
              onPressed: _centerOnDriver,
              backgroundColor: scheme.surfaceContainerHigh,
              child: Icon(Icons.my_location, color: scheme.onSurface),
            ),
          ),
          // Simbología: qué significan los colores de las celdas de demanda.
          if (hayZonas)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 12,
              child: _ZonaLegend(
                isDark: Theme.of(context).brightness == Brightness.dark,
                scheme: scheme,
                text: text,
              ),
            ),
          // Panel inferior: banner de registro, barra horizontal, o el sheet
          // arrastrable (retrato) para mostrar/ocultar el mapa.
          if (!disponibilidad.esConductor)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: () => context.push(AppRoutes.documents),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: scheme.surfaceContainerLow,
                  child: Text(
                    'Completa tu registro de conductor para recibir viajes →',
                    style: text.bodyMedium?.copyWith(color: scheme.primary),
                  ),
                ),
              ),
            )
          else if (isLandscape)
            _LandscapeBottomBar(
              stats: disponibilidad.stats,
              pendientes: inbox.pendientes,
              onSelect:
                  ref.read(rideInboxViewModelProvider.notifier).seleccionarViaje,
              isOnline: disponibilidad.isOnline,
              onToggle: (_) => ref
                  .read(driverAvailabilityViewModelProvider.notifier)
                  .toggleOnline(),
              onlineElapsed: onlineElapsed,
              text: text,
              scheme: scheme,
            )
          else
            DraggableScrollableSheet(
              initialChildSize: _sheetInitial,
              minChildSize: _sheetMin,
              maxChildSize: _sheetMax,
              builder: (context, scrollController) => _BottomSheet(
                scrollController: scrollController,
                pendientes: inbox.pendientes,
                onSelect: ref
                    .read(rideInboxViewModelProvider.notifier)
                    .seleccionarViaje,
                isOnline: disponibilidad.isOnline,
                onToggle: (_) => ref
                    .read(driverAvailabilityViewModelProvider.notifier)
                    .toggleOnline(),
                stats: disponibilidad.stats,
                onlineElapsed: onlineElapsed,
                text: text,
                scheme: scheme,
              ),
            ),
        ],
      ),
    );
  }
}

/// Simbología del mapa: qué significa cada color de las celdas de demanda.
class _ZonaLegend extends StatelessWidget {
  const _ZonaLegend({
    required this.isDark,
    required this.scheme,
    required this.text,
  });

  final bool isDark;
  final ColorScheme scheme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final colores = isDark
        ? const [Color(0xFF7CD67C), Color(0xFFA8EB6C), Color(0xFFCDFF5A)]
        : const [Color(0xFFC5E1A5), Color(0xFF66BB6A), Color(0xFF1B5E20)];
    const labels = ['Poca', 'Media', 'Mucha'];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demanda',
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colores[i],
                      borderRadius: BorderRadius.circular(3),
                      border:
                          Border.all(color: scheme.outlineVariant, width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labels[i],
                    style: text.bodySmall?.copyWith(color: scheme.onSurface),
                  ),
                ],
              ),
            ),
        ],
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
              isOnline ? 'En línea' : 'Desconectado',
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
                  hayPendientes
                      ? 'Viaje solicitado'
                      : (isOnline ? 'Esperando viajes…' : 'Desconectado'),
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
  final ScrollController scrollController;
  final List<SolicitudViaje> pendientes;
  final ValueChanged<SolicitudViaje> onSelect;
  final bool isOnline;
  final ValueChanged<bool> onToggle;
  final DriverStats? stats;
  final Duration? onlineElapsed;
  final TextTheme text;
  final ColorScheme scheme;

  const _BottomSheet({
    required this.scrollController,
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
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      // El sheet arrastrable provee el scrollController: la lista y el arrastre
      // comparten el mismo scroll (subir el panel = mostrar/ocultar el mapa).
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                      isOnline ? 'Estás en línea' : 'Estás desconectado',
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
          const SizedBox(height: 8),
          _PendingTrips(
            pendientes: pendientes,
            onSelect: onSelect,
            isOnline: isOnline,
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
  final bool isOnline;
  final TextTheme text;
  final ColorScheme scheme;

  const _PendingTrips({
    required this.pendientes,
    required this.onSelect,
    required this.isOnline,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    // Sin pendientes: radar "buscando" solo si estás en línea; si no, invita a
    // conectarse (nunca "buscando viajes" estando desconectado).
    if (pendientes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: isOnline
              ? Column(
                  children: [
                    _RadarPulse(color: JalaBrand.success),
                    const SizedBox(height: 18),
                    Text('Buscando viajes cerca de ti',
                        style: text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Te avisaremos al instante.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                )
              : Column(
                  children: [
                    Icon(Icons.wifi_tethering_off_rounded,
                        size: 40, color: scheme.onSurfaceVariant),
                    const SizedBox(height: 14),
                    Text('Estás desconectado',
                        style: text.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Ponte en línea para recibir viajes.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
        ),
      );
    }

    // El sheet ya es scrollable: las tarjetas van como columna, no en otra lista.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Viajes para ti',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
        for (var i = 0; i < pendientes.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _TripCard(
            viaje: pendientes[i],
            onTap: () => onSelect(pendientes[i]),
            text: text,
            scheme: scheme,
          ),
        ],
      ],
    );
  }
}

/// Pulso tipo radar/escáner: anillos que se expanden y desvanecen. Se muestra
/// cuando el conductor está en línea esperando viajes.
class _RadarPulse extends StatefulWidget {
  const _RadarPulse({required this.color});

  final Color color;

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _RadarPainter(_c.value, widget.color),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width / 2;
    // Tres anillos desfasados que crecen y se desvanecen.
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (1 - p) * 0.6);
      canvas.drawCircle(center, maxR * p, paint);
    }
    // Punto central sólido.
    canvas.drawCircle(center, 5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.color != color;
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
