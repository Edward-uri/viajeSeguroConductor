import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/rides_module.dart';
import '../../domain/entities/ride_history_item.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final _earningsProvider =
    ChangeNotifierProvider.autoDispose<_EarningsViewModel>((ref) {
  return _EarningsViewModel(ref.watch(ridesRepositoryProvider));
});

class _EarningsViewModel extends ChangeNotifier {
  _EarningsViewModel(this._repository);

  final RidesRepository _repository;

  DriverStats? _stats;
  List<RideHistoryItem> _recentRides = [];
  bool _isLoading = true;
  String? _errorMessage;

  DriverStats? get stats => _stats;
  List<RideHistoryItem> get recentRides => _recentRides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getAssignedRides(),
      ]);
      _stats = results[0] as DriverStats;
      _recentRides = results[1] as List<RideHistoryItem>;
    } catch (e) {
      _errorMessage = 'Error al cargar tus ganancias';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(_earningsProvider).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(_earningsProvider);
    final text = Theme.of(context).textTheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vm.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.errorMessage!,
                            style: text.bodyMedium?.copyWith(
                                color: const Color(0xFF6B6661))),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref.read(_earningsProvider).load(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(isLandscape ? 12 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EarningsHeader(stats: vm.stats, isLandscape: isLandscape),
                        SizedBox(height: isLandscape ? 12 : 24),
                        Text(
                          'Últimos viajes',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1410),
                          ),
                        ),
                        SizedBox(height: isLandscape ? 8 : 12),
                        Expanded(
                          child: vm.recentRides.isEmpty
                              ? Center(
                                  child: Text('Aún no tienes viajes hoy',
                                      style: text.bodyMedium?.copyWith(
                                          color: const Color(0xFF6B6661))),
                                )
                              : ListView.separated(
                                  itemCount: vm.recentRides.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, i) {
                                    final r = vm.recentRides[i];
                                    return _EarningRow(
                                      hora: r.estado,
                                      monto: r.monto,
                                      origen: r.origen,
                                      destino: r.destino,
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _EarningsHeader extends StatelessWidget {
  final DriverStats? stats;
  final bool isLandscape;

  const _EarningsHeader({required this.stats, this.isLandscape = false});

  @override
  Widget build(BuildContext context) {
    final ganancias = stats?.gananciasHoy ?? 0;
    final viajes = stats?.viajesHoy ?? 0;
    final horas = stats?.horasEnLinea ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isLandscape ? 12 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8F00),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ganancias de hoy',
            style: TextStyle(
              fontSize: isLandscape ? 12 : 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${ganancias.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isLandscape ? 24 : 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isLandscape ? 6 : 12),
          Row(
            children: [
              _Chip('$viajes viajes'),
              const SizedBox(width: 8),
              _Chip('${horas.toStringAsFixed(1)} h en línea'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final String hora;
  final double monto;
  final String origen;
  final String destino;

  const _EarningRow({
    required this.hora,
    required this.monto,
    required this.origen,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_outlined,
                size: 18, color: Color(0xFFFF8F00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$origen → $destino',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B6661),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
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
}
