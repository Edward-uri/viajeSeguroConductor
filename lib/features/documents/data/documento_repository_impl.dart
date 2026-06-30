import 'package:flutter/foundation.dart';

import '../../../core/http/api_exception.dart';
import '../domain/entities/documento.dart';
import '../domain/repositories/documento_repository.dart';
import 'mappers/documento_mapper.dart';
import 'remote/documentos_api.dart';

class DocumentoRepositoryImpl implements DocumentoRepository {
  DocumentoRepositoryImpl(this._api);

  final DocumentosApi _api;

  @override
  Future<List<Documento>> getDocumentos() async {
    try {
      return await _fetchDocumentos();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        try {
          await _api.crearConductor();
        } catch (_) {
          debugPrint('[DocumentoRepo] crearConductor falló, retornando defaults');
        }
        return _fetchDocumentos();
      }
      if (e.statusCode == 403) {
        debugPrint('[DocumentoRepo] 403 en conductor endpoints — el token no tiene permisos de conductor');
      }
      rethrow;
    }
  }

  Future<List<Documento>> _fetchDocumentos() async {
    final res = await _api.getDocumentos();
    final docs = res['documentos'] as List<dynamic>? ?? [];
    return docs.map((e) => DocumentoMapper.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> subirDocumento(String documentoId, Uint8List bytes, String fileName) async {
    debugPrint('[DocumentoRepo] subirDocumento("$documentoId")');
    await _api.subirDocumento(
      tipo: documentoId,
      bytes: bytes,
      fileName: fileName,
    );
  }
}
