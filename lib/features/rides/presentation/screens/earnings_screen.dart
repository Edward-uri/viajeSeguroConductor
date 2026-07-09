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
    final scheme = Theme.of(context).colorScheme;
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
                        Icon(Icons.error_outline, size: 48, color: scheme.outline),
                        const SizedBox(height: 16),
                        Text(vm.errorMessage!,
                            style: text.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => ref.read(_earningsProvider).load(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: EdgeInsets.all(isLandscape ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EarningsHeader(stats: vm.stats, isLandscape: isLandscape),
                        SizedBox(height: isLandscape ? 12 : 24),
                        Text(
                          'Últimos viajes',
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: isLandscape ? 8 : 12),
                        Expanded(
                          child: vm.recentRides.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.directions_car_outlined,
                                          size: 48, color: scheme.outline),
                                      const SizedBox(height: 16),
                                      Text('Aún no tienes viajes hoy',
                                          style: text.bodyLarge?.copyWith(
                                              color: scheme.onSurfaceVariant)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: vm.recentRides.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 12),
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ganancias = stats?.gananciasHoy ?? 0;
    final viajes = stats?.viajesHoy ?? 0;
    final horas = stats?.horasEnLinea ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ganancias de hoy',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          '\$${ganancias.toStringAsFixed(2)}',
          style: isLandscape ? text.headlineSmall : text.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          '$viajes viajes · ${horas.toStringAsFixed(1)} h en línea',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.directions_car_outlined,
                size: 18,
                color: scheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$origen → $destino',
                    style:
                        text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hora,
                    style:
                        text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '\$${monto.toStringAsFixed(2)}',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
