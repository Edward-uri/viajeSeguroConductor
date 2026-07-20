import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/session/session_service.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../auth/di/auth_module.dart';
import '../../di/profile_module.dart';
import '../../domain/repositories/profile_repository.dart';

final driverProfileViewModelProvider =
    ChangeNotifierProvider.autoDispose<DriverProfileViewModel>((ref) {
  return DriverProfileViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(sessionServiceProvider),
  );
});

class DriverProfileViewModel extends ChangeNotifier {
  DriverProfileViewModel(
    this._profileRepo,
    this._sessionService,
  );

  final ProfileRepository _profileRepo;
  final SessionService _sessionService;

  User? _user;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _profileRepo.getMe();
    } on UnauthorizedException {
      await _sessionService.logout();
      _errorMessage = 'Tu sesión expiró. Inicia sesión de nuevo.';
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
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
    } catch (e) {
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'Error al actualizar perfil');
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
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'No pudimos actualizar tu foto. Intenta de nuevo.');
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
