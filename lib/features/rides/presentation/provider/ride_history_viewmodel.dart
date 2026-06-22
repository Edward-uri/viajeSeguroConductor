import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/rides_module.dart';
import '../../domain/entities/ride_history_item.dart';
import '../../domain/repositories/rides_repository.dart';

final rideHistoryViewModelProvider =
    ChangeNotifierProvider.autoDispose<RideHistoryViewModel>((ref) {
  return RideHistoryViewModel(ref.watch(ridesRepositoryProvider));
});

class RideHistoryViewModel extends ChangeNotifier {
  RideHistoryViewModel(this._repository);

  final RidesRepository _repository;

  List<RideHistoryItem> _rides = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RideHistoryItem> get rides => _rides;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _rides.isEmpty && !_isLoading;

  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _rides = await _repository.getAssignedRides();
    } catch (e) {
      _errorMessage = 'Error al cargar el historial';
      _rides = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
