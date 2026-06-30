import 'dart:typed_data';

import '../../../core/http/api_exception.dart';
import '../../../shared/data/mappers/user_mapper.dart';
import '../../../shared/domain/entities/user.dart';
import '../domain/entities/update_profile_params.dart';
import '../domain/repositories/profile_repository.dart';
import 'remote/profile_api.dart';


class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final ProfileApi _api;

  @override
  Future<User> getMe() async {
    final response = await _api.getMe();
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<User> updateMe(Map<String, dynamic> data) async {
    final response = await _api.updateMe(data);
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<User> updateProfile(UpdateProfileParams params) async {
    final response = await _api.updateMe(params.toJson());
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<User> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final response = await _api.uploadPhoto(bytes: bytes, fileName: fileName);
    return UserMapper.fromJson(_unwrapData(response));
  }

  @override
  Future<void> deleteAccount() => _api.deleteAccount();


  Map<String, dynamic> _unwrapData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw ApiException('Respuesta inesperada del servidor');
    }
    return data;
  }
}
