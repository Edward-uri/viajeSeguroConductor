import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/security/sensitive_data_processor.dart';
import '../../../../core/session/session_service.dart';
import '../../../../core/storage/sensitive_data_storage.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../di/profile_module.dart';
import '../../domain/repositories/profile_repository.dart';

final profileViewModelProvider =
    ChangeNotifierProvider.autoDispose<ProfileViewModel>((ref) {
  return ProfileViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(sessionServiceProvider),
    ref.watch(sensitiveDataStorageProvider),
  );
});

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._profileRepo, this._sessionService, this._sensitiveStorage);

  final ProfileRepository _profileRepo;
  final SessionService _sessionService;
  final SensitiveDataStorage _sensitiveStorage;

  User? _user;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  bool _isDeleting = false;
  String? _errorMessage;

  String _maskedEmail = '';
  String _maskedPhone = '';
  String _dataFingerprint = '';

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;
  String get maskedEmail => _maskedEmail;
  String get maskedPhone => _maskedPhone;
  String get dataFingerprint => _dataFingerprint;

  Future<void> _loadSensitiveData() async {
    final email = await _sensitiveStorage.readEmail();
    final phone = await _sensitiveStorage.readPhone();
    _maskedEmail = email != null
        ? SensitiveDataProcessor.maskEmail(email)
        : 'No disponible';
    _maskedPhone = phone != null
        ? SensitiveDataProcessor.maskPhone(phone)
        : 'No disponible';

    final allData = <String, dynamic>{
      'email': email,
      'phone': phone,
      'username': await _sensitiveStorage.readUsername(),
      'userId': await _sensitiveStorage.readUserId(),
    };
    _dataFingerprint = SensitiveDataProcessor.computeDataFingerprint(allData);
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _profileRepo.getMe();
      await _loadSensitiveData();
    } on UnauthorizedException {
      // JWT vencido o invalido. La View detectara `user == null` y
      // sabra que tiene que ir al login.
      await _sessionService.logout();
      _errorMessage = 'Tu sesion expiro. Inicia sesion de nuevo.';
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Ocurrio un error inesperado';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> uploadNewPhoto({
    required List<int> bytes,
    required String contentType,
  }) async {
    if (_user == null) return false;
    _isUploadingPhoto = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final ticket =
          await _profileRepo.requestPhotoUpload(contentType: contentType);
      if (bytes.length > ticket.maxBytes) {
        throw ApiException(
          'La imagen excede el tamano maximo permitido (${ticket.maxBytes ~/ (1024 * 1024)} MB).',
        );
      }
      await _profileRepo.uploadBytesToS3(
        uploadUrl: ticket.uploadUrl,
        bytes: bytes,
        contentType: contentType,
      );
      _user = await _profileRepo.confirmPhotoUpload(s3Key: ticket.s3Key);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo actualizar la foto';
      return false;
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _profileRepo.deleteAccount();
      await _sessionService.logout();
      _user = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo eliminar la cuenta';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _sessionService.logout();
    _user = null;
    notifyListeners();
  }
}
