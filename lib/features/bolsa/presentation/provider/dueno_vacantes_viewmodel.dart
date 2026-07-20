import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../../vehicle/di/vehicle_module.dart';
import '../../../vehicle/domain/entities/vehiculo.dart';
import '../../../vehicle/domain/repositories/vehicle_repository.dart';
import '../../di/bolsa_module.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../../domain/repositories/bolsa_repository.dart';

final duenoVacantesViewModelProvider =
    ChangeNotifierProvider.autoDispose<DuenoVacantesViewModel>((ref) {
  return DuenoVacantesViewModel(
    ref.watch(bolsaRepositoryProvider),
    ref.watch(vehicleRepositoryProvider),
  );
});

/// Vistas del dueño: publicar vacantes y gestionar postulaciones.
/// Separado de BolsaViewModel (ese es del conductor: buscar/postular).
class DuenoVacantesViewModel extends ChangeNotifier {
  DuenoVacantesViewModel(this._repository, this._vehicleRepository);

  final BolsaRepository _repository;
  final VehicleRepository _vehicleRepository;

  List<Vacante> _vacantes = [];
  List<Vehiculo> _vehiculos = [];
  List<Postulacion> _postulaciones = [];
  bool _isLoading = false;
  bool _isWorking = false;
  String? _errorMessage;
  String? _successMessage;

  List<Vacante> get vacantes => _vacantes;
  List<Postulacion> get postulaciones => _postulaciones;
  bool get isLoading => _isLoading;
  bool get isWorking => _isWorking;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Mis vehículos sin una vacante abierta (para el dropdown de publicar).
  List<Vehiculo> get vehiculosSinVacante {
    final conVacante = _vacantes
        .where((v) => v.abierta)
        .map((v) => v.idVehiculo)
        .toSet();
    return _vehiculos.where((v) => !conVacante.contains(v.idVehiculo)).toList();
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.misVacantes(),
        _vehicleRepository.getVehiculos(),
      ]);
      _vacantes = results[0] as List<Vacante>;
      _vehiculos = results[1] as List<Vehiculo>;
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No pudimos cargar tus vacantes. Intenta de nuevo.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPostulaciones(int idVacante) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _postulaciones = await _repository.postulacionesDe(idVacante);
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No pudimos cargar las postulaciones. Intenta de nuevo.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> crearVacante(int idVehiculo, String? condiciones) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    var ok = false;
    try {
      await _repository.crearVacante(idVehiculo, condiciones);
      ok = true;
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No se pudo publicar la vacante. Intenta de nuevo.');
    } finally {
      _isWorking = false;
      notifyListeners();
    }
    return ok;
  }

  Future<void> cerrarVacante(int idVacante) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.cerrarVacante(idVacante);
      await load();
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No se pudo cerrar la vacante. Intenta de nuevo.');
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  Future<void> aceptarPostulacion(int idPostulacion, int idVacante) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.aceptarPostulacion(idPostulacion);
      _successMessage = 'Conductor asignado';
      await loadPostulaciones(idVacante);
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No se pudo aceptar la postulación. Intenta de nuevo.');
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }
}
