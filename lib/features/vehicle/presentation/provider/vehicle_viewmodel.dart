import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/vehicle_module.dart';
import '../../domain/entities/vehiculo.dart';
import '../../domain/repositories/vehicle_repository.dart';

final vehicleViewModelProvider =
    ChangeNotifierProvider.autoDispose<VehicleViewModel>((ref) {
  return VehicleViewModel(ref.watch(vehicleRepositoryProvider));
});

class VehicleViewModel extends ChangeNotifier {
  VehicleViewModel(this._repository);

  final VehicleRepository _repository;

  List<Vehiculo> _vehiculos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Vehiculo> get vehiculos => _vehiculos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadVehiculos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _vehiculos = await _repository.getVehiculos();
    } catch (e) {
      _errorMessage = 'Error al cargar vehículos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registrar(Vehiculo v) async {
    await _repository.registrarVehiculo(v);
    await loadVehiculos();
  }

  Future<void> actualizar(Vehiculo v) async {
    await _repository.actualizarVehiculo(v);
    await loadVehiculos();
  }

  String statusLabel(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return 'Activo';
      case VehicleStatus.incomplete:
        return 'Incompleto';
      case VehicleStatus.reviewing:
        return 'En revisión';
    }
  }

  Color statusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return const Color(0xFF1E8E5A);
      case VehicleStatus.incomplete:
        return const Color(0xFFE8A317);
      case VehicleStatus.reviewing:
        return const Color(0xFFE8A317);
    }
  }
}
