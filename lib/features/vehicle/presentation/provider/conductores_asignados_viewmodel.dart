import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../di/vehicle_module.dart';
import '../../domain/entities/conductor_asignado.dart';
import '../../domain/repositories/vehicle_repository.dart';

/// Un viewmodel por vehículo (familia): carga y gestiona sus conductores asignados.
final conductoresAsignadosViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<ConductoresAsignadosViewModel, int>((ref, idVehiculo) {
  return ConductoresAsignadosViewModel(
    ref.watch(vehicleRepositoryProvider),
    idVehiculo,
  )..load();
});

class ConductoresAsignadosViewModel extends ChangeNotifier {
  ConductoresAsignadosViewModel(this._repository, this._idVehiculo);

  final VehicleRepository _repository;
  final int _idVehiculo;

  List<ConductorAsignado> _conductores = [];
  bool _isLoading = true;
  bool _isWorking = false;
  String? _errorMessage;
  String? _successMessage;

  List<ConductorAsignado> get conductores => _conductores;
  bool get isLoading => _isLoading;
  bool get isWorking => _isWorking;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _conductores = await _repository.getConductoresAsignados(_idVehiculo);
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No pudimos cargar los conductores. Intenta de nuevo.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editarTerminos(
    int idConductor, {
    required String tipoTurno,
    required double rentaTurno,
    required List<String> dias,
    String? horario,
  }) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    var ok = false;
    try {
      await _repository.editarConductorAsignado(
        _idVehiculo,
        idConductor,
        tipoTurno: tipoTurno,
        rentaTurno: rentaTurno,
        dias: dias,
        horario: horario,
      );
      _successMessage = 'Términos actualizados';
      ok = true;
      await load();
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No se pudieron actualizar los términos. Intenta de nuevo.');
    } finally {
      _isWorking = false;
      notifyListeners();
    }
    return ok;
  }

  Future<void> darDeBaja(int idConductor) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.darDeBajaConductor(_idVehiculo, idConductor);
      _successMessage = 'Conductor dado de baja';
      await load();
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No se pudo dar de baja al conductor. Intenta de nuevo.');
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }
}
