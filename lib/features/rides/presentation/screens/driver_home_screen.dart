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
      await vm.initLocation();
      _centerOnDriver();

      if (!_socketInitialized) {
        _socketInitialized = true;
        final storage = ref.read(authStorageProvider);
        final token = await storage.readAccessToken();
        debugPrint('TOKEN: $token');
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
                      if (vm.zonasCalientes.isNotEmpty)
                        CircleLayer(
                          circles: vm.zonasCalientes.map((z) {
                            final opacity = 0.3 + (z.intensidad * 0.5);
                            return CircleMarker(
                              point: LatLng(z.lat, z.lng),
                              radius: z.radioM,
                              useRadiusInMeter: true,
                              color: Color.lerp(
                                Colors.orange.withValues(alpha: opacity),
                                Colors.red.withValues(alpha: opacity),
                                z.intensidad,
                              )!,
                              borderColor: Colors.red.shade900,
                              borderStrokeWidth: 1,
                              hitValue: z,
                            );
                          }).toList(),
                          hitNotifier: _heatHitNotifier,
                        ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Viajes disponibles',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            if (pendientes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${pendientes.length}',
                    style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (pendientes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('Aún no hay viajes cerca. Mantente en línea.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: pendientes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primary,
              child: Text(viaje.pasajeroIniciales,
                  style: TextStyle(
                      color: scheme.onPrimary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(viaje.nombreCompleto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      Text('\$${viaje.monto.toStringAsFixed(2)}',
                          style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${viaje.origen} → ${viaje.destino}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(
                      '${viaje.distanciaKm.toStringAsFixed(1)} km · ${viaje.duracionMin} min · ${viaje.metodoPago}',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
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
