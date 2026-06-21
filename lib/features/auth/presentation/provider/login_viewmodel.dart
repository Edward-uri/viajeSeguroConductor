import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../di/auth_module.dart';
import '../../domain/repositories/auth_repository.dart';

final loginViewModelProvider =
    ChangeNotifierProvider<LoginViewModel>((ref) {
  return LoginViewModel(ref.watch(authRepositoryProvider));
});

class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository);

  final AuthRepository _repository;

  String _email = '';
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get email => _email;

  void setEmail(String v) {
    _email = v;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> sendOtp() async {
    if (_email.trim().isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.loginStart(correo: _email.trim());
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

  Future<bool> verifyOtp(String codigo) async {
    if (_email.trim().isEmpty || codigo.length != 4) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.loginVerify(
        correo: _email.trim(),
        codigo: codigo,
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
