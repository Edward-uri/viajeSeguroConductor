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

  Future<Map<String, dynamic>> getRideById(String rideId) =>
      _api.get(ApiEndpoints.viajeDetalle(rideId), auth: true);

  Future<Map<String, dynamic>> acceptRide(
    String rideId, {
    required int idVehiculo,
  }) =>
      _api.post(
        ApiEndpoints.viajeAceptar(rideId),
        auth: true,
        body: <String, dynamic>{'idVehiculo': idVehiculo},
      );

  Future<Map<String, dynamic>> startRide(String rideId) =>
      _api.post(ApiEndpoints.viajeIniciar(rideId), auth: true);

  Future<Map<String, dynamic>> completeRide(String rideId) =>
      _api.post(ApiEndpoints.viajeCompletar(rideId), auth: true);

  Future<Map<String, dynamic>> cancelRide(
    String rideId, {
    String? motivo,
  }) =>
      _api.post(
        ApiEndpoints.viajeCancelar(rideId),
        auth: true,
        body: motivo != null ? <String, dynamic>{'motivo': motivo} : null,
      );

  Future<Map<String, dynamic>> rateRide(
    String rideId, {
    required int calificacion,
    String? comentario,
  }) =>
      _api.post(
        ApiEndpoints.viajeEvaluacion(rideId),
        auth: true,
        body: <String, dynamic>{
          'calificacion': calificacion,
          if (comentario != null) 'comentario': comentario,
        },
      );

  Future<Map<String, dynamic>> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  }) =>
      _api.post(
        ApiEndpoints.conductorDisponibilidad,
        auth: true,
        body: <String, dynamic>{
          'disponible': disponible,
          'lat': lat,
          'lng': lng,
        },
      );

  Future<Map<String, dynamic>> getAvailability() =>
      _api.get(ApiEndpoints.conductorDisponibilidad);

  Future<Map<String, dynamic>> registerDevice({
    required String tokenFcm,
    required String plataforma,
  }) =>
      _api.post(
        ApiEndpoints.dispositivos,
        auth: true,
        body: <String, dynamic>{
          'tokenFcm': tokenFcm,
          'plataforma': plataforma,
        },
      );
}
