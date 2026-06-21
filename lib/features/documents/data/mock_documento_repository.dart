import 'dart:typed_data';

import '../domain/entities/documento.dart';
import '../domain/repositories/documento_repository.dart';

class MockDocumentoRepository implements DocumentoRepository {
  @override
  Future<List<Documento>> getDocumentos() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      const Documento(
        id: 'licencia',
        nombre: 'Licencia de conducir',
        status: DocumentStatus.approved,
      ),
      const Documento(
        id: 'ine-frente',
        nombre: 'INE (frente)',
        status: DocumentStatus.reviewing,
      ),
      const Documento(
        id: 'ine-reverso',
        nombre: 'INE (reverso)',
        status: DocumentStatus.rejected,
        rejectionReason: 'Foto borrosa, vuelve a subirla',
      ),
      const Documento(
        id: 'tarjeta-circulacion',
        nombre: 'Tarjeta de circulación',
        status: DocumentStatus.pending,
      ),
      const Documento(
        id: 'foto-vehiculo',
        nombre: 'Foto del vehículo',
        status: DocumentStatus.pending,
      ),
    ];
  }

  @override
  Future<void> subirDocumento(String documentoId, Uint8List bytes, String fileName) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}
