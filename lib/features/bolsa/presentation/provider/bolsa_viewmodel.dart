import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../../profile/di/profile_module.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../di/bolsa_module.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../../domain/repositories/bolsa_repository.dart';

final bolsaViewModelProvider =
    ChangeNotifierProvider.autoDispose<BolsaViewModel>((ref) {
  return BolsaViewModel(
    ref.watch(bolsaRepositoryProvider),
    ref.watch(profileRepositoryProvider),
  );
});

class BolsaViewModel extends ChangeNotifier {
  BolsaViewModel(this._repository, this._profileRepository);

  final BolsaRepository _repository;
  final ProfileRepository _profileRepository;

  List<Vacante> _vacantes = [];
  List<Postulacion> _postulaciones = [];
  bool _isLoading = false;
  bool _isWorking = false;
  String? _errorMessage;

  List<Vacante> get vacantes => _vacantes;
  List<Postulacion> get postulaciones => _postulaciones;
  bool get isLoading => _isLoading;
  bool get isWorking => _isWorking;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // Mismo patrón que home_viewmodel: municipio del usuario, default 1.
      var idMunicipio = 1;
      try {
        final user = await _profileRepository.getMe();
        if (user.idMunicipio != null) idMunicipio = user.idMunicipio!;
      } catch (_) {}
      final results = await Future.wait([
        _repository.getVacantes(idMunicipio),
        _repository.getMisPostulaciones(),
      ]);
      _vacantes = results[0] as List<Vacante>;
      _postulaciones = results[1] as List<Postulacion>;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No pudimos cargar la bolsa de trabajo. Intenta de nuevo.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mi postulación para una vacante, si existe (cualquier estado).
  /// Tras retirarla SÍ se puede re-postular: el backend revive la misma fila
  /// a pendiente (la UI muestra "Postularme de nuevo" en ese caso).
  Postulacion? postulacionDe(int idVacante) {
    for (final p in _postulaciones) {
      if (p.idVacante == idVacante) return p;
    }
    return null;
  }

  /// Vehículo de una postulación cruzando con las vacantes cargadas
  /// (mis-postulaciones no trae modelo/color/anio).
  String vehiculoDe(Postulacion p) {
    for (final v in _vacantes) {
      if (v.idVacante == p.idVacante) return v.descripcionVehiculo;
    }
    return 'Vehículo #${p.idVehiculo}';
  }

  Future<void> postular(int idVacante) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.postular(idVacante);
      await load();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo enviar tu postulación. Intenta de nuevo.';
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  Future<void> retirar(int idPostulacion) async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.retirarPostulacion(idPostulacion);
      await load();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo retirar la postulación. Intenta de nuevo.';
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  String estadoLabel(EstadoPostulacion estado) {
    switch (estado) {
      case EstadoPostulacion.pendiente:
        return 'Pendiente';
      case EstadoPostulacion.aceptada:
        return 'Aceptada';
      case EstadoPostulacion.rechazada:
        return 'Rechazada';
      case EstadoPostulacion.retirada:
        return 'Retirada';
      case EstadoPostulacion.desconocido:
        return 'N/A';
    }
  }

  Color estadoColor(EstadoPostulacion estado) {
    switch (estado) {
      case EstadoPostulacion.pendiente:
        return const Color(0xFFE8A317);
      case EstadoPostulacion.aceptada:
        return const Color(0xFF1E8E5A);
      case EstadoPostulacion.rechazada:
        return const Color(0xFFD84315);
      case EstadoPostulacion.retirada:
      case EstadoPostulacion.desconocido:
        return const Color(0xFF9E9E9E);
    }
  }
}
