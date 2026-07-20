import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  String get nombre => _nombre;
  String get apellidoPaterno => _apellidoPaterno;
  String get apellidoMaterno => _apellidoMaterno;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get canSubmit =>
      _nombre.trim().isNotEmpty && _apellidoPaterno.trim().isNotEmpty;

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
        ),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.messageFor(e,
          fallback: 'Ocurrió un error al guardar los cambios');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
