import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/theme.dart';
import '../../domain/entities/ride_history_item.dart';
import '../provider/ride_history_viewmodel.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(rideHistoryViewModelProvider).loadHistory(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(rideHistoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildContent(vm),
        ),
      ),
    );
  }

  Widget _buildContent(RideHistoryViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  ref.read(rideHistoryViewModelProvider).loadHistory(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (vm.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              'Sin viajes aún',
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: vm.rides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _RideHistoryCard(ride: vm.rides[i]),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final RideHistoryItem ride;

  const _RideHistoryCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final estadoColor = _estadoColor(scheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.motorcycle_outlined,
                color: scheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ride.origen} → ${ride.destino}',
                    style:
                        text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      text: _estadoLabel(),
                      style: text.bodySmall?.copyWith(
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        if (ride.distanciaKm != null)
                          TextSpan(
                            text:
                                ' · ${ride.distanciaKm!.toStringAsFixed(1)} km',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '\$${ride.monto.toStringAsFixed(2)}',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  String _estadoLabel() {
    switch (ride.estado) {
      case 'solicitado':
        return 'Solicitado';
      case 'aceptado':
        return 'Aceptado';
      case 'en_curso':
        return 'En curso';
      case 'completado':
        return 'Completado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return ride.estado;
    }
  }

  Color _estadoColor(ColorScheme scheme) {
    switch (ride.estado) {
      case 'completado':
        return JalaBrand.success;
      case 'en_curso':
      case 'aceptado':
        return JalaBrand.amberDeep;
      case 'cancelado':
        return scheme.error;
      default:
        return scheme.onSurfaceVariant;
    }
  }
}
