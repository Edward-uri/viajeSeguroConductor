import '../../../../routes/app_routes.dart';
import '../../domain/entities/documento.dart';
import '../../domain/repositories/documento_repository.dart';

Future<String> resolveDocumentsRoute(DocumentoRepository repo) async {
  try {
    final docs = await repo.getDocumentos();
    if (docs.every((d) => d.status == DocumentStatus.approved)) {
      return AppRoutes.driverHome;
    }
    if (docs.any((d) => d.status == DocumentStatus.reviewing) &&
        docs.every((d) => d.status != DocumentStatus.pending)) {
      return AppRoutes.documentsReview;
    }
    return AppRoutes.documents;
  } catch (_) {
    return AppRoutes.documents;
  }
}
