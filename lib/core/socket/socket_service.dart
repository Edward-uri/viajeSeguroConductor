import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:socket_io_client/socket_io_client.dart';

import '../env/api_config.dart';

enum SocketStatus { disconnected, connecting, connected, unauthorized }

class SocketService {
  SocketService({
    String Function()? tokenProvider,
    Future<bool> Function()? onTokenExpired,
  })  : _tokenProvider = tokenProvider,
        _onTokenExpired = onTokenExpired;

  /// Devuelve el access token vigente (lo cachea ApiClient).
  final String Function()? _tokenProvider;

  /// Pide a ApiClient refrescar la sesión (con sus guards de single-flight
  /// y cooldown). Devuelve true si hay token nuevo.
  final Future<bool> Function()? _onTokenExpired;

  io.Socket? _socket;
  SocketStatus _status = SocketStatus.disconnected;
  Timer? _reconnectTimer;
  Timer? _refreshTimer;
  int _refreshAttempts = 0;
  String? _token;
  bool _shouldReconnect = true;
  int? _municipioOnline;

  final _statusController = StreamController<SocketStatus>.broadcast();
  final _rideRequestedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStateChangedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideNotAvailableController = StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _passengerLocationController = StreamController<Map<String, dynamic>>.broadcast();

  SocketStatus get status => _status;
  Stream<SocketStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get onRideRequested => _rideRequestedController.stream;
  Stream<Map<String, dynamic>> get onRideAccepted => _rideAcceptedController.stream;
  Stream<Map<String, dynamic>> get onRideStateChanged => _rideStateChangedController.stream;
  Stream<Map<String, dynamic>> get onRideNotAvailable => _rideNotAvailableController.stream;
  Stream<Map<String, dynamic>> get onDriverLocation => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get onPassengerLocation => _passengerLocationController.stream;

  bool get isConnected => _status == SocketStatus.connected;

  Future<void> connect({required String token}) async {
    _token = token;
    _shouldReconnect = true;
    _doConnect();
  }

  void _doConnect() {
    _setStatus(SocketStatus.connecting);

    _socket = io.io(
      ApiConfig.baseUrl,
      OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(<String, dynamic>{'token': _token})
          .build(),
    );

    _socket!.onConnect((_) {
      _refreshAttempts = 0;
      _setStatus(SocketStatus.connected);
      // Tras reconectar, el server perdió el room: hay que volver a anunciarse.
      if (_municipioOnline != null) emitOnline(_municipioOnline!);
    });

    _socket!.onDisconnect((_) {
      _setStatus(SocketStatus.disconnected);
      _scheduleReconnect();
    });

    _socket!.onConnectError((data) {
      final msg = data.toString();
      if (msg.contains('unauthorized')) {
        _setStatus(SocketStatus.unauthorized);
        // Token expirado: refresca vía ApiClient y reconecta.
        _tryRefreshAndReconnect();
      } else {
        _setStatus(SocketStatus.disconnected);
        _scheduleReconnect();
      }
    });

    _socket!.on('viaje:solicitado', (data) {
      if (data is Map<String, dynamic>) {
        _rideRequestedController.add(data);
      }
    });

    _socket!.on('viaje:aceptado', (data) {
      if (data is Map<String, dynamic>) {
        _rideAcceptedController.add(data);
      }
    });

    _socket!.on('viaje:cambio_estado', (data) {
      if (data is Map<String, dynamic>) {
        _rideStateChangedController.add(data);
      }
    });

    _socket!.on('viaje:no_disponible', (data) {
      if (data is Map<String, dynamic>) {
        _rideNotAvailableController.add(data);
      }
    });

    _socket!.on('viaje:ubicacion_conductor', (data) {
      if (data is Map<String, dynamic>) {
        _driverLocationController.add(data);
      }
    });

    _socket!.on('viaje:ubicacion_pasajero', (data) {
      if (data is Map<String, dynamic>) {
        _passengerLocationController.add(data);
      }
    });

    _socket!.connect();
  }

  /// Emite conductor:online y resuelve true si el servidor confirmó la unión al
  /// room de su municipio. false si fue rechazado, no hay socket, o timeout.
  Future<bool> emitOnline(int idMunicipio) {
    final socket = _socket;
    if (socket == null) {
      if (kDebugMode) debugPrint('[Socket] emitOnline sin socket conectado');
      return Future.value(false);
    }
    _municipioOnline = idMunicipio;
    final completer = Completer<bool>();
    socket.emitWithAck('conductor:online', {'idMunicipio': idMunicipio}, ack: (data) {
      if (kDebugMode) debugPrint('[Socket] conductor:online ack=$data');
      final ok = data is Map && data['ok'] == true;
      if (!completer.isCompleted) completer.complete(ok);
    });
    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () => false);
  }

  void emitOffline() {
    _municipioOnline = null;
    _socket?.emit('conductor:offline');
  }

  void emitLocation({required int idViaje, required double lat, required double lng}) {
    _socket?.emit('conductor:ubicacion', {
      'idViaje': idViaje,
      'lat': lat,
      'lng': lng,
    });
  }

  Future<void> refreshToken(String newToken) async {
    _token = newToken;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('auth:refresh', {'token': newToken});
    } else {
      _doConnect();
    }
  }

  /// Intenta refrescar el token y reconectar el socket (máx. 5 intentos
  /// entre conexiones exitosas, con debounce de 2 s).
  void _tryRefreshAndReconnect() {
    if (_onTokenExpired == null || _tokenProvider == null) return;
    if (_refreshAttempts >= 5) return;
    _refreshAttempts++;

    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 2), () async {
      final refreshed = await _onTokenExpired();
      if (!refreshed) return;
      final token = _tokenProvider();
      if (token.isEmpty) return;
      refreshToken(token);
    });
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_shouldReconnect && _status != SocketStatus.connected) {
        _doConnect();
      }
    });
  }

  void _setStatus(SocketStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _refreshTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setStatus(SocketStatus.disconnected);
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _rideRequestedController.close();
    _rideAcceptedController.close();
    _rideStateChangedController.close();
    _rideNotAvailableController.close();
    _driverLocationController.close();
    _passengerLocationController.close();
  }
}
