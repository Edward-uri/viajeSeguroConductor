import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../theme/jala_theme.dart';

/// Pin para seleccionar ubicación en el mapa (mismos PNG de map-icons que
/// los pines dibujados sobre el mapa).
class JalaPinMarker extends StatelessWidget {
  const JalaPinMarker({
    super.key,
    this.asset = 'lib/shared/icons/map-icons/Pin-Naranja.png',
    this.width = 30,
    this.height = 36,
  });

  final String asset;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        // Deja la punta del pin en el centro exacto del mapa.
        padding: EdgeInsets.only(bottom: height),
        child: Image.asset(asset, width: width, height: height),
      ),
    );
  }
}

class JalaLocationMarker extends StatelessWidget {
  const JalaLocationMarker({
    super.key,
    this.outerSize = 64,
    this.innerSize = 18,
    this.markerColor = const Color(0xFFFF8F00),
  });

  final double outerSize;
  final double innerSize;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          color: markerColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Colors.white, width: 3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JalaMapView extends StatefulWidget {
  const JalaMapView({
    super.key,
    required this.onMapCreated,
    this.initialLatitude,
    this.initialLongitude,
    this.initialZoom = 2.0,
    this.showLocationMarker = false,
    this.showPinMarker = false,
    this.pinMarkerAsset = 'lib/shared/icons/map-icons/Pin-Naranja.png',
    this.showCurrentLocationPin = true,
    this.onMapIdle,
    this.onCameraChanged,
    this.onTap,
    this.autoLocate = true,
    this.styleUri,
  });

  final void Function(MapboxMap) onMapCreated;
  final double? initialLatitude;
  final double? initialLongitude;
  final double initialZoom;
  final bool showLocationMarker;
  final bool showPinMarker;
  final String pinMarkerAsset;
  final bool showCurrentLocationPin;
  final void Function(CameraChangedEventData)? onCameraChanged;
  final void Function(MapIdleEventData)? onMapIdle;

  /// Tap sobre el mapa (coordenada geográfica en `context.point`).
  final OnMapTapListener? onTap;
  final bool autoLocate;
  final String? styleUri;

  @override
  State<JalaMapView> createState() => _JalaMapViewState();
}

class _JalaMapViewState extends State<JalaMapView>
    with WidgetsBindingObserver {
  MapboxMap? _mapboxMap;
  CircleAnnotationManager? _circleManager;
  geo.Position? _currentPosition;
  bool _located = false;
  // Ambiente día/noche ya aplicado (evita re-aplicarlo en cada rebuild).
  Brightness? _appliedBrightness;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.autoLocate &&
        widget.initialLatitude == null &&
        widget.initialLongitude == null) {
      _resolveCurrentLocation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cambió el tema de la app: ajusta el ambiente del mapa SIN recrear el
    // MapWidget. Antes el mapa estaba keyed por brillo y cambiar tema destruía
    // y recreaba el mapa nativo de Mapbox = jank agresivo.
    final b = Theme.of(context).brightness;
    if (_mapboxMap != null && b != _appliedBrightness) {
      _applyLightPreset(b);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Ajusta el preset de luz del estilo Standard (día/noche) según el tema, sin
  /// recargar el estilo ni recrear el mapa (reemplaza el switch de styleUri por
  /// brillo, que obligaba a recrear el MapWidget).
  Future<void> _applyLightPreset(Brightness b) async {
    final map = _mapboxMap;
    if (map == null) return;
    _appliedBrightness = b;
    try {
      await map.style.setStyleImportConfigProperty(
          'basemap', 'lightPreset', b == Brightness.dark ? 'night' : 'day');
    } catch (_) {
      // Estilos que no son Standard no tienen 'basemap'; se ignora.
    }
  }

  void _onStyleLoaded(StyleLoadedEventData _) {
    if (mounted) _applyLightPreset(Theme.of(context).brightness);
  }

  /// When the app comes back from background the native GL surface may have
  /// been destroyed by Android.  A zero-duration flyTo with the last known
  /// position forces the Mapbox renderer to re-acquire the surface.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _mapboxMap != null) {
      final pos = _currentPosition;
      if (pos != null) {
        try {
          _mapboxMap!.flyTo(
            CameraOptions(
              center: Point(
                coordinates: Position(pos.longitude, pos.latitude),
              ),
              zoom: 16.0,
            ),
            MapAnimationOptions(duration: 0, startDelay: 0),
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _resolveCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      final lastKnown = await geo.Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() => _currentPosition = lastKnown);
        _flyToCurrent(lastKnown.latitude, lastKnown.longitude);
        _tryAddCurrentLocationPin();
      }

      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() => _currentPosition = position);
      _flyToCurrent(position.latitude, position.longitude);
      _tryAddCurrentLocationPin();
    } catch (e) {
      if (kDebugMode) debugPrint('[JalaMapView] Error obteniendo ubicacion: $e');
    }
  }

