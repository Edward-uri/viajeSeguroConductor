class ApiEndpoints {
  ApiEndpoints._();

  // ───── Auth ─────
  static const String registerStart = '/api/auth/register/start';
  static const String registerVerify = '/api/auth/register/verify';
  static const String registerComplete = '/api/auth/register/complete';
  static const String loginStart = '/api/auth/login/start';
  static const String loginVerify = '/api/auth/login/verify';
  static const String loginPassword = '/api/auth/login/password';
  static const String logout = '/api/auth/logout';
  static const String refresh = '/api/auth/refresh';

  // ───── Conductor / Onboarding ─────
  static const String conductorOnboarding = '/api/conductor/onboarding';
  static const String conductorOnboardingLicencia =
      '/api/conductor/onboarding/licencia';
  static const String conductorDocumentosLicencia =
      '/api/conductor/documentos/licencia';
  static const String conductorDocumentosIneFrente =
      '/api/conductor/documentos/ine-frente';
  static const String conductorDocumentosIneReverso =
      '/api/conductor/documentos/ine-reverso';
  static const String conductorDocumentosTarjetaCirculacion =
      '/api/conductor/documentos/tarjeta-circulacion';
  static const String conductorDocumentosFotoVehiculo =
      '/api/conductor/documentos/foto-vehiculo';

  // ───── Conductor / Stats & Availability ─────
  static const String conductorStats = '/api/conductor/stats';
  static const String conductorDisponibilidad =
      '/api/conductor/disponibilidad';
  static const String conductorMetodoCobro =
      '/api/conductor/metodo-cobro';

  // ───── Rides ─────
  static const String viajesPendientes = '/api/viajes/pendientes';
  static const String viajesAsignados = '/api/viajes/asignados';
  static const String viajesMios = '/api/viajes/mios';
  static String viajeAceptar(String rideId) => '/api/viajes/$rideId/aceptar';
  static String viajeRechazar(String rideId) => '/api/viajes/$rideId/rechazar';
  static String viajeSoltar(String rideId) => '/api/viajes/$rideId/soltar';
  static String viajeIniciar(String rideId) => '/api/viajes/$rideId/iniciar';
  static String viajeCompletar(String rideId) =>
      '/api/viajes/$rideId/completar';
  static String viajeCancelar(String rideId) =>
      '/api/viajes/$rideId/cancelar';
  static String viajeEvaluacion(String rideId) =>
      '/api/viajes/$rideId/evaluacion';
  static String viajeDetalle(String rideId) => '/api/viajes/$rideId';
  static String viajeRuta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) =>
      '/api/viajes/ruta?fromLat=$fromLat&fromLng=$fromLng&toLat=$toLat&toLng=$toLng';

  // ───── Flotillas / Vehículos ─────
  static const String flotillasVehiculos = '/api/flotillas/vehiculos';
  static const String flotillasVehiculoActivo =
      '/api/flotillas/vehiculos/activo';
  static String flotillasVehiculo(String placa) =>
      '/api/flotillas/vehiculos/$placa';
  static String flotillasVehiculoDocumentos(String placa) =>
      '/api/flotillas/vehiculos/$placa/documentos';
  // El backend sube docs del vehículo por idVehiculo y tipo en la ruta:
  // POST /api/flotillas/vehiculos/:id/documentos/{tarjeta-circulacion,foto-vehiculo}
  static String flotillasVehiculoDocumento(int idVehiculo, String tipo) =>
      '/api/flotillas/vehiculos/$idVehiculo/documentos/$tipo';
  static const String flotillasFacturacion = '/api/flotillas/facturacion';
  static const String flotillasPropietariosActivar =
      '/api/flotillas/propietarios/activar';

  // ───── Bolsa de trabajo ─────
  static String bolsaVacantes(int idMunicipio) =>
      '/api/bolsa/vacantes?municipio=$idMunicipio';
  static String bolsaPostular(int idVacante) =>
      '/api/bolsa/vacantes/$idVacante/postular';
  static const String bolsaMisPostulaciones = '/api/bolsa/mis-postulaciones';
  static String bolsaPostulacion(int idPostulacion) =>
      '/api/bolsa/postulaciones/$idPostulacion';

  // ───── Bolsa de trabajo (dueño) ─────
  static const String bolsaCrearVacante = '/api/bolsa/vacantes';
  static const String bolsaMisVacantes = '/api/bolsa/mis-vacantes';
  static String bolsaCerrarVacante(int idVacante) =>
      '/api/bolsa/vacantes/$idVacante/cerrar';
  static String bolsaPostulacionesDeVacante(int idVacante) =>
      '/api/bolsa/vacantes/$idVacante/postulaciones';
  static String bolsaAceptarPostulacion(int idPostulacion) =>
      '/api/bolsa/postulaciones/$idPostulacion/aceptar';

  // ───── User / Profile ─────
  static const String usersMe = '/api/users/me';
  // Subida directa al volumen montado (PUT multipart, campo "foto").
  static const String usersMePhoto = '/api/users/me/photo';
  static String userPhoto(int idUsuario) => '/api/users/$idUsuario/photo';

  // ───── Tarifas ─────
  static String municipioTarifas(int idMunicipio) =>
      '/api/municipios/$idMunicipio/tarifas';

  // ───── Zonas calientes (proxy del modelo, evita CORS) ─────
  static String zonasCalientes(int diaSemana, int hora) =>
      '/api/zonas/calientes?dia_semana=$diaSemana&hora=$hora&top=6';

  // ───── Dispositivos / FCM ─────
  static const String dispositivos = '/api/dispositivos';

  // ───── Shared ─────
  static const String municipios = '/api/municipios';
}
