import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../data/bolsa_repository_impl.dart';
import '../data/remote/bolsa_api.dart';
import '../domain/repositories/bolsa_repository.dart';

final bolsaApiProvider = Provider<BolsaApi>((ref) {
  return BolsaApi(ref.watch(apiClientProvider));
});

final bolsaRepositoryProvider = Provider<BolsaRepository>((ref) {
  return BolsaRepositoryImpl(ref.watch(bolsaApiProvider));
});
