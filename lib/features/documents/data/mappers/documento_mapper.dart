import '../../domain/entities/documento.dart';

const _tipoToNombre = {
  'licencia': 'Licencia de conducir',
  'ine-frente': 'INE (frente)',
  'ine-reverso': 'INE (reverso)',
};

class DocumentoMapper {
  const DocumentoMapper._();

  static Documento fromJson(Map<String, dynamic> json) {
    final tipo = (json['tipo']?.toString() ?? '').replaceAll('_', '-');
    return Documento(
      id: tipo,
      nombre: _tipoToNombre[tipo] ?? tipo,
      status: _mapStatus(json['estado']?.toString() ?? ''),
      rejectionReason: json['motivoRechazo']?.toString(),
    );
  }

  static DocumentStatus _mapStatus(String estado) {
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
