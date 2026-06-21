import 'dart:typed_data';

import '../entities/documento.dart';

abstract class DocumentoRepository {
  Future<List<Documento>> getDocumentos();
  Future<void> subirDocumento(String documentoId, Uint8List bytes, String fileName);
}
