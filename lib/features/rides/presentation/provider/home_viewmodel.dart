import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/rides_module.dart';
import '../../domain/entities/solicitud_viaje.dart';
import '../../domain/repositories/rides_repository.dart';

final homeViewModelProvider =
    ChangeNotifierProvider.autoDispose<HomeViewModel>((ref) {
  return HomeViewModel(ref.watch(ridesRepositoryProvider));
});

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository);

  final RidesRepository _repository;

  DriverStats? _stats;
  SolicitudViaje? _currentRequest;
  bool _isLoading = false;
  bool _isOnline = true;
  String? _errorMessage;

  DriverStats? get stats => _stats;
  SolicitudViaje? get currentRequest => _currentRequest;
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getStats(),
        _repository.getCurrentRequest(),
      ]);
      _stats = results[0] as DriverStats;
      _currentRequest = results[1] as SolicitudViaje?;
    } catch (e) {
      _errorMessage = 'Error al cargar datos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleOnline() {
    _isOnline = !_isOnline;
    notifyListeners();
  }

  Future<void> acceptRide() async {
    if (_currentRequest == null) return;
    await _repository.acceptRide(_currentRequest!.id);
    _currentRequest = null;
    notifyListeners();
  }

  Future<void> rejectRide() async {
    if (_currentRequest == null) return;
    await _repository.rejectRide(_currentRequest!.id);
    _currentRequest = null;
    notifyListeners();
  }
}
