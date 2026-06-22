import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../di/auth_module.dart';
import '../../domain/repositories/auth_repository.dart';

final loginPasswordViewModelProvider =
    ChangeNotifierProvider<LoginPasswordViewModel>((ref) {
  return LoginPasswordViewModel(ref.watch(authRepositoryProvider));
});

class LoginPasswordViewModel extends ChangeNotifier {
  LoginPasswordViewModel(this._repository);

  final AuthRepository _repository;

  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setEmail(String v) {
    _email = v;
    clearError();
  }

  void setPassword(String v) {
    _password = v;
    clearError();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login() async {
    if (_email.trim().isEmpty || _password.isEmpty) {
      _errorMessage = 'Completa todos los campos';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.loginPassword(
        correo: _email.trim(),
        password: _password,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Ocurrió un error inesperado';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
