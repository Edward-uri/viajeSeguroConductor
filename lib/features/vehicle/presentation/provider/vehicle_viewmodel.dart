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
  String? _rfc;
  String? _razonSocial;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<Vehiculo> get vehiculos => _vehiculos;
  String? get rfc => _rfc;
  String? get razonSocial => _razonSocial;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadVehiculos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getVehiculos(),
        _repository.getDatosFacturacion(),
      ]);
      _vehiculos = results[0] as List<Vehiculo>;
      final facturacion = results[1] as Map<String, dynamic>;
      _rfc = facturacion['rfc']?.toString();
      _razonSocial = facturacion['razonSocial']?.toString();
    } catch (e) {
      _errorMessage = 'Error al cargar vehículos';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> guardarDatosFacturacion({
    required String rfc,
    String? razonSocial,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.guardarDatosFacturacion({
        'rfc': rfc,
        if (razonSocial != null && razonSocial.isNotEmpty)
          'razonSocial': razonSocial,
      });
      _rfc = rfc;
      _razonSocial = razonSocial;
    } catch (e) {
      _errorMessage = 'No se pudieron guardar los datos de facturación';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Registra el vehículo y devuelve su idVehiculo (0 si falló).
  Future<int> registrar(Vehiculo v) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final id = await _repository.registrarVehiculo(v);
      await loadVehiculos();
      return id;
    } catch (e) {
      _errorMessage = 'No se pudo registrar el vehículo. Verifica los datos.';
      return 0;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> subirDocumento({
    required int idVehiculo,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.subirDocumento(
        idVehiculo: idVehiculo,
        tipo: tipo,
        bytes: bytes,
        fileName: fileName,
      );
      await loadVehiculos();
      return true;
    } catch (e) {
      _errorMessage = 'No se pudo subir el documento. Intenta de nuevo.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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
