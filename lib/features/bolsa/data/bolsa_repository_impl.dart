import '../domain/entities/postulacion.dart';
import '../domain/entities/vacante.dart';
import '../domain/repositories/bolsa_repository.dart';
import 'mappers/bolsa_mapper.dart';
import 'remote/bolsa_api.dart';

class BolsaRepositoryImpl implements BolsaRepository {
  BolsaRepositoryImpl(this._api);

  final BolsaApi _api;

  // Las lecturas NO tragan errores (a diferencia de vehicle): el viewmodel
  // los convierte en SnackBar, requisito de esta pantalla.

  @override
  Future<List<Vacante>> getVacantes(int idMunicipio) async {
    final res = await _api.getVacantes(idMunicipio);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BolsaMapper.vacanteFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Postulacion>> getMisPostulaciones() async {
    final res = await _api.getMisPostulaciones();
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BolsaMapper.postulacionFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> postular(int idVacante) async {
    await _api.postular(idVacante);
  }

  @override
  Future<void> retirarPostulacion(int idPostulacion) async {
    await _api.retirarPostulacion(idPostulacion);
  }

  // ───── Dueño ─────

  @override
  Future<List<Vacante>> misVacantes() async {
    final res = await _api.getMisVacantes();
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BolsaMapper.vacanteFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> crearVacante(int idVehiculo, String? condiciones) async {
    await _api.crearVacante(idVehiculo, condiciones);
  }

  @override
  Future<void> cerrarVacante(int idVacante) async {
    await _api.cerrarVacante(idVacante);
  }

  @override
  Future<List<Postulacion>> postulacionesDe(int idVacante) async {
    final res = await _api.getPostulacionesDeVacante(idVacante);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BolsaMapper.postulacionFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> aceptarPostulacion(int idPostulacion) async {
    await _api.aceptarPostulacion(idPostulacion);
  }
}
