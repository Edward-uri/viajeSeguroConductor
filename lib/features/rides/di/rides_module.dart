import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../data/remote/rides_api.dart';
import '../data/rides_repository_impl.dart';
import '../data/services/location_service.dart';
import '../domain/repositories/rides_repository.dart';

final ridesApiProvider = Provider<RidesApi>((ref) {
  return RidesApi(ref.watch(apiClientProvider));
});

final ridesRepositoryProvider = Provider<RidesRepository>((ref) {
  return RidesRepositoryImpl(ref.watch(ridesApiProvider));
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});
