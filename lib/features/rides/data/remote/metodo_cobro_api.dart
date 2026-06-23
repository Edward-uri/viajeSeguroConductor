import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class MetodoCobroApi {
  MetodoCobroApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getMetodoCobro() =>
      _api.get(ApiEndpoints.conductorMetodoCobro, auth: true);

  Future<Map<String, dynamic>> saveMetodoCobro(
    Map<String, dynamic> data,
  ) =>
      _api.post(
        ApiEndpoints.conductorMetodoCobro,
        auth: true,
        body: data,
      );
}
