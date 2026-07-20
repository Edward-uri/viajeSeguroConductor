import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../di/rides_module.dart';
import '../../domain/entities/ride_history_item.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final earningsViewModelProvider =
    ChangeNotifierProvider.autoDispose<EarningsViewModel>((ref) {
  return EarningsViewModel(ref.watch(ridesRepositoryProvider));
});

class EarningsViewModel extends ChangeNotifier {
  EarningsViewModel(this._repository);

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
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'Error al cargar tus ganancias');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
