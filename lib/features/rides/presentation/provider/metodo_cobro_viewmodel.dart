import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../domain/entities/metodo_cobro.dart';
import '../../domain/repositories/metodo_cobro_repository.dart';
import '../../di/rides_module.dart';

final metodoCobroViewModelProvider =
    ChangeNotifierProvider.autoDispose<MetodoCobroViewModel>((ref) {
  return MetodoCobroViewModel(ref.watch(metodoCobroRepositoryProvider));
});

class MetodoCobroViewModel extends ChangeNotifier {
  MetodoCobroViewModel(this._repository);

  final MetodoCobroRepository _repository;

  MetodoCobro? _metodoCobro;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _noDisponible = false;
  String? _errorMessage;

  MetodoCobro? get metodoCobro => _metodoCobro;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _metodoCobro = await _repository.getMetodoCobro();
      if (_metodoCobro == null) {
        _noDisponible = true;
        _errorMessage =
            'Método de cobro no disponible. Próximamente podrás configurarlo.';
      }
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'Error al cargar método de cobro');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> save(MetodoCobro metodoCobro) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.saveMetodoCobro(metodoCobro);
      _metodoCobro = metodoCobro;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback:
              'Método de cobro no disponible. Próximamente podrás configurarlo.');
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  bool get noDisponible => _noDisponible;
}
