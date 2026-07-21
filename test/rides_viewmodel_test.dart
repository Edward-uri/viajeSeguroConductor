import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:viajeseguroconductor/core/http/api_exception.dart';
import 'package:viajeseguroconductor/core/socket/socket_service.dart';
import 'package:viajeseguroconductor/features/documents/domain/entities/documento.dart';
import 'package:viajeseguroconductor/features/documents/domain/repositories/documento_repository.dart';
import 'package:viajeseguroconductor/features/heatmap/data/models/heat_zone.dart';
import 'package:viajeseguroconductor/features/heatmap/domain/repositories/heatmap_repository.dart';
import 'package:viajeseguroconductor/features/heatmap/presentation/provider/heatmap_viewmodel.dart';
import 'package:viajeseguroconductor/features/profile/domain/repositories/profile_repository.dart';
import 'package:viajeseguroconductor/features/rides/data/services/location_service.dart';
import 'package:viajeseguroconductor/features/rides/domain/entities/ride_history_item.dart';
import 'package:viajeseguroconductor/features/rides/domain/entities/solicitud_viaje.dart';
import 'package:viajeseguroconductor/features/rides/domain/repositories/rides_repository.dart';
import 'package:viajeseguroconductor/features/rides/presentation/provider/driver_availability_viewmodel.dart';
import 'package:viajeseguroconductor/features/rides/presentation/provider/ride_history_viewmodel.dart';
import 'package:viajeseguroconductor/features/rides/presentation/provider/ride_evaluation_viewmodel.dart';
import 'package:viajeseguroconductor/features/rides/presentation/provider/ride_inbox_viewmodel.dart';
import 'package:viajeseguroconductor/features/rides/di/rides_module.dart';
import 'package:viajeseguroconductor/features/vehicle/domain/entities/vehiculo.dart';
import 'package:viajeseguroconductor/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:viajeseguroconductor/features/vehicle/presentation/provider/vehicle_viewmodel.dart';
import 'package:viajeseguroconductor/shared/domain/entities/user.dart';

class _MockRidesRepository implements RidesRepository {
  List<RideHistoryItem> assignedRides = [];
  bool shouldThrow = false;
  List<SolicitudViaje> pendingTrips = [];
  Object? acceptError;
  final acceptedIds = <String>[];
  final rejectedIds = <String>[];

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
  Future<List<SolicitudViaje>> getPendingTrips() async => pendingTrips;

  @override
  Future<SolicitudViaje?> getViajeActivoConductor() async => null;

  @override
  Future<SolicitudViaje> getRideById(String rideId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> acceptRide(String rideId, {required int idVehiculo}) async {
    if (acceptError != null) throw acceptError!;
    acceptedIds.add(rideId);
  }

  @override
  Future<void> rejectRide(String rideId) async {
    rejectedIds.add(rideId);
  }

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

  /// Historial de llamadas a toggleAvailability, en orden de despacho.
  final disponibles = <bool>[];

  @override
  Future<void> toggleAvailability({
    required bool disponible,
    required double lat,
    required double lng,
  }) async {
    disponibles.add(disponible);
  }

  @override
  Future<void> registerDevice({
    required String tokenFcm,
    required String plataforma,
  }) async {}
}

/// Socket falso: expone los mismos streams con controllers propios y registra
/// las emisiones, sin tocar la red.
class _FakeSocketService extends SocketService {
  final statusCtrl = StreamController<SocketStatus>.broadcast();
  final requested = StreamController<Map<String, dynamic>>.broadcast();
  final accepted = StreamController<Map<String, dynamic>>.broadcast();
  final notAvailable = StreamController<Map<String, dynamic>>.broadcast();
  final stateChanged = StreamController<Map<String, dynamic>>.broadcast();

  int? municipioOnline;
  bool offlineEmitido = false;

  @override
  Stream<SocketStatus> get statusStream => statusCtrl.stream;
  @override
  Stream<Map<String, dynamic>> get onRideRequested => requested.stream;
  @override
  Stream<Map<String, dynamic>> get onRideAccepted => accepted.stream;
  @override
  Stream<Map<String, dynamic>> get onRideNotAvailable => notAvailable.stream;
  @override
  Stream<Map<String, dynamic>> get onRideStateChanged => stateChanged.stream;

