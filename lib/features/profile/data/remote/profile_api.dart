import 'dart:typed_data';

import 'package:http_parser/http_parser.dart';

import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class ProfileApi {
  ProfileApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getMe() =>
      _api.get(ApiEndpoints.usersMe, auth: true);

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> data) =>
      _api.put(ApiEndpoints.usersMe, auth: true, body: data);

  /// Sube la foto de perfil al volumen montado: PUT multipart, campo "foto".
  Future<Map<String, dynamic>> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) =>
      _api.multipartPost(
        ApiEndpoints.usersMePhoto,
        method: 'PUT',
        fieldName: 'foto',
        bytes: bytes,
        fileName: fileName,
        contentType: MediaType('image', 'jpeg'),
        auth: true,
      );

  Future<void> deleteAccount() =>
      _api.delete(ApiEndpoints.usersMe, auth: true);

  Future<void> activarPropietario() =>
      _api.post(ApiEndpoints.flotillasPropietariosActivar, auth: true);
}
