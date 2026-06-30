import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../di/auth_module.dart';
import '../../domain/entities/register_params.dart';
import '../../domain/repositories/auth_repository.dart';

final registerViewModelProvider =
    ChangeNotifierProvider<RegisterViewModel>((ref) {
  return RegisterViewModel(ref.watch(authRepositoryProvider));
});

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel(this._repository);

  final AuthRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  String _email = '';
  String _registrationToken = '';

  String _password = '';
  String _nombre = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';
  String _telefono = '';
  int? _idSexo;
  String _fechaNacimiento = '';
  int? _idMunicipio;

  String _licencia = '';
  String _licenciaFechaExpedicion = '';
  String _licenciaFechaVencimiento = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get email => _email;
  String get registrationToken => _registrationToken;

  String get nombre => _nombre;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  String get telefono => _telefono;
  int? get idSexo => _idSexo;
  String get fechaNacimiento => _fechaNacimiento;
  int? get idMunicipio => _idMunicipio;

  String get password => _password;

  String get licencia => _licencia;
  String get licenciaFechaExpedicion => _licenciaFechaExpedicion;
  String get licenciaFechaVencimiento => _licenciaFechaVencimiento;

  void setEmail(String v) {
    _email = v;
    notifyListeners();
  }

  void setPassword(String v) {
    _password = v;
    notifyListeners();
  }

  void setNombre(String v) {
    _nombre = v;
    notifyListeners();
  }

  void setApellidoPaterno(String v) {
    _apellidoPaterno = v;
    notifyListeners();
  }

  void setApellidoMaterno(String v) {
    _apellidoMaterno = v;
    notifyListeners();
  }

  void setTelefono(String v) {
    _telefono = v;
    notifyListeners();
  }

  void setIdSexo(int? v) {
    _idSexo = v;
    notifyListeners();
  }

  void setFechaNacimiento(String v) {
    _fechaNacimiento = v;
    notifyListeners();
  }

  void setIdMunicipio(int? v) {
    _idMunicipio = v;
    notifyListeners();
  }

  void setLicencia(String v) {
    _licencia = v;
  }

  void setLicenciaFechaExpedicion(String v) {
    _licenciaFechaExpedicion = v;
  }

  void setLicenciaFechaVencimiento(String v) {
    _licenciaFechaVencimiento = v;
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
      await _repository.registerStart(
        correo: _email.trim(),
        rol: 'conductor',
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

  Future<bool> verifyOtp(String codigo) async {
    if (_email.trim().isEmpty || codigo.length != 6) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _registrationToken = await _repository.registerVerify(
        correo: _email.trim(),
        codigo: codigo,
        rol: 'conductor',
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

  Future<bool> completeRegistration() async {
    if (_registrationToken.isEmpty) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.registerComplete(
        registrationToken: _registrationToken,
        params: RegisterParams(
          password: _password.isEmpty ? null : _password,
          nombre: _nombre.trim(),
          apellidoPaterno: _apellidoPaterno.trim(),
          apellidoMaterno:
              _apellidoMaterno.trim().isEmpty ? null : _apellidoMaterno.trim(),
          telefono: _telefono.trim().isEmpty ? null : _telefono.trim(),
          idSexo: _idSexo,
          fechaNacimiento: _fechaNacimiento.isEmpty ? null : _fechaNacimiento,
          idMunicipio: _idMunicipio,
          dispositivo: 'flutter',
        ),
      );
      if (_licencia.isNotEmpty && _licenciaFechaVencimiento.isNotEmpty) {
        try {
          await _repository.guardarLicencia(
            idMunicipio: _idMunicipio ?? 1,
            licencia: _licencia.trim(),
            licenciaFechaExpedicion: _normalizeDate(_licenciaFechaExpedicion),
            licenciaFechaVencimiento: _normalizeDate(_licenciaFechaVencimiento),
          );
        } on ApiException catch (e) {
          debugPrint('[RegisterVM] guardarLicencia falló (${e.statusCode}): ${e.message} — continuando');
        }
      }
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

  String _normalizeDate(String date) {
    final parts = date.split(' / ');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    final alt = date.split('-');
    if (alt.length == 3 && alt[0].length == 4) return date;
    return date;
  }
}
