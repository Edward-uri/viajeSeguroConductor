import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../data/documento_repository_impl.dart';
import '../data/remote/documentos_api.dart';
import '../domain/repositories/documento_repository.dart';

final documentosApiProvider = Provider<DocumentosApi>((ref) {
  return DocumentosApi(ref.watch(apiClientProvider));
});

final documentoRepositoryProvider =
    Provider<DocumentoRepository>((ref) {
  return DocumentoRepositoryImpl(ref.watch(documentosApiProvider));
});