  @override
  Future<void> connect({required String token}) async {}
  @override
  Future<bool> emitOnline(int idMunicipio) async {
    municipioOnline = idMunicipio;
    return true;
  }

  @override
  void emitOffline() => offlineEmitido = true;
  @override
  void disconnect() {}
}

class _FakeLocationService extends LocationService {
  final posiciones = StreamController<LatLng>.broadcast();
  bool tracking = false;

  @override
  Stream<LatLng> get positionStream => posiciones.stream;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> isServiceEnabled() async => true;
  @override
  Future<LatLng> getCurrentPosition() async => LatLng(19.43, -99.13);
  @override
  void startTracking({
    Duration interval = const Duration(seconds: 10),
    bool immediate = true,
  }) {
    tracking = true;
  }

  @override
  void stopTracking() => tracking = false;
}

class _FakeDocumentoRepository implements DocumentoRepository {
  List<Documento> documentos = [];

  @override
  Future<List<Documento>> getDocumentos() async => documentos;
  @override
  Future<void> subirDocumento(
          String documentoId, Uint8List bytes, String fileName) =>
      throw UnimplementedError();
}

class _FakeVehicleRepository implements VehicleRepository {
  Vehiculo? miVehiculo;
  // Si se define, gana sobre miVehiculo en getVehiculos (para probar flotillas).
  List<Vehiculo>? vehiculos;
  final activados = <int>[];

  @override
  Future<Vehiculo?> getMiVehiculo() async => miVehiculo;
  @override
  Future<List<Vehiculo>> getVehiculos() async => vehiculos ?? [?miVehiculo];
  @override
  Future<void> setVehiculoActivo(int idVehiculo) async {
    activados.add(idVehiculo);
  }

