import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:viajeseguroconductor/features/rides/domain/entities/ride_history_item.dart';
import 'package:viajeseguroconductor/features/rides/domain/entities/solicitud_viaje.dart';
import 'package:viajeseguroconductor/features/rides/domain/repositories/rides_repository.dart';
import 'package:viajeseguroconductor/features/rides/presentation/provider/ride_history_viewmodel.dart';
import 'package:viajeseguroconductor/features/rides/presentation/provider/ride_evaluation_viewmodel.dart';
import 'package:viajeseguroconductor/features/rides/di/rides_module.dart';

class _MockRidesRepository implements RidesRepository {
  List<RideHistoryItem> assignedRides = [];
  bool shouldThrow = false;

  @override
  Future<DriverStats> getStats() async => const DriverStats(
        gananciasHoy: 0,
        viajesHoy: 0,
        horasEnLinea: 0,
      );

  @override
  Future<List<RideHistoryItem>> getAssignedRides() async {
    if (shouldThrow) throw Exception('Error');
    return assignedRides;
  }

  @override
  Future<SolicitudViaje?> getCurrentRequest() async => null;

  @override
  Future<List<SolicitudViaje>> getPendingTrips() async => [];

  @override
  Future<SolicitudViaje?> getViajeActivoConductor() async => null;

  @override
  Future<SolicitudViaje> getRideById(String rideId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> acceptRide(String rideId, {required int idVehiculo}) async {}

  @override
  Future<void> rejectRide(String rideId) async {}

  @override
  Future<void> soltarViaje(String rideId) async {}

  @override
  Future<void> startRide(String rideId) async {}

  @override
  Future<void> completeRide(String rideId) async {}

  @override
  Future<void> cancelRide(String rideId, {String? motivo}) async {}

  @override
  Future<void> rateRide(
    String rideId, {
    required int calificacion,
    String? comentario,
  }) async {
    if (shouldThrow) throw Exception('Error');
  }

  @override
  Future<void> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  }) async {}

  @override
  Future<void> registerDevice({
    required String tokenFcm,
    required String plataforma,
  }) async {}
}

void main() {
  group('RideHistoryViewModel', () {
    late _MockRidesRepository mockRepo;

    setUp(() {
      mockRepo = _MockRidesRepository();
    });

    test('initial state', () {
      final vm = RideHistoryViewModel(mockRepo);
      expect(vm.rides, isEmpty);
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.isEmpty, true);
    });

    test('loadHistory carga viajes exitosamente', () async {
      mockRepo.assignedRides = [
        const RideHistoryItem(
          id: '1',
          origen: 'A',
          destino: 'B',
          monto: 50,
          estado: 'completado',
        ),
      ];

      final vm = RideHistoryViewModel(mockRepo);
      expect(vm.isLoading, false);

      await vm.loadHistory();

      expect(vm.isLoading, false);
      expect(vm.rides.length, 1);
      expect(vm.rides.first.id, '1');
      expect(vm.isEmpty, false);
      expect(vm.errorMessage, isNull);
    });

    test('loadHistory maneja error', () async {
      mockRepo.shouldThrow = true;

      final vm = RideHistoryViewModel(mockRepo);
      await vm.loadHistory();

      expect(vm.isLoading, false);
      expect(vm.rides, isEmpty);
      expect(vm.errorMessage, isNotNull);
    });

    test('loadHistory cambia estados loading', () async {
      final vm = RideHistoryViewModel(mockRepo);
      final loadingStates = <bool>[];
      vm.addListener(() => loadingStates.add(vm.isLoading));

      final future = vm.loadHistory();
      expect(vm.isLoading, true);
      await future;
      expect(vm.isLoading, false);
    });
  });

  group('RideEvaluationViewModel', () {
    late _MockRidesRepository mockRepo;

    setUp(() {
      mockRepo = _MockRidesRepository();
    });

    test('initial state', () {
      final vm = RideEvaluationViewModel(mockRepo);
      expect(vm.calificacion, 5);
      expect(vm.comentario, '');
      expect(vm.isSubmitting, false);
      expect(vm.isSubmitted, false);
      expect(vm.errorMessage, isNull);
    });

    test('setCalificacion actualiza estrellas', () {
      final vm = RideEvaluationViewModel(mockRepo);
      vm.setCalificacion(3);
      expect(vm.calificacion, 3);
    });

    test('setComentario actualiza texto', () {
      final vm = RideEvaluationViewModel(mockRepo);
      vm.setComentario('Buen servicio');
      expect(vm.comentario, 'Buen servicio');
    });

    test('submit exitoso marca isSubmitted', () async {
      final vm = RideEvaluationViewModel(mockRepo);
      await vm.submit('123');

      expect(vm.isSubmitted, true);
      expect(vm.isSubmitting, false);
      expect(vm.errorMessage, isNull);
    });

    test('submit con error marca errorMessage', () async {
      mockRepo.shouldThrow = true;
      final vm = RideEvaluationViewModel(mockRepo);

      await vm.submit('123');

      expect(vm.isSubmitted, false);
      expect(vm.isSubmitting, false);
      expect(vm.errorMessage, isNotNull);
    });

    test('submit con comentario vacío no manda cadena vacía', () async {
      final vm = RideEvaluationViewModel(mockRepo);
      await vm.submit('123');

      expect(vm.isSubmitted, true);
    });
  });

  group('RideHistoryViewModel con ProviderScope', () {
    test('loadHistory via provider', () async {
      final mockRepo = _MockRidesRepository();
      mockRepo.assignedRides = [
        const RideHistoryItem(
          id: '1',
          origen: 'Centro',
          destino: 'Norte',
          monto: 35,
          estado: 'completado',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          ridesRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      final vm = container.read(rideHistoryViewModelProvider);
      await vm.loadHistory();

      expect(vm.rides.length, 1);
      expect(vm.rides.first.id, '1');
    });
  });
}
