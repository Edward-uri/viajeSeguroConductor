import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/core_module.dart';
import '../data/remote/vehiculos_api.dart';
import '../data/vehicle_repository_impl.dart';
import '../domain/repositories/vehicle_repository.dart';

final vehiculosApiProvider = Provider<VehiculosApi>((ref) {
  return VehiculosApi(ref.watch(apiClientProvider));
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(ref.watch(vehiculosApiProvider));
});
