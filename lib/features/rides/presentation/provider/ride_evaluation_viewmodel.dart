import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/rides_module.dart';
import '../../domain/repositories/rides_repository.dart';

final rideEvaluationViewModelProvider =
    ChangeNotifierProvider.autoDispose<RideEvaluationViewModel>((ref) {
  return RideEvaluationViewModel(ref.watch(ridesRepositoryProvider));
});

class RideEvaluationViewModel extends ChangeNotifier {
  RideEvaluationViewModel(this._repository);

  final RidesRepository _repository;

  int _calificacion = 5;
  String _comentario = '';
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isSubmitted = false;

  int get calificacion => _calificacion;
  String get comentario => _comentario;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isSubmitted => _isSubmitted;

  void setCalificacion(int stars) {
    _calificacion = stars;
    notifyListeners();
  }

  void setComentario(String text) {
    _comentario = text;
    notifyListeners();
  }

  Future<void> submit(String rideId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.rateRide(
        rideId,
        calificacion: _calificacion,
        comentario: _comentario.isNotEmpty ? _comentario : null,
      );
      _isSubmitted = true;
    } catch (e) {
      _errorMessage = 'Error al enviar evaluación';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
