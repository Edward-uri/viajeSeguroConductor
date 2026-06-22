import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              vm.errorMessage!,
              style: const TextStyle(color: Color(0xFF6B6661)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.read(rideHistoryViewModelProvider).loadHistory(),
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
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Sin viajes aún',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B6661),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: vm.rides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _RideHistoryCard(ride: vm.rides[i]),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final RideHistoryItem ride;

  const _RideHistoryCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final estadoStr = _estadoLabel(ride.estado);
    final estadoColor = _estadoColor(ride.estado);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.motorcycle_outlined,
              color: Color(0xFFFF8F00),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${ride.origen} → ${ride.destino}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: estadoColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estadoStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: estadoColor,
                        ),
                      ),
                    ),
                    if (ride.distanciaKm != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${ride.distanciaKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B6661),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '\$${ride.monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF8F00),
            ),
          ),
        ],
      ),
    );
  }

  String _estadoLabel(String estado) {
    switch (estado) {
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
        return estado;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'completado':
        return const Color(0xFF1E8E5A);
      case 'en_curso':
      case 'aceptado':
        return const Color(0xFFFF8F00);
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
