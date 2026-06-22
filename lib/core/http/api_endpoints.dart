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

  // ───── Rides ─────
  static const String viajesPendientes = '/api/viajes/pendientes';
  static const String viajesAsignados = '/api/viajes/asignados';
  static const String viajesMios = '/api/viajes/mios';
  static String viajeAceptar(String rideId) => '/api/viajes/$rideId/aceptar';
  static String viajeIniciar(String rideId) => '/api/viajes/$rideId/iniciar';
  static String viajeCompletar(String rideId) =>
      '/api/viajes/$rideId/completar';
  static String viajeCancelar(String rideId) =>
      '/api/viajes/$rideId/cancelar';
  static String viajeEvaluacion(String rideId) =>
      '/api/viajes/$rideId/evaluacion';
  static String viajeDetalle(String rideId) => '/api/viajes/$rideId';

  // ───── Flotillas / Vehículos ─────
  static const String flotillasVehiculos = '/api/flotillas/vehiculos';
  static String flotillasVehiculo(String placa) =>
      '/api/flotillas/vehiculos/$placa';
  static String flotillasVehiculoDocumentos(String placa) =>
      '/api/flotillas/vehiculos/$placa/documentos';
  static const String flotillasFacturacion = '/api/flotillas/facturacion';

  // ───── User / Profile ─────
  static const String usersMe = '/api/users/me';
  static const String usersMePhotoPresign = '/api/users/me/photo/presign';
  static const String usersMePhotoConfirm = '/api/users/me/photo/confirm';

  // ───── Tarifas ─────
  static String municipioTarifas(int idMunicipio) =>
      '/api/municipios/$idMunicipio/tarifas';

  // ───── Dispositivos / FCM ─────
  static const String dispositivos = '/api/dispositivos';

  // ───── Shared ─────
  static const String municipios = '/api/municipios';
}
