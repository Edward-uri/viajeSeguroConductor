import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/storage/sensitive_data_storage.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../di/profile_module.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../rides/domain/entities/solicitud_viaje.dart';
import '../../../rides/domain/repositories/rides_repository.dart';
import '../../../rides/di/rides_module.dart';
import '../../../vehicle/domain/entities/vehiculo.dart';
import '../../../vehicle/domain/repositories/vehicle_repository.dart';
import '../../../vehicle/di/vehicle_module.dart';

final driverProfileViewModelProvider =
    ChangeNotifierProvider.autoDispose<DriverProfileViewModel>((ref) {
  return DriverProfileViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(ridesRepositoryProvider),
    ref.watch(vehicleRepositoryProvider),
    ref.watch(sensitiveDataStorageProvider),
    ref.watch(sessionServiceProvider),
  );
});

class DriverProfileViewModel extends ChangeNotifier {
  DriverProfileViewModel(
    this._profileRepo,
    this._ridesRepo,
    this._vehicleRepo,
    this._sensitiveStorage,
    this._sessionService,
  );

  final ProfileRepository _profileRepo;
  final RidesRepository _ridesRepo;
  final VehicleRepository _vehicleRepo;
  final SensitiveDataStorage _sensitiveStorage;
  final SessionService _sessionService;

  User? _user;
  DriverStats? _stats;
  Vehiculo? _vehiculo;
  String _displayName = '';
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  User? get user => _user;
  DriverStats? get stats => _stats;
  Vehiculo? get vehiculo => _vehiculo;
  String get displayName => _displayName;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;

  int get viajes => _stats?.viajesHoy ?? 0;
  double get ganancias => _stats?.gananciasHoy ?? 0;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _profileRepo.getMe();
    } on UnauthorizedException {
      await _sessionService.logout();
      _errorMessage = 'Tu sesion expiro. Inicia sesion de nuevo.';
      _isLoading = false;
      notifyListeners();
      return;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Ocurrio un error inesperado';
    }

    try {
      _stats = await _ridesRepo.getStats();
    } catch (_) {}

    try {
      final vehicles = await _vehicleRepo.getVehiculos();
      _vehiculo = vehicles.isNotEmpty ? vehicles.first : null;
    } catch (_) {}

    try {
      _displayName = await _sensitiveStorage.readUsername() ??
          _user?.correoElectronico ??
          'N/A';
    } catch (_) {
      _displayName = _user?.correoElectronico ?? 'N/A';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    _errorMessage = null;
    try {
      _user = await _profileRepo.updateMe(data);
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _errorMessage =
            'La edición de perfil no está disponible por el momento. Contacta al administrador.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Error al actualizar perfil';
      notifyListeners();
    }
  }

  Future<bool> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _profileRepo.uploadPhoto(bytes: bytes, fileName: fileName);
      return true;
    } catch (_) {
      _errorMessage = 'No pudimos actualizar tu foto. Intenta de nuevo.';
      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _sessionService.logout();
    _user = null;
    notifyListeners();
  }
}
