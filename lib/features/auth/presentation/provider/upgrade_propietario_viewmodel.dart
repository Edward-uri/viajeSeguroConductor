import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/di/core_module.dart';
import '../../../../core/env/api_config.dart';
import '../../../../core/http/api_endpoints.dart';
import '../../../../core/http/api_exception.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../profile/di/profile_module.dart';
import '../../../profile/domain/repositories/profile_repository.dart';

final upgradePropietarioViewModelProvider =
    ChangeNotifierProvider.autoDispose<UpgradePropietarioViewModel>((ref) {
  return UpgradePropietarioViewModel(
    ref.watch(profileRepositoryProvider),
    ref.watch(authStorageProvider),
  );
});

class UpgradePropietarioViewModel extends ChangeNotifier {
  UpgradePropietarioViewModel(this._profileRepository, this._authStorage);

  final ProfileRepository _profileRepository;
  final AuthStorage _authStorage;

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
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado. Intenta de nuevo.';
      return ActivationResult.error;
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  // Duplicado a propósito de HomeViewModel._refreshSocketToken(): es un
  // bloque pequeño (lee refreshToken → POST refresh → writeTokens) y
  // extraerlo mezclaría la atribución de ambos cambios.
  Future<bool> _refreshTokens() async {
    final refreshToken = await _authStorage.readRefreshToken();
    if (refreshToken == null) return false;
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('${ApiConfig.baseUrl}${ApiEndpoints.refresh}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.requestTimeout);
      if (response.statusCode != 200) return false;
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = decoded['accessToken'] as String?;
      final newRefreshToken = decoded['refreshToken'] as String?;
      if (accessToken == null || newRefreshToken == null) return false;
      await _authStorage.writeTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }
}

enum ActivationResult { ok, okSinRefresh, error }
