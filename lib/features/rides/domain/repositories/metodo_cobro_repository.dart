import '../entities/metodo_cobro.dart';

abstract class MetodoCobroRepository {
  Future<MetodoCobro?> getMetodoCobro();
  Future<void> saveMetodoCobro(MetodoCobro metodoCobro);
}
