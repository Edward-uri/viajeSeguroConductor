import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        Navigator.of(context).pushNamedAndRemoveUntil(
          route,
          (route) => false,
        );
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
          Navigator.of(context).pushNamed(AppRoutes.rideRequest);
        }
      },
    );

    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (vm.stats != null)
              _EarningsCard(stats: vm.stats!, text: text),
            _OnlineStatusBar(
              isOnline: vm.isOnline,
              onToggle: (_) => vm.toggleOnline(),
              text: text,
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
                        urlTemplate: ApiConfig.mapboxTilesUrl,
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
                      backgroundColor: Colors.white,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF1A1410),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _BottomSheet(
              stats: vm.stats,
              text: text,
              scheme: scheme,
              onGanancias: () => Navigator.of(context)
                  .pushNamed(AppRoutes.earnings),
              onPerfil: () =>
                  Navigator.of(context).pushNamed(AppRoutes.driverProfile),
              onFlotilla: () =>
                  Navigator.of(context).pushNamed(AppRoutes.vehicles),
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

  const _EarningsCard({required this.stats, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8F00).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFFFF8F00),
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
                  color: const Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ganancias del día',
                style: text.bodySmall?.copyWith(
                  color: const Color(0xFF6B6661),
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

  const _OnlineStatusBar({
    required this.isOnline,
    required this.onToggle,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
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
                        color: const Color(0xFF1A1410),
                      ),
                    ),
                  ],
                ),
                if (isOnline)
                  Text(
                    'Buscando viajes cerca de ti…',
                    style: text.bodySmall?.copyWith(
                      color: const Color(0xFF6B6661),
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
  final TextTheme text;
  final ColorScheme scheme;
  final VoidCallback onGanancias;
  final VoidCallback onPerfil;
  final VoidCallback onFlotilla;

  const _BottomSheet({
    required this.stats,
    required this.text,
    required this.scheme,
    required this.onGanancias,
    required this.onPerfil,
    required this.onFlotilla,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stats != null) ..._buildStatsContent(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NavButton(
                  icon: Icons.person_outline,
                  label: 'Perfil',
                  onTap: onPerfil,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavButton(
                  icon: Icons.directions_car_outlined,
                  label: 'Flotilla',
                  onTap: onFlotilla,
                ),
              ),
            ],
          ),
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
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE2E2E2),
          ),
          Expanded(
            child: _StatItem(
              value: '${s.viajesHoy}',
              label: 'Viajes',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFFE2E2E2),
          ),
          Expanded(
            child: _StatItem(
              value: '${s.horasEnLinea} h',
              label: 'En línea',
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
            color: const Color(0xFFFF8F00),
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

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF8F00),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B6661),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: const Color(0xFFE2E2E2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: const Color(0xFF1A1410),
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
