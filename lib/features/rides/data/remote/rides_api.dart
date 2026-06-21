import '../../../../core/http/api_client.dart';
import '../../../../core/http/api_endpoints.dart';

class RidesApi {
  RidesApi(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>> getStats() =>
      _api.get(ApiEndpoints.conductorStats);

  Future<Map<String, dynamic>> getPendingRides() =>
      _api.get(ApiEndpoints.viajesPendientes);

  Future<Map<String, dynamic>> getAssignedRides() =>
      _api.get(ApiEndpoints.viajesAsignados);

  Future<Map<String, dynamic>> acceptRide(String rideId) =>
      _api.post(ApiEndpoints.viajeAceptar(rideId), auth: true);

  Future<Map<String, dynamic>> rejectRide(String rideId) =>
      _api.post(ApiEndpoints.viajeRechazar(rideId), auth: true);

  Future<Map<String, dynamic>> startRide(String rideId) =>
      _api.post(ApiEndpoints.viajeIniciar(rideId), auth: true);

  Future<Map<String, dynamic>> completeRide(String rideId) =>
      _api.post(ApiEndpoints.viajeCompletar(rideId), auth: true);

  Future<Map<String, dynamic>> toggleAvailability() =>
      _api.post(ApiEndpoints.conductorDisponibilidad);

  Future<Map<String, dynamic>> getAvailability() =>
      _api.get(ApiEndpoints.conductorDisponibilidad);
}