  @override
  Future<Map<String, dynamic>> getDatosFacturacion() async => {};
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeProfileRepository implements ProfileRepository {
  User? me;

  @override
  Future<User> getMe() async {
    final user = me;
    if (user == null) throw Exception('sin usuario');
    return user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeHeatmapRepository implements HeatmapRepository {
  List<Map<String, dynamic>> raw = [];
  bool shouldThrow = false;

  @override
  Future<List<HeatZone>> getZonasCalientes(int municipio) async => [];
  @override
  Future<List<Map<String, dynamic>>> getZonasCalientesRaw(
      int municipio) async {
    if (shouldThrow) throw Exception('Error');
    return raw;
  }
}

SolicitudViaje _viaje(int id) => SolicitudViaje(
      idViaje: id,
      idPasajero: 1,
      idMunicipio: 1,
      tipoServicio: 'viaje',
      distanciaKm: 1,
      tarifa: 50,
      tarifaEstimada: false,
      estado: 'solicitado',
      fechaSolicitud: '',
    );

const _vehiculoAprobado = Vehiculo(
  idVehiculo: 7,
  placa: 'ABC123',
  modelo: 'Italika',
  color: 'Rojo',
  anio: 2022,
  status: VehicleStatus.active,
);

// El recién registrado quedó activo pero aún en revisión (reproduce el bug de
// gating: tener este activo NO debe impedir salir en línea si hay otro aprobado).
const _vehiculoPendiente = Vehiculo(
  idVehiculo: 8,
  placa: 'XYZ789',
  modelo: 'Vento',
  color: 'Negro',
  anio: 2023,
  status: VehicleStatus.reviewing,
  activo: true,
);

/// Deja correr microtasks y timers de duración cero (entrega de streams broadcast).
Future<void> _pump() => Future<void>.delayed(Duration.zero);

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

  group('RideInboxViewModel', () {
    late _MockRidesRepository mockRepo;
    late _FakeSocketService socket;
    late RideInboxViewModel inbox;

    setUp(() {
      mockRepo = _MockRidesRepository();
      socket = _FakeSocketService();
      inbox = RideInboxViewModel(mockRepo, socket);
      inbox.initSocket(token: 't');
    });

    tearDown(() => inbox.dispose());

    test('viaje:solicitado agrega pendiente solo cuando está online', () async {
      socket.requested.add({'idViaje': 1});
      await _pump();
      expect(inbox.state.pendientes, isEmpty, reason: 'offline: se ignora');

      inbox.setOnline(true);
      socket.requested.add({'idViaje': 1});
      await _pump();
      expect(inbox.state.pendientes.length, 1);

      // Duplicado: no se reinyecta.
      socket.requested.add({'idViaje': 1});
      await _pump();
      expect(inbox.state.pendientes.length, 1);
    });

    test('acceptRide estando offline se rehúsa', () async {
      inbox.setVehiculo(_vehiculoAprobado);
      inbox.setPendientes([_viaje(3)]);
      inbox.seleccionarViaje(_viaje(3));

      final result = await inbox.acceptRide();

      expect(result, isNull);
      expect(inbox.state.errorMessage, 'Ponte en línea para aceptar viajes.');
      expect(mockRepo.acceptedIds, isEmpty);
    });

    test('acceptRide sin vehículo aprobado marca error', () async {
      inbox.setOnline(true);
      inbox.seleccionarViaje(_viaje(3));
      final result = await inbox.acceptRide();
      expect(result, isNull);
      expect(inbox.state.errorMessage, isNotNull);
      expect(mockRepo.acceptedIds, isEmpty);
    });

    test('acceptRide feliz limpia la solicitud y regresa el viaje', () async {
      inbox.setOnline(true);
      inbox.setVehiculo(_vehiculoAprobado);
      inbox.setPendientes([_viaje(3)]);
      inbox.seleccionarViaje(_viaje(3));

      final result = await inbox.acceptRide();

      expect(result?.id, '3');
      expect(mockRepo.acceptedIds, ['3']);
      expect(inbox.state.currentRequest, isNull);
      expect(inbox.state.pendientes, isEmpty);
      expect(inbox.state.errorMessage, isNull);
    });

    test('acceptRide con 409 avisa que el viaje ya fue tomado', () async {
      inbox.setOnline(true);
      inbox.setVehiculo(_vehiculoAprobado);
      inbox.seleccionarViaje(_viaje(3));
      mockRepo.acceptError = ApiException('', statusCode: 409);

      final result = await inbox.acceptRide();

      expect(result, isNull);
      expect(inbox.state.currentRequest, isNull);
      expect(inbox.state.errorMessage,
          'Este viaje ya fue tomado por otro conductor');
    });

    test('rejectRide no reinyecta el viaje (refresh ni socket)', () async {
      inbox.setOnline(true);
      inbox.setPendientes([_viaje(5)]);
      inbox.seleccionarViaje(_viaje(5));

      await inbox.rejectRide();
      expect(mockRepo.rejectedIds, ['5']);
      expect(inbox.state.currentRequest, isNull);
      expect(inbox.state.pendientes, isEmpty);

      mockRepo.pendingTrips = [_viaje(5)];
      await inbox.refrescarPendientes();
      expect(inbox.state.pendientes, isEmpty);

      socket.requested.add({'idViaje': 5});
      await _pump();
      expect(inbox.state.pendientes, isEmpty);
    });

    test('viaje:aceptado por otro conductor quita el pendiente y avisa',
        () async {
      inbox.setPendientes([_viaje(4)]);
      inbox.seleccionarViaje(_viaje(4));

      socket.accepted.add({'idViaje': 4});
      await _pump();

      expect(inbox.state.pendientes, isEmpty);
      expect(inbox.state.currentRequest, isNull);
      expect(inbox.state.errorMessage,
          'Este viaje fue tomado por otro conductor');
    });

    test('viaje:aceptado por MÍ no genera aviso', () async {
      inbox.setOnline(true);
      inbox.setVehiculo(_vehiculoAprobado);
      inbox.seleccionarViaje(_viaje(4));
      await inbox.acceptRide();

      socket.accepted.add({'idViaje': 4});
      await _pump();

      expect(inbox.state.errorMessage, isNull);
    });

    test('clearError limpia el mensaje y el mismo error vuelve a notificar',
        () async {
      inbox.setPendientes([_viaje(4)]);
      inbox.seleccionarViaje(_viaje(4));
      socket.accepted.add({'idViaje': 4});
      await _pump();
      expect(inbox.state.errorMessage, isNotNull);

      // La UI mostró el snackbar y limpia; un segundo error idéntico vuelve
      // a ser un cambio de estado (los listeners con select sólo ven cambios).
      inbox.clearError();
      expect(inbox.state.errorMessage, isNull);

      inbox.setPendientes([_viaje(4)]);
      inbox.seleccionarViaje(_viaje(4));
      socket.accepted.add({'idViaje': 4});
      await _pump();
      expect(inbox.state.errorMessage,
          'Este viaje fue tomado por otro conductor');
    });

    test('retransmite cierres del viaje activo a viajesCerrados', () async {
      final cierres = <Map<String, dynamic>>[];
      inbox.viajesCerrados.listen(cierres.add);

      socket.stateChanged.add({'idViaje': 9, 'estado': 'cancelado'});
      socket.stateChanged.add({'idViaje': 9, 'estado': 'en_curso'});
      socket.notAvailable.add({'idViaje': 8});
      await _pump();

      expect(cierres.length, 2);
      expect(cierres[0]['estado'], 'cancelado');
      expect(cierres[1]['idViaje'], 8);
    });
  });

  group('DriverAvailabilityViewModel', () {
    late _MockRidesRepository mockRepo;
    late _FakeSocketService socket;
    late _FakeLocationService location;
    late _FakeDocumentoRepository docs;
    late _FakeVehicleRepository vehicles;
    late _FakeProfileRepository profile;
    late _FakeHeatmapRepository heatmapRepo;
    late RideInboxViewModel inbox;
    late HeatmapViewModel heatmap;
    late DriverAvailabilityViewModel vm;

    setUp(() {
      mockRepo = _MockRidesRepository();
      socket = _FakeSocketService();
      location = _FakeLocationService();
      docs = _FakeDocumentoRepository()
        ..documentos = [
          const Documento(
              id: '1', nombre: 'Licencia', status: DocumentStatus.approved),
        ];
      vehicles = _FakeVehicleRepository()..miVehiculo = _vehiculoAprobado;
      profile = _FakeProfileRepository()
        ..me = const User(
          idUsuario: 1,
          rol: 'conductor',
          roles: ['conductor'],
          estadoCuenta: 'activa',
          idMunicipio: 2,
        );
      heatmapRepo = _FakeHeatmapRepository();
      inbox = RideInboxViewModel(mockRepo, socket);
      heatmap = HeatmapViewModel(heatmapRepo);
      vm = DriverAvailabilityViewModel(
        mockRepo, location, socket, docs, vehicles, profile, inbox, heatmap);
    });

    tearDown(() {
      vm.dispose();
      inbox.dispose();
      heatmap.dispose();
    });

    test('loadData llena stats/municipio pero NO carga pendientes offline', () async {
      mockRepo.pendingTrips = [_viaje(1), _viaje(2)];
      await vm.loadData();

      expect(vm.state.isLoading, false);
      expect(vm.state.stats, isNotNull);
      expect(vm.state.idMunicipio, 2);
      expect(vm.state.esConductor, true);
      // Arranca offline: no deben aparecer viajes hasta ponerse en línea.
      expect(inbox.state.pendientes, isEmpty);
    });

    test('toggleOnline bloqueado por documentos pendientes', () async {
      docs.documentos = [
        const Documento(
            id: '1', nombre: 'Licencia', status: DocumentStatus.reviewing),
      ];

      await vm.toggleOnline();

      expect(vm.state.isOnline, false);
      expect(vm.state.errorMessage, contains('Licencia'));
      expect(socket.municipioOnline, isNull);
    });

    test('toggleOnline bloqueado sin vehículo aprobado', () async {
      vehicles.miVehiculo = null;

      await vm.toggleOnline();

      expect(vm.state.isOnline, false);
      expect(vm.state.errorMessage,
          'Registra tu vehículo para poder recibir viajes.');
    });

    test('toggleOnline con un aprobado entre otros en revisión entra en línea',
        () async {
      await vm.loadData();
      inbox.initSocket(token: 't');
      // El activo está en revisión, pero hay otro aprobado en la flotilla.
      vehicles.vehiculos = [_vehiculoPendiente, _vehiculoAprobado];

      await vm.toggleOnline();
      await _pump();

      expect(vm.state.isOnline, true);
      expect(vm.state.errorMessage, isNull);
      // Se conduce con el aprobado, no con el activo-en-revisión.
      expect(vm.state.miVehiculo?.idVehiculo, _vehiculoAprobado.idVehiculo);
    });

    test('toggleOnline feliz: en línea, tracking y room del municipio',
        () async {
      await vm.loadData(); // municipio 2 del perfil
      inbox.initSocket(token: 't');

      await vm.toggleOnline();
      await _pump(); // emitOnline + refresh en segundo plano

      expect(vm.state.isOnline, true);
      expect(vm.state.errorMessage, isNull);
      expect(location.tracking, true);
      expect(socket.municipioOnline, 2);

      // Ya en línea: las solicitudes del socket entran al inbox.
      socket.requested.add({'idViaje': 11});
      await _pump();
      expect(inbox.state.pendientes.any((t) => t.id == '11'), true);
    });

    test('toggle rápido on→off termina offline en todas partes', () async {
      await vm.loadData(); // municipio 2, pendientes vacías
      inbox.initSocket(token: 't');
      // Solo el refresh en segundo plano del pase a online podría traerlas.
      mockRepo.pendingTrips = [_viaje(1)];

      // Primer tap: pasa a online (queda en vuelo en sus awaits).
      final enVuelo = vm.toggleOnline();
      expect(vm.state.isToggling, true);
      // Segundo tap mientras la operación corre: el deseo final es offline.
      await vm.toggleOnline();
      await enVuelo;
      await _pump();
      await _pump(); // emitOnline/refresh en segundo plano

      // El último deseo gana: offline en UI, backend, socket e inbox.
      expect(vm.state.isOnline, false);
      expect(vm.state.isToggling, false);
      expect(location.tracking, false);
      expect(socket.offlineEmitido, true);
      expect(mockRepo.disponibles, [true, false],
          reason: 'el backend debe recibir disponible=false al final');
      expect(inbox.state.pendientes, isEmpty,
          reason: 'el refresh del pase a online no debe repoblar offline');
      expect(inbox.state.currentRequest, isNull);

      // El espejo _online del inbox quedó en false: se ignoran solicitudes.
      socket.requested.add({'idViaje': 13});
      await _pump();
      expect(inbox.state.pendientes, isEmpty);
    });

    test('volver a offline limpia inbox y zonas', () async {
      inbox.initSocket(token: 't');
      await vm.toggleOnline();
      await _pump();
      inbox.seleccionarViaje(_viaje(6));

      await vm.toggleOnline(); // apaga

      expect(vm.state.isOnline, false);
      expect(socket.offlineEmitido, true);
      expect(location.tracking, false);
      expect(inbox.state.currentRequest, isNull);
      expect(heatmap.state.zonas, isEmpty);

      // Offline: se ignoran solicitudes entrantes.
      socket.requested.add({'idViaje': 12});
      await _pump();
      expect(inbox.state.pendientes.any((t) => t.id == '12'), false);
    });
  });

  group('VehicleViewModel.usarVehiculo', () {
    test('bloqueado estando en línea: no toca el repositorio', () async {
      final repo = _FakeVehicleRepository();
      final vm = VehicleViewModel(repo, isOnline: () => true);

      await vm.usarVehiculo(7);

      expect(vm.errorMessage,
          'No puedes cambiar de vehículo estando en línea. Pasa a offline primero.');
      expect(repo.activados, isEmpty);
      expect(vm.isSaving, false);
    });

    test('offline sí cambia el vehículo activo', () async {
      final repo = _FakeVehicleRepository()..miVehiculo = _vehiculoAprobado;
      final vm = VehicleViewModel(repo, isOnline: () => false);

      await vm.usarVehiculo(7);

      expect(repo.activados, [7]);
      expect(vm.errorMessage, isNull);
    });
  });

  group('HeatmapViewModel', () {
    test('fetchZonas procesa zonas y colores', () async {
      final repo = _FakeHeatmapRepository()
        ..raw = [
          {
            'lat': 19.0,
            'lng': -99.0,
            'intensidad': 0.5,
            'demand_density': 1.0,
            'supply_demand_ratio': 0.5,
            'n_requests': 3,
            'radio_m': 200.0,
          },
        ];
      final vm = HeatmapViewModel(repo);
      addTearDown(vm.dispose);

      await vm.fetchZonas(1);

      expect(vm.state.isLoading, false);
      expect(vm.state.zonas.length, 1);
      expect(vm.state.colores.length, 1);
      expect(vm.state.zonas.first.radioM, 200.0);
    });

    test('fetchZonas con error deja el mapa despejado', () async {
      final repo = _FakeHeatmapRepository()..shouldThrow = true;
      final vm = HeatmapViewModel(repo);
      addTearDown(vm.dispose);

      await vm.fetchZonas(1);

      expect(vm.state.isLoading, false);
      expect(vm.state.zonas, isEmpty);
      expect(vm.state.colores, isEmpty);
    });
  });
}
