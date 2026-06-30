import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/documents_module.dart';
import '../../domain/entities/documento.dart';
import '../../domain/repositories/documento_repository.dart';

final documentsViewModelProvider =
    ChangeNotifierProvider.autoDispose<DocumentsViewModel>((ref) {
  return DocumentsViewModel(ref.watch(documentoRepositoryProvider));
});

const _defaultDocumentos = [
  Documento(
    id: 'licencia',
    nombre: 'Licencia de conducir',
    status: DocumentStatus.pending,
  ),
  Documento(
    id: 'ine-frente',
    nombre: 'INE (frente)',
    status: DocumentStatus.pending,
  ),
  Documento(
    id: 'ine-reverso',
    nombre: 'INE (reverso)',
    status: DocumentStatus.pending,
  ),
  // Los documentos del vehículo (tarjeta de circulación, foto) se suben en el
  // alta del vehículo, no aquí. Aquí solo van los documentos personales.
];

class DocumentsViewModel extends ChangeNotifier {
  DocumentsViewModel(this._repository);

  final DocumentoRepository _repository;

  List<Documento> _documentos = List.from(_defaultDocumentos);
  bool _isLoading = false;
  String? _errorMessage;

  List<Documento> get documentos => _documentos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get approvedCount =>
      _documentos.where((d) => d.status == DocumentStatus.approved).length;
  int get totalCount => _documentos.length;

  /// Todos los documentos aprobados: habilita continuar al registro de vehículo.
  bool get allApproved =>
      _documentos.isNotEmpty &&
      _documentos.every((d) => d.status == DocumentStatus.approved);

  /// Algún documento rechazado: hay que avisar al conductor que lo corrija.
  bool get hasRejected =>
      _documentos.any((d) => d.status == DocumentStatus.rejected);

  Future<void> loadDocumentos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final docs = await _repository.getDocumentos();
      _documentos = docs.isEmpty ? List.from(_defaultDocumentos) : docs;
    } catch (_) {
      _documentos = List.from(_defaultDocumentos);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> subirDocumento(String id, Uint8List bytes, String fileName) async {
    debugPrint('[DocumentsVM] subirDocumento id="$id" fileName="$fileName"');
    await _repository.subirDocumento(id, bytes, fileName);
    await loadDocumentos();
  }
}
