import '../entities/postulacion.dart';
import '../entities/vacante.dart';

abstract class BolsaRepository {
  /// Vacantes abiertas del municipio del conductor.
  Future<List<Vacante>> getVacantes(int idMunicipio);

  /// Mis postulaciones con su estado (el backend no incluye datos del vehículo aquí).
  Future<List<Postulacion>> getMisPostulaciones();

  /// Lanza ApiException con mensaje del backend:
  /// 409 ya postulaste / vacante cerrada, 403 vacante propia.
  Future<void> postular(int idVacante);

  /// Marca la postulación como 'retirada' (no la borra).
  Future<void> retirarPostulacion(int idPostulacion);

  // ───── Dueño ─────

  /// Mis vacantes (abiertas y cerradas), con conteo de pendientes.
  /// Lanza ApiException con mensaje del backend: 409 ya tiene una abierta
  /// para ese vehículo.
  Future<List<Vacante>> misVacantes();

  Future<void> crearVacante(int idVehiculo, String? condiciones);

  Future<void> cerrarVacante(int idVacante);

  /// Postulaciones de una vacante propia (shape público del conductor).
  /// Lanza ApiException 403 si la vacante no es mía.
  Future<List<Postulacion>> postulacionesDe(int idVacante);

  /// Acepta una postulación pendiente: asigna el vehículo, rechaza las
  /// demás pendientes de esa vacante y la cierra.
  /// Lanza ApiException: 409 no-pendiente/cerrada, 403 ajena.
  Future<void> aceptarPostulacion(int idPostulacion);
}
