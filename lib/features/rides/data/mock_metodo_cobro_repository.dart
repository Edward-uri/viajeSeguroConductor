import '../domain/entities/metodo_cobro.dart';
import '../domain/repositories/metodo_cobro_repository.dart';

class MockMetodoCobroRepository implements MetodoCobroRepository {
  MetodoCobro? _saved;

  @override
  Future<MetodoCobro?> getMetodoCobro() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _saved ?? const MetodoCobro(
      tipo: 'transferencia',
      clabe: '1234 5678 9012 3456 7890',
      banco: 'BBVA',
      titular: 'Carlos Méndez',
    );
  }

  @override
  Future<void> saveMetodoCobro(MetodoCobro metodoCobro) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _saved = metodoCobro;
  }
}
