import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/env/api_config.dart';
import '../../../../features/auth/di/auth_module.dart';
import '../../../../features/documents/di/documents_module.dart';
import '../../../../features/documents/presentation/utils/document_route_helper.dart';
import '../../../../features/heatmap/data/models/heat_zone.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../provider/home_viewmodel.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final _mapController = MapController();
  final _heatHitNotifier = LayerHitNotifier<HeatZone>(null);
  bool _socketInitialized = false;
  bool _heatListenerSet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(documentoRepositoryProvider);
      final route = await resolveDocumentsRoute(repo);
      if (route != AppRoutes.driverHome) {
        if (!context.mounted) return;
        context.go(route);
        return;
      }
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

      if (!_heatListenerSet) {
        _heatListenerSet = true;
        _heatHitNotifier.addListener(_onHeatZoneTap);
      }
    });
  }

  @override
  void dispose() {
    _heatHitNotifier.removeListener(_onHeatZoneTap);
    super.dispose();
  }

  void _centerOnDriver() {
    final pos = ref.read(homeViewModelProvider).currentPosition;
    if (pos != null) {
      _mapController.move(pos, 15.0);
    }
  }

  // Naranja (baja) → rojo (alta intensidad).
  Color _zonaColor(double intensidad) =>
      Color.lerp(const Color(0xFFFFA000), const Color(0xFFD32F2F), intensidad)!;

  void _onHeatZoneTap() {
    final hit = _heatHitNotifier.value;
    if (hit != null && hit.hitValues.isNotEmpty && context.mounted) {
      _showZoneDetails(hit.hitValues.first);
    }
  }

  void _showZoneDetails(HeatZone zone) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Zona caliente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ZoneDetailRow(
                  label: 'Densidad de demanda',
                  value: zone.demandDensity.toStringAsFixed(2),
                ),
                const SizedBox(height: 8),
                _ZoneDetailRow(
                  label: 'Relación oferta/demanda',
                  value: zone.supplyDemandRatio.toStringAsFixed(3),
                ),
                const SizedBox(height: 8),
                _ZoneDetailRow(
                  label: 'Solicitudes',
                  value: '${zone.nRequests}',
                ),
                const SizedBox(height: 8),
                _ZoneDetailRow(
                  label: 'Intensidad',
                  value: '${(zone.intensidad * 100).toStringAsFixed(0)}%',
                ),
                const SizedBox(height: 8),
                _ZoneDetailRow(
                  label: 'Radio',
                  value: '${zone.radioM.toStringAsFixed(0)} m',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen<String?>(homeViewModelProvider.select((v) => v.errorMessage), (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red.shade700,
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

    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (vm.stats != null)
              _EarningsCard(stats: vm.stats!, text: text, scheme: scheme),
            _OnlineStatusBar(
              isOnline: vm.isOnline,
              onToggle: (_) => vm.toggleOnline(),
              text: text,
              scheme: scheme,
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: vm.currentPosition ?? const LatLng(19.4326, -99.1332),
                      initialZoom: 14.0,
                      onTap: (_, _) {},
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: ApiConfig.mapboxTilesUrlFor(
                            Theme.of(context).brightness),
                        userAgentPackageName: 'com.uriel.viajeseguroapp',
                      ),
                      if (vm.currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: vm.currentPosition!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E8E5A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
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
                          ],
                        ),
                      if (vm.zonasCalientes.isNotEmpty) ...[
                        CircleLayer(
                          circles: vm.zonasCalientes.map((z) {
                            final base = _zonaColor(z.intensidad);
                            return CircleMarker(
                              point: LatLng(z.lat, z.lng),
                              radius: z.radioM,
                              useRadiusInMeter: true,
                              color: base.withValues(
                                  alpha: 0.18 + z.intensidad * 0.17),
                              borderColor: base,
                              borderStrokeWidth: 2.5,
                              hitValue: z,
                            );
                          }).toList(),
                          hitNotifier: _heatHitNotifier,
                        ),
                        MarkerLayer(
                          markers: vm.zonasCalientes
                              .map((z) => Marker(
                                    point: LatLng(z.lat, z.lng),
                                    width: 56,
                                    height: 56,
                                    child: _ZonaBadge(
                                      intensidad: z.intensidad,
                                      color: _zonaColor(z.intensidad),
                                      onTap: () => _showZoneDetails(z),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  if (vm.isLoadingZonas)
                    const Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Cargando zonas calientes…'),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                ],
              ),
            ),
            _BottomSheet(
              stats: vm.stats,
              pendientes: vm.pendientes,
              onSelect: vm.seleccionarViaje,
              text: text,
              scheme: scheme,
              onGanancias: () => context.push(AppRoutes.earnings),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final DriverStats stats;
  final TextTheme text;
  final ColorScheme scheme;

  const _EarningsCard({
    required this.stats,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: scheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${stats.gananciasHoy.toStringAsFixed(2)} hoy',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ganancias del día',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnlineStatusBar extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;
  final TextTheme text;
  final ColorScheme scheme;

  const _OnlineStatusBar({
    required this.isOnline,
    required this.onToggle,
    required this.text,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF1E8E5A)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Estás en línea' : 'Estás offline',
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                if (isOnline)
                  Text(
                    'Buscando viajes cerca de ti…',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isOnline,
            onChanged: onToggle,
            activeTrackColor: const Color(0xFF1E8E5A).withValues(alpha: 0.4),
            activeThumbColor: const Color(0xFF1E8E5A),
          ),
        ],
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  final DriverStats? stats;
  final List<SolicitudViaje> pendientes;
  final ValueChanged<SolicitudViaje> onSelect;
  final TextTheme text;
  final ColorScheme scheme;
  final VoidCallback onGanancias;

  const _BottomSheet({
    required this.stats,
    required this.pendientes,
    required this.onSelect,
    required this.text,
    required this.scheme,
    required this.onGanancias,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PendingTrips(
            pendientes: pendientes,
            onSelect: onSelect,
            text: text,
            scheme: scheme,
          ),
          if (stats != null) ...[
            const Divider(height: 24),
            ..._buildStatsContent(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStatsContent() {
    final s = stats!;
    return [
      Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '\$${s.gananciasHoy.toStringAsFixed(2)}',
              label: 'Ganancias hoy',
              scheme: scheme,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outlineVariant,
          ),
          Expanded(
            child: _StatItem(
              value: '${s.viajesHoy}',
              label: 'Viajes',
              scheme: scheme,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: scheme.outlineVariant,
          ),
          Expanded(
            child: _StatItem(
              value: '${s.horasEnLinea} h',
              label: 'En línea',
              scheme: scheme,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onGanancias,
        child: Text(
          'Ver mis ganancias',
          style: text.bodyMedium?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final ColorScheme scheme;

  const _StatItem({
    required this.value,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
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
            Icon(
              hay ? Icons.directions_car_filled : Icons.directions_car_outlined,
              size: 20,
              color: hay ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(hay ? 'Viajes para ti' : 'Viajes disponibles',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.radar, color: scheme.onSurfaceVariant, size: 28),
                const SizedBox(height: 8),
                Text('Buscando viajes cerca de ti',
                    style: text.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Mantente en línea, te avisaremos al instante.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
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
    final nombre = viaje.nombreCompleto.isNotEmpty ? viaje.nombreCompleto : 'Pasajero';
    return Material(
      color: scheme.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: scheme.primary),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(nombre,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700)),
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
                                                color:
                                                    scheme.onSurfaceVariant)),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('\$${viaje.monto.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      color: scheme.onPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RouteLine(
                          origen: viaje.origen,
                          destino: viaje.destino,
                          scheme: scheme,
                          text: text,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _MetaChip(
                                      icon: Icons.straighten,
                                      label:
                                          '${viaje.distanciaKm.toStringAsFixed(1)} km',
                                      scheme: scheme,
                                      text: text),
                                  _MetaChip(
                                      icon: Icons.schedule,
                                      label: '${viaje.duracionMin} min',
                                      scheme: scheme,
                                      text: text),
                                  _MetaChip(
                                      icon: Icons.payments_outlined,
                                      label: viaje.metodoPago,
                                      scheme: scheme,
                                      text: text),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Aceptar',
                                style: text.bodyMedium?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800)),
                            Icon(Icons.chevron_right,
                                color: scheme.primary, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;
  final TextTheme text;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.scheme,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label,
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ZonaBadge extends StatelessWidget {
  final double intensidad;
  final Color color;
  final VoidCallback onTap;

  const _ZonaBadge({
    required this.intensidad,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.local_fire_department,
                color: Colors.white, size: 18),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 3,
                ),
              ],
            ),
            child: Text(
              '${(intensidad * 100).round()}%',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ZoneDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
