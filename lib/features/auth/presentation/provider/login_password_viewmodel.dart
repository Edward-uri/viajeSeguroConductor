import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../../../core/error/error.dart';
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
  String? _passwordError;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get passwordError => _passwordError;

  void setEmail(String v) {
    _email = v;
    clearError();
  }

  void setPassword(String v) {
    _password = v;
    final error = (v.isNotEmpty && v.length < 6)
        ? 'La contraseña debe tener al menos 6 caracteres'
        : null;
    // Solo notifica cuando cambia algo visible: antes notificaba en cada
    // tecla y reconstruía toda la pantalla de login por pulsación.
    final changed = error != _passwordError || _errorMessage != null;
    _passwordError = error;
    _errorMessage = null;
    if (changed) notifyListeners();
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
    if (_password.length < 6) {
      _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
      _passwordError = _errorMessage;
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    _passwordError = null;
    notifyListeners();
    try {
      await _repository.loginPassword(
        correo: _email.trim(),
        password: _password,
      );
      return true;
    } on ApiException catch (e) {
      // El mensaje del backend (p. ej. credenciales inválidas) es el correcto aquí.
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = ErrorHandler.handle(e).message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
