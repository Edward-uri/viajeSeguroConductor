import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/http/api_exception.dart';
import '../../di/profile_module.dart';
import '../../domain/entities/update_profile_params.dart';
import '../../domain/repositories/profile_repository.dart';

final editProfileViewModelProvider =
    ChangeNotifierProvider.autoDispose<EditProfileViewModel>((ref) {
  return EditProfileViewModel(ref.watch(profileRepositoryProvider));
});

class EditProfileViewModel extends ChangeNotifier {
  EditProfileViewModel(this._profileRepo);

  final ProfileRepository _profileRepo;

  String _nombre = '';
  String _apellidoPaterno = '';
  String _apellidoMaterno = '';
  String _correoElectronico = '';
  bool _isLoading = false;
  String? _errorMessage;

  String get nombre => _nombre;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  String get correoElectronico => _correoElectronico;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get canSubmit =>
      _nombre.trim().isNotEmpty &&
      _apellidoPaterno.trim().isNotEmpty &&
      _correoElectronico.trim().contains('@');

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

  void setCorreo(String v) {
    _correoElectronico = v;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (!canSubmit) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepo.updateProfile(
        UpdateProfileParams(
          nombre: _nombre.trim(),
          apellidoPaterno: _apellidoPaterno.trim(),
          apellidoMaterno: _apellidoMaterno.trim().isEmpty
              ? null
              : _apellidoMaterno.trim(),
          correoElectronico: _correoElectronico.trim(),
        ),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Ocurrió un error al guardar los cambios';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
