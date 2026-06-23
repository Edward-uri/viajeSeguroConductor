import '../domain/entities/metodo_cobro.dart';
import '../domain/repositories/metodo_cobro_repository.dart';
import 'mappers/metodo_cobro_mapper.dart';
import 'remote/metodo_cobro_api.dart';

class MetodoCobroRepositoryImpl implements MetodoCobroRepository {
  MetodoCobroRepositoryImpl(this._api);

  final MetodoCobroApi _api;

  @override
  Future<MetodoCobro?> getMetodoCobro() async {
    try {
      final res = await _api.getMetodoCobro();
      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return MetodoCobroMapper.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveMetodoCobro(MetodoCobro metodoCobro) async {
    await _api.saveMetodoCobro(MetodoCobroMapper.toJson(metodoCobro));
  }
}
