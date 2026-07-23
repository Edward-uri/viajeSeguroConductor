import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
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
  static const _perPage = 10;

  List<RideHistoryItem> _rides = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _estado; // filtro de estado; null = todos
  int? _dias; // filtro de fecha; null = todo, 0 = hoy, 7, 30

  List<RideHistoryItem> get rides => _rides;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _rides.isEmpty && !_isLoading;
  bool get hasMore => _page < _totalPages;
  int get total => _total;
  String? get estado => _estado;
  int? get dias => _dias;

  DateTime? get _desde {
    final d = _dias;
    if (d == null) return null;
    final now = DateTime.now();
    if (d == 0) return DateTime(now.year, now.month, now.day);
    return now.subtract(Duration(days: d));
  }

  Future<void> loadHistory() => _load();

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final res = await _repository.getHistorial(
        page: 1,
        perPage: _perPage,
        estado: _estado,
        desde: _desde,
      );
      _rides = res.items;
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
    } catch (e) {
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'Error al cargar el historial');
      _rides = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final res = await _repository.getHistorial(
        page: _page + 1,
        perPage: _perPage,
        estado: _estado,
        desde: _desde,
      );
      _rides = [..._rides, ...res.items];
      _page = res.page;
      _totalPages = res.totalPages;
      _total = res.total;
    } catch (e) {
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'No se pudo cargar más.');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setEstado(String? estado) {
    if (_estado == estado) return;
    _estado = estado;
    _load();
  }

  void setDias(int? dias) {
    if (_dias == dias) return;
    _dias = dias;
    _load();
  }
}
