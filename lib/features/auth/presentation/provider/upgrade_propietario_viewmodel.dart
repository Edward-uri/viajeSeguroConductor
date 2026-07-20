import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../../../../core/error/error.dart';
import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_exception.dart';
import '../../../profile/di/profile_module.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

final upgradePropietarioViewModelProvider =
    ChangeNotifierProvider.autoDispose<UpgradePropietarioViewModel>((ref) {
  return UpgradePropietarioViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});

class UpgradePropietarioViewModel extends ChangeNotifier {
  UpgradePropietarioViewModel(this._profileRepository, this._apiClient);

  final ProfileRepository _profileRepository;
  final ApiClient _apiClient;

  bool _isWorking = false;
  String? _errorMessage;

  bool get isWorking => _isWorking;
  String? get errorMessage => _errorMessage;

  /// Activa el rol propietario y refresca tokens (el access viejo no trae el
  /// rol nuevo). Devuelve un enum: ok (ambos OK), okSinRefresh (activó pero
  /// refresh falló), error (activación falló).
  Future<ActivationResult> activar() async {
    _isWorking = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _profileRepository.activarPropietario();
      final refreshOk = await _refreshTokens();
      if (!refreshOk) {
        return ActivationResult.okSinRefresh;
      }
      return ActivationResult.ok;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return ActivationResult.error;
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      return ActivationResult.error;
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  // Único camino de refresh: ApiClient.refreshSession() (single-flight,
  // cooldown y manejo de sesión muerta incluidos).
  Future<bool> _refreshTokens() => _apiClient.refreshSession();
}

enum ActivationResult { ok, okSinRefresh, error }
