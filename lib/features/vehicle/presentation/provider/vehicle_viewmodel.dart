import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/error.dart';
import '../../../../features/rides/presentation/provider/driver_availability_viewmodel.dart';
import '../../../../theme/jala_theme.dart';
import '../../di/vehicle_module.dart';
import '../../domain/entities/vehiculo.dart';
import '../../domain/repositories/vehicle_repository.dart';

final vehicleViewModelProvider =
    ChangeNotifierProvider.autoDispose<VehicleViewModel>((ref) {
  return VehicleViewModel(
    ref.watch(vehicleRepositoryProvider),
    // ref.read puntual (sin dependencia): el shell del home mantiene vivo el
    // provider de disponibilidad mientras el conductor puede estar en línea.
    isOnline: () => ref.read(driverAvailabilityViewModelProvider).isOnline,
  );
});

class VehicleViewModel extends ChangeNotifier {
  VehicleViewModel(this._repository, {bool Function()? isOnline})
      : _isOnline = isOnline ?? (() => false);

  final VehicleRepository _repository;
  final bool Function() _isOnline;

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
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'Error al cargar vehículos');
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
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'No se pudieron guardar los datos de facturación');
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
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'No se pudo registrar el vehículo. Verifica los datos.');
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
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'No se pudo subir el documento. Intenta de nuevo.');
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

  Future<void> usarVehiculo(int idVehiculo) async {
    // El backend no lo valida: cambiar de vehículo en línea dejaría viajes
    // asignados con un vehículo distinto al aprobado para recibirlos.
    if (_isOnline()) {
      _errorMessage =
          'No puedes cambiar de vehículo estando en línea. Pasa a offline primero.';
      notifyListeners();
      return;
    }
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.setVehiculoActivo(idVehiculo);
      await loadVehiculos();
    } catch (e) {
      _errorMessage =
          ErrorHandler.messageFor(e, fallback: 'No se pudo seleccionar el vehículo. Intenta de nuevo.');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
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

  // ponytail: sin BuildContext aquí; se usan las constantes estáticas de marca.
  Color statusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return JalaBrand.success;
      case VehicleStatus.incomplete:
        return JalaBrand.warning;
      case VehicleStatus.reviewing:
        return JalaBrand.warning;
    }
  }
}