  void _flyToCurrent(double latitude, double longitude) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(longitude, latitude)),
        zoom: 16.0,
      ),
      MapAnimationOptions(duration: 1000, startDelay: 0),
    );
  }

  Future<void> _tryAddCurrentLocationPin() async {
    if (!widget.showCurrentLocationPin) return;
    if (_mapboxMap == null || _currentPosition == null) return;

    try {
      _circleManager ??=
          await _mapboxMap!.annotations.createCircleAnnotationManager();
      _circleManager!.deleteAll();

      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      final amber = JalaBrand.amber.toARGB32();

      await _circleManager!.createMulti([
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleColor: amber,
          circleRadius: 22.0,
          circleOpacity: 0.18,
          circleStrokeWidth: 0,
        ),
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          circleColor: amber,
          circleRadius: 10.0,
          circleOpacity: 0.9,
          circleStrokeColor: Colors.white.toARGB32(),
          circleStrokeWidth: 3.0,
        ),
      ]);
    } catch (e) {
      if (kDebugMode) debugPrint('[JalaMapView] CircleAnnotation no disponible: $e');
      _circleManager = null;
    }
  }

  void _handleMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _hideMapOrnaments(mapboxMap);
    _applyLightPreset(Theme.of(context).brightness);
    if (!_located && _currentPosition != null) {
      _located = true;
      _flyToCurrent(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    _tryAddCurrentLocationPin();
    widget.onMapCreated(mapboxMap);
  }

  void _hideMapOrnaments(MapboxMap mapboxMap) {
    try {
      mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    } catch (_) {}
    try {
      mapboxMap.attribution.updateSettings(AttributionSettings(enabled: false));
    } catch (_) {}
    try {
      mapboxMap.logo.updateSettings(LogoSettings(enabled: false));
    } catch (_) {}
    try {
      mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.initialLatitude ?? _currentPosition?.latitude;
    final lng = widget.initialLongitude ?? _currentPosition?.longitude;
    final hasPosition = lat != null && lng != null;
    // Un único estilo estable (Standard) para claro y oscuro: el ambiente
    // día/noche se cambia con lightPreset (_applyLightPreset) sin recrear el
    // mapa. Por eso la key ya NO depende del brillo (evita el jank al cambiar
    // tema, sobre todo con el Home vivo en el IndexedStack del shell).
    final mapStyle = widget.styleUri ?? MapboxStyles.STANDARD;

    return Stack(
      children: [
        Positioned.fill(
          child: MapWidget(
            key: const ValueKey('jalaMapWidget'),
            // Igual que en la app pasajero (mapbox 2.25); en 2.26 se prefiere
            // `viewport`, pero cameraOptions sigue funcionando.
            // ignore: deprecated_member_use
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  lng ?? 0,
                  lat ?? 0,
                ),
              ),
              zoom: hasPosition ? 16.0 : widget.initialZoom,
            ),
            styleUri: mapStyle,
            onMapCreated: _handleMapCreated,
            onStyleLoadedListener: _onStyleLoaded,
            onCameraChangeListener: widget.onCameraChanged,
            onMapIdleListener: widget.onMapIdle,
            // onTapListener sigue funcionando en 2.25; addInteraction es de 2.26.
            // ignore: deprecated_member_use
            onTapListener: widget.onTap,
          ),
        ),
        if (widget.showLocationMarker)
          Positioned.fill(
            child: IgnorePointer(
              child: JalaLocationMarker(),
            ),
          ),
        if (widget.showPinMarker)
          Positioned.fill(
            child: IgnorePointer(
              child: JalaPinMarker(asset: widget.pinMarkerAsset),
            ),
          ),
      ],
    );
  }
}
