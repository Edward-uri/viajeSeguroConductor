import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../core/http/api_exception.dart';
import '../domain/entities/documento.dart';
import '../domain/repositories/documento_repository.dart';
import 'remote/documentos_api.dart';

const _tipoToNombre = {
  'licencia': 'Licencia de conducir',
  'ine-frente': 'INE (frente)',
  'ine-reverso': 'INE (reverso)',
  'tarjeta-circulacion': 'Tarjeta de circulación',
  'foto-vehiculo': 'Foto del vehículo',
};

class DocumentoRepositoryImpl implements DocumentoRepository {
  DocumentoRepositoryImpl(this._api);

  final DocumentosApi _api;

  @override
  Future<List<Documento>> getDocumentos() async {
    try {
      return await _fetchDocumentos();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _api.crearConductor();
        return _fetchDocumentos();
      }
      rethrow;
    }
  }

  Future<List<Documento>> _fetchDocumentos() async {
    final res = await _api.getDocumentos();
    final docs = res['documentos'] as List<dynamic>? ?? [];
    return docs.map((e) => _mapDocumento(e as Map<String, dynamic>)).toList();
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

  Documento _mapDocumento(Map<String, dynamic> json) {
    final tipo = json['tipo']?.toString() ?? '';
    return Documento(
      id: tipo,
      nombre: _tipoToNombre[tipo] ?? tipo,
      status: _mapStatus(json['estado']?.toString() ?? ''),
      rejectionReason: json['motivoRechazo']?.toString(),
    );
  }

  DocumentStatus _mapStatus(String estado) {
    switch (estado.toLowerCase()) {
      case 'aprobado':
        return DocumentStatus.approved;
      case 'pendiente':
        return DocumentStatus.reviewing;
      case 'rechazado':
        return DocumentStatus.rejected;
      default:
        return DocumentStatus.pending;
    }
  }
}
