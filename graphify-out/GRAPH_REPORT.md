# Graph Report - .  (2026-07-20)

## Corpus Check
- 248 files · ~83,140 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 2505 nodes · 3520 edges · 139 communities (130 shown, 9 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 62 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Socket Service
- Theme System
- API Endpoints
- Job Vacancy System
- Firebase & Messaging
- Socket Service
- Auth Login Flow
- Registration Flow
- Ride Request Entities
- Socket Service
- Driver Ride UI
- Job Vacancy System
- Auth Login Flow
- Theme System
- Job Vacancy System
- Heatmap Feature
- Socket Service
- Socket Service
- Socket Service
- Driver Ride UI
- Job Vacancy System
- Socket Service
- Registration Flow
- Vehicle Management
- Shared UI Widgets
- Ride Request Entities
- Driver Ride UI
- Driver Ride UI
- Auth Dependency Injection
- API Endpoints
- Auth Dependency Injection
- Community 31
- Auth Login Flow
- Auth Dependency Injection
- Job Vacancy System
- User Profile
- Community 36
- Auth Dependency Injection
- Job Vacancy System
- Job Vacancy System
- Firebase & Messaging
- Ride History
- Auth Dependency Injection
- Auth Dependency Injection
- Error Handling
- Error Handling
- Driver Ride UI
- Ride Request Entities
- Job Vacancy System
- Navigation & Routing
- Error Handling
- Community 51
- Job Vacancy System
- Auth Dependency Injection
- Driver Ride UI
- Auth Dependency Injection
- Community 56
- Ride Request Entities
- Vehicle Management
- Auth Login Flow
- Registration Flow
- Community 61
- Job Vacancy System
- Job Vacancy System
- Error Handling
- API Endpoints
- Registration Flow
- Job Vacancy System
- Ride Inbox
- Error Handling
- Auth Login Flow
- Socket Service
- Registration Flow
- Vehicle Management
- Community 74
- Navigation & Routing
- Job Vacancy System
- Community 77
- Registration Flow
- Error Handling
- Job Vacancy System
- Registration Flow
- Document Domain
- Auth Login Flow
- Registration Flow
- Job Vacancy System
- Document Domain
- Theme System
- Community 88
- Design & Documentation
- Community 90
- Socket Service
- Vehicle Management
- Community 93
- Registration Flow
- Heatmap Feature
- Navigation & Routing
- Vehicle Management
- Theme System
- Community 99
- Registration Flow
- User Profile
- Theme System
- Auth Dependency Injection
- User Profile
- Theme System
- Ride Request Entities
- Community 107
- API Endpoints
- API Endpoints
- Socket Service
- Ride Request Entities
- Ride Request Entities
- Firebase & Messaging
- Heatmap Feature
- Community 115
- Community 116
- Community 117
- Community 118
- Community 119
- Job Vacancy System
- Document Domain
- Registration Flow
- Ride Request Entities
- Community 124
- Community 125
- Community 126
- Error Handling
- Community 128
- Community 129
- Community 133
- Community 134
- Community 135
- Community 137
- Community 138

## God Nodes (most connected - your core abstractions)
1. `Jala Passenger App README` - 23 edges
2. `Win32Window` - 22 edges
3. `registerViewModelProvider` - 15 edges
4. `vehicleViewModelProvider` - 12 edges
5. `MessageHandler` - 12 edges
6. `ApiClient` - 11 edges
7. `SocketService` - 11 edges
8. `duenoVacantesViewModelProvider` - 11 edges
9. `documentsViewModelProvider` - 11 edges
10. `RidesRepository` - 11 edges

## Surprising Connections (you probably didn't know these)
- `iOS App Icon 1024x1024 @1x` --semantically_similar_to--> `App Icon (Android Static)`  [INFERRED] [semantically similar]
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png → assets/icon/icon.png
- `macOS App Icon 32px` --semantically_similar_to--> `Web PWA Icon 192px`  [INFERRED] [semantically similar]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png → web/icons/Icon-192.png
- `macOS App Icon 512px` --semantically_similar_to--> `Web PWA Icon 512px`  [INFERRED] [semantically similar]
  macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png → web/icons/Icon-512.png
- `Navigator 1.0 (Named Routes)` --references--> `go_router`  [AMBIGUOUS]
  README.md → pubspec.yaml
- `Driver Ride Evaluation Screen (Figma)` --conceptually_related_to--> `Rides Feature`  [INFERRED]
  docs/figma-designs.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **App Architecture Patterns (Clean + Vertical Slicing + Screaming + MVVM)** — readme_clean_architecture, readme_vertical_slicing, readme_screaming_architecture, readme_mvvm_pattern [EXTRACTED 0.95]
- **Linux Build Chain** — linux_cmakelists_txt_runner_build, linux_flutter_cmakelists_txt_flutter_library, linux_runner_cmakelists_txt_runner_executable [EXTRACTED 1.00]
- **Windows Build Chain** — windows_cmakelists_txt_runner_build, windows_flutter_cmakelists_txt_flutter_library, windows_runner_cmakelists_txt_runner_executable [EXTRACTED 1.00]
- **Trip System Integration (Integration Guide + Rides Feature + Trip States + Socket.IO)** — integracion_apps_viajes_md_viaje_seguro_integration_guide, integracion_apps_viajes_md_trip_state_machine, integracion_apps_viajes_md_socket_io_realtime, integracion_apps_viajes_md_rest_endpoints, readme_feature_rides [INFERRED 0.85]
- **Security Systems (JWT + FLAG_SECURE + Risk Detection + Remote Wipe)** — integracion_apps_viajes_md_jwt_authentication, readme_flag_secure, readme_security_risk_detection, readme_remote_wipe [INFERRED 0.80]

## Communities (139 total, 9 thin omitted)

### Community 0 - "Socket Service"
Cohesion: 0.02
Nodes (85): package:viajeseguroconductor/core/socket/socket_service.dart, package:viajeseguroconductor/features/documents/domain/entities/documento.dart, package:viajeseguroconductor/features/documents/domain/repositories/documento_repository.dart, package:viajeseguroconductor/features/heatmap/data/models/heat_zone.dart, package:viajeseguroconductor/features/heatmap/domain/repositories/heatmap_repository.dart, package:viajeseguroconductor/features/heatmap/presentation/provider/heatmap_viewmodel.dart, package:viajeseguroconductor/features/profile/domain/repositories/profile_repository.dart, package:viajeseguroconductor/features/rides/data/services/location_service.dart (+77 more)

### Community 1 - "Theme System"
Cohesion: 0.06
Nodes (53): PluginRegistry, Point, RECT, Size, unique_ptr, RegisterPlugins(), DartProject, HWND (+45 more)

### Community 2 - "API Endpoints"
Cohesion: 0.04
Nodes (54): ApiEndpoints, bolsaAceptarPostulacion, bolsaCerrarVacante, bolsaCrearVacante, bolsaMisPostulaciones, bolsaMisVacantes, bolsaPostulacion, bolsaPostulacionesDeVacante (+46 more)

### Community 3 - "Job Vacancy System"
Cohesion: 0.05
Nodes (47): Color, ConsumerWidget, ReputationChips, Vacante, duenoVacantesViewModelProvider, build, color, _confirmandoCierre (+39 more)

### Community 4 - "Firebase & Messaging"
Cohesion: 0.05
Nodes (33): Any, Cocoa, file_selector_macos, firebase_core, firebase_messaging, Flutter, flutter_secure_storage_macos, FlutterAppDelegate (+25 more)

### Community 5 - "Socket Service"
Cohesion: 0.05
Nodes (45): ColorScheme, dart:math, Duration?, ../../../heatmap/presentation/provider/heatmap_viewmodel.dart, deviceRegistrationServiceProvider, heatmapViewModelProvider, driverAvailabilityViewModelProvider, build (+37 more)

### Community 6 - "Auth Login Flow"
Cohesion: 0.07
Nodes (46): Driver Ride Evaluation Screen (Figma), Driver Ride In Progress Screen (Figma), Jala Design System Colors, API Error Codes, FCM Push Token Registration, JWT Authentication, OTP Login Flow, Password Login (+38 more)

### Community 7 - "Registration Flow"
Cohesion: 0.06
Nodes (42): Exception, ../http/api_exception.dart, int?, AppError, ConflictAppError, details, ErrorHandler, _fromApiException (+34 more)

### Community 8 - "Ride Request Entities"
Cohesion: 0.05
Nodes (42): double? get, calificacion, canceladoPor, destino, destinoLat, destinoLng, destinoTexto, distanciaKm (+34 more)

### Community 9 - "Socket Service"
Cohesion: 0.05
Nodes (42): ../../../../features/documents/di/documents_module.dart, ../../../../features/documents/domain/entities/documento.dart, ../../../../features/documents/domain/repositories/documento_repository.dart, ../../../../features/heatmap/presentation/provider/heatmap_viewmodel.dart, ../../../../features/profile/di/profile_module.dart, ../../../../features/profile/domain/repositories/profile_repository.dart, ../../../../features/vehicle/di/vehicle_module.dart, ../../../../features/vehicle/domain/repositories/vehicle_repository.dart (+34 more)

### Community 10 - "Driver Ride UI"
Cohesion: 0.05
Nodes (42): _BottomSheet, _LandscapeBottomBar, _PendingTrips, _RouteLine, _TripCard, active, _anioController, _buildStep (+34 more)

### Community 11 - "Job Vacancy System"
Cohesion: 0.05
Nodes (41): app_routes.dart, ../features/auth/presentation/screens/login_screen.dart, ../features/auth/presentation/screens/registration/getstarted_screen.dart, ../features/auth/presentation/screens/registration/register_email_screen.dart, ../features/auth/presentation/screens/registration/register_municipio_screen.dart, ../features/auth/presentation/screens/registration/register_names_screen.dart, ../features/auth/presentation/screens/registration/register_otp_screen.dart, ../features/auth/presentation/screens/registration/register_personal_data_screen.dart (+33 more)

### Community 12 - "Auth Login Flow"
Cohesion: 0.07
Nodes (39): ../../auth/di/auth_module.dart, ../../../../core/widgets/gradient_button.dart, ../../../core/widgets/logo_badge.dart, ../../di/auth_module.dart, sessionServiceProvider, loginPasswordViewModelProvider, upgradePropietarioViewModelProvider, build (+31 more)

### Community 13 - "Theme System"
Cohesion: 0.05
Nodes (41): accentBlue, accentBlueDark, accentSurface, accentSurfaceDark, amber, amberDeep, amberLight, cream (+33 more)

### Community 14 - "Job Vacancy System"
Cohesion: 0.05
Nodes (38): double?, conductorCalificacion, conductorFotoUrl, conductorNombre, estado, EstadoPostulacion, EstadoPostulacionUi, estadoVacante (+30 more)

### Community 15 - "Heatmap Feature"
Cohesion: 0.05
Nodes (36): dart:ui, ../../data/models/heat_zone.dart, ../../di/heatmap_module.dart, ../../domain/repositories/heatmap_repository.dart, int? get, _api, _diaSemana, getZonasCalientes (+28 more)

### Community 16 - "Socket Service"
Cohesion: 0.05
Nodes (38): connect, disconnect, dispose, _doConnect, _driverLocationController, emitLocation, emitOffline, emitOnline (+30 more)

### Community 17 - "Socket Service"
Cohesion: 0.06
Nodes (33): core/messaging/messaging_globals.dart, ../../../../core/socket/socket_module.dart, dart:async, dart:io, ../data/auth_repository_impl.dart, ../data/auth_session_service.dart, ../data/device_registration_service.dart, ../data/platform/mock_location_detector_impl.dart (+25 more)

### Community 18 - "Socket Service"
Cohesion: 0.05
Nodes (37): ../../data/mappers/solicitud_viaje_mapper.dart, ../../../../features/vehicle/domain/entities/vehiculo.dart, acceptRide, _aceptadosPorMi, clearError, copyWith, currentRequest, dispose (+29 more)

### Community 19 - "Driver Ride UI"
Cohesion: 0.06
Nodes (33): ../../di/rides_module.dart, ../../domain/entities/ride_history_item.dart, ../../domain/repositories/rides_repository.dart, DriverStats? get, fromJson, RideHistoryMapper, RidesRepositoryImpl, RidesRepository (+25 more)

### Community 20 - "Job Vacancy System"
Cohesion: 0.06
Nodes (35): AppRoutes, bolsa, documents, documentsApproved, documentsReview, documentUpload, documentView, driverHome (+27 more)

### Community 21 - "Socket Service"
Cohesion: 0.06
Nodes (33): _canceladoPorPasajero, _cargarDetalle, _cierreSub, completeRide, _currentPosition, dispose, _errorMessage, _etaMin (+25 more)

### Community 22 - "Registration Flow"
Cohesion: 0.06
Nodes (32): _apellidoMaterno, _apellidoPaterno, clearError, completeRegistration, _email, _errorMessage, _fechaNacimiento, _idMunicipio (+24 more)

### Community 23 - "Vehicle Management"
Cohesion: 0.08
Nodes (30): build, vehicleViewModelProvider, activo, build, createState, descripcion, initState, isSaving (+22 more)

### Community 24 - "Shared UI Widgets"
Cohesion: 0.06
Nodes (31): asset, autoLocate, build, _circleManager, createState, _currentPosition, didChangeAppLifecycleState, dispose (+23 more)

### Community 25 - "Ride Request Entities"
Cohesion: 0.06
Nodes (29): BuildContext, Color get, ColorScheme get, JalaSemantic get, accentBlue, accentSurface, brand, BuildContextThemeX (+21 more)

### Community 26 - "Driver Ride UI"
Cohesion: 0.06
Nodes (30): CircleAnnotationManager?, _avanceTexto, _avisarCancelado, _buildBottomSheet, _buildHeader, _buildMap, createState, _drawRoute (+22 more)

### Community 27 - "Driver Ride UI"
Cohesion: 0.06
Nodes (28): ../../domain/entities/solicitud_viaje.dart, DriverStatsMapper, fromJson, _extractOrigenDestino, fromJson, SolicitudViajeMapper, acceptRide, _api (+20 more)

### Community 28 - "Auth Dependency Injection"
Cohesion: 0.08
Nodes (25): Animation, AnimationController, accent, createState, detalle, dispose, _entrada, _filas (+17 more)

### Community 29 - "API Endpoints"
Cohesion: 0.07
Nodes (28): api_endpoints.dart, api_exception.dart, ../env/api_config.dart, _authStorage, baseUrl, _buildHeaders, _cachedToken, _client (+20 more)

### Community 30 - "Auth Dependency Injection"
Cohesion: 0.07
Nodes (25): IconData, build, GradientButton, height, icon, isLoading, label, onPressed (+17 more)

### Community 31 - "Community 31"
Cohesion: 0.09
Nodes (22): FlPluginRegistry, FlView, GApplication, gboolean, gchar, GObject, GtkApplication, fl_register_plugins() (+14 more)

### Community 32 - "Auth Login Flow"
Cohesion: 0.08
Nodes (23): ../../../../core/error/error.dart, debugDumpSensitiveData, estado, clearError, _email, _errorMessage, _isLoading, login (+15 more)

### Community 33 - "Auth Dependency Injection"
Cohesion: 0.08
Nodes (23): ../../../../core/security/sensitive_data_processor.dart, ../../../../core/storage/sensitive_data_storage.dart, hasSession, logout, SessionService, AuthSessionService, _dataFingerprint, deleteAccount (+15 more)

### Community 34 - "Job Vacancy System"
Cohesion: 0.10
Nodes (21): class, ConsumerStatefulWidget, AppNavigator, goToLogin, _VacanteCard, createState, DocumentsApprovedScreen, _DocumentsApprovedScreenState (+13 more)

### Community 35 - "User Profile"
Cohesion: 0.09
Nodes (22): ../../domain/entities/update_profile_params.dart, ../entities/update_profile_params.dart, activarPropietario, _api, deleteAccount, getMe, ProfileRepositoryImpl, _unwrapData (+14 more)

### Community 36 - "Community 36"
Cohesion: 0.09
Nodes (22): DateTime?, apellidoMaterno, apellidoPaterno, copyWith, correoElectronico, esConductor, esPasajero, esPropietario (+14 more)

### Community 37 - "Auth Dependency Injection"
Cohesion: 0.09
Nodes (21): app.dart, core/messaging/background_message_handler.dart, core/navigation/app_navigator.dart, core/security/remote_wipe_handler.dart, core/storage/secure_auth_storage.dart, core/storage/secure_sensitive_data_storage.dart, core/storage/sensitive_data_debug.dart, core/storage/sensitive_data_seeder.dart (+13 more)

### Community 38 - "Job Vacancy System"
Cohesion: 0.10
Nodes (20): ../data/bolsa_repository_impl.dart, ../data/remote/bolsa_api.dart, ../../domain/repositories/bolsa_repository.dart, aceptarPostulacion, _api, BolsaRepositoryImpl, cerrarVacante, crearVacante (+12 more)

### Community 39 - "Job Vacancy System"
Cohesion: 0.10
Nodes (20): ../../di/bolsa_module.dart, ../../domain/entities/postulacion.dart, ../../domain/entities/vacante.dart, BolsaMapper, _mapEstado, postulacionFromJson, vacanteFromJson, _errorMessage (+12 more)

### Community 40 - "Firebase & Messaging"
Cohesion: 0.11
Nodes (18): getDeviceToken, initialize, _maskToken, _onMessage, _sensitiveStorage, topicForUser, _wipeHandler, _authStorage (+10 more)

### Community 41 - "Ride History"
Cohesion: 0.11
Nodes (18): @Deprecated, ../entities/ride_history_item.dart, ../entities/solicitud_viaje.dart, acceptRide, cancelRide, completeRide, getAssignedRides, getCurrentRequest (+10 more)

### Community 42 - "Auth Dependency Injection"
Cohesion: 0.11
Nodes (17): @pragma, Client, firebase_options.dart, ../http/api_client.dart, apiClientProvider, client, sensitiveDataStorageProvider, firebaseMessagingBackgroundHandler (+9 more)

### Community 43 - "Auth Dependency Injection"
Cohesion: 0.11
Nodes (16): ../../core/di/core_module.dart, ../data/heatmap_repository_impl.dart, ../data/profile_repository_impl.dart, ../data/remote/heatmap_api.dart, ../data/remote/profile_api.dart, ../../domain/repositories/profile_repository.dart, heatmapApiProvider, heatmapRepositoryProvider (+8 more)

### Community 44 - "Error Handling"
Cohesion: 0.13
Nodes (18): editProfileViewModelProvider, _apellidoMaternoController, _apellidoPaternoController, build, _correoController, createState, dispose, EditProfileScreen (+10 more)

### Community 45 - "Error Handling"
Cohesion: 0.12
Nodes (16): ../../../core/http/api_exception.dart, ../data/documento_repository_impl.dart, ../data/remote/documentos_api.dart, ../../domain/repositories/documento_repository.dart, _api, DocumentoRepositoryImpl, _fetchDocumentos, getDocumentos (+8 more)

### Community 46 - "Driver Ride UI"
Cohesion: 0.11
Nodes (17): ../../di/vehicle_module.dart, ../../../../features/rides/presentation/provider/driver_availability_viewmodel.dart, actualizar, _errorMessage, guardarDatosFacturacion, _isLoading, _isSaving, loadVehiculos (+9 more)

### Community 47 - "Ride Request Entities"
Cohesion: 0.11
Nodes (16): ApiConfig, baseUrl, requestTimeout, uploadTimeout, android, DefaultFirebaseOptions, ios, macos (+8 more)

### Community 48 - "Job Vacancy System"
Cohesion: 0.13
Nodes (17): bolsaViewModelProvider, BolsaScreen, _BolsaScreenState, build, color, createState, _EstadoChip, initState (+9 more)

### Community 49 - "Navigation & Routing"
Cohesion: 0.13
Nodes (17): documentsViewModelProvider, _upload, build, initState, build, createState, doc, _DocCard (+9 more)

### Community 50 - "Error Handling"
Cohesion: 0.12
Nodes (17): build, createState, _detectedExt, _detectExtension, DocumentUploadScreen, _DocumentUploadScreenState, _fileBytes, _formatError (+9 more)

### Community 51 - "Community 51"
Cohesion: 0.12
Nodes (16): _allKeys, clear, _emailKey, isEmpty, _phoneKey, readEmail, readPhone, readSessionToken (+8 more)

### Community 52 - "Job Vacancy System"
Cohesion: 0.12
Nodes (16): aceptarPostulacion, cerrarVacante, crearVacante, _errorMessage, _isLoading, _isWorking, load, loadPostulaciones (+8 more)

### Community 53 - "Auth Dependency Injection"
Cohesion: 0.14
Nodes (16): driverProfileViewModelProvider, createState, _divider, DriverProfileScreen, _DriverProfileScreenState, _estadoColor, _estadoLabel, _initials (+8 more)

### Community 54 - "Driver Ride UI"
Cohesion: 0.14
Nodes (16): DriverStats, earningsViewModelProvider, build, createState, destino, _EarningRow, _EarningsHeader, EarningsScreen (+8 more)

### Community 55 - "Auth Dependency Injection"
Cohesion: 0.15
Nodes (15): ../../core/env/api_config.dart, Future, authStorageProvider, httpClientProvider, AuthedImage, _AuthedImageState, build, _bytes (+7 more)

### Community 56 - "Community 56"
Cohesion: 0.12
Nodes (15): LatLng?, LatLng? get, _controller, dispose, getCurrentPosition, isServiceEnabled, _lastKnown, positionStream (+7 more)

### Community 57 - "Ride Request Entities"
Cohesion: 0.12
Nodes (15): acceptRide, _api, cancelRide, completeRide, getAssignedRides, getAvailability, getPendingRides, getRideById (+7 more)

### Community 58 - "Vehicle Management"
Cohesion: 0.12
Nodes (15): activo, anio, aprobado, color, idMunicipio, idVehiculo, marca, modelo (+7 more)

### Community 59 - "Auth Login Flow"
Cohesion: 0.13
Nodes (14): ../../domain/repositories/auth_repository.dart, _api, guardarLicencia, hasSession, loginPassword, loginStart, loginVerify, logout (+6 more)

### Community 60 - "Registration Flow"
Cohesion: 0.15
Nodes (13): build, createState, RegisterMunicipioScreen, _RegisterMunicipioScreenState, _selected, _datosStep, municipiosProvider, estado (+5 more)

### Community 61 - "Community 61"
Cohesion: 0.14
Nodes (14): approved, approvedCount, createState, doc, _DocumentCard, DocumentsListScreen, _DocumentsListScreenState, iconBgColor (+6 more)

### Community 62 - "Job Vacancy System"
Cohesion: 0.13
Nodes (11): package:flutter_test/flutter_test.dart, package:viajeseguroconductor/core/error/app_error.dart, package:viajeseguroconductor/core/http/api_exception.dart, package:viajeseguroconductor/features/bolsa/data/mappers/bolsa_mapper.dart, package:viajeseguroconductor/features/bolsa/domain/entities/postulacion.dart, package:viajeseguroconductor/features/vehicle/data/mappers/vehiculo_mapper.dart, package:viajeseguroconductor/shared/data/mappers/user_mapper.dart, main (+3 more)

### Community 63 - "Job Vacancy System"
Cohesion: 0.15
Nodes (13): ConsumerState, _VacanteCardState, _anioController, build, _colorController, createState, dispose, initState (+5 more)

### Community 64 - "Error Handling"
Cohesion: 0.14
Nodes (13): ../../di/documents_module.dart, allApproved, approvedCount, _defaultDocumentos, _documentos, DocumentsViewModel, _errorMessage, hasRejected (+5 more)

### Community 65 - "API Endpoints"
Cohesion: 0.14
Nodes (13): ../http/api_endpoints.dart, api, build, _chip, data, EtiquetaReputacion, etiquetasReputacionProvider, fromJson (+5 more)

### Community 66 - "Registration Flow"
Cohesion: 0.16
Nodes (13): build, _bytes, createState, _pick, RegisterPhotoScreen, _RegisterPhotoScreenState, _subiendo, _subir (+5 more)

### Community 67 - "Job Vacancy System"
Cohesion: 0.15
Nodes (12): bool get, abierta, anio, color, condiciones, estado, idMunicipio, idVacante (+4 more)

### Community 68 - "Ride Inbox"
Cohesion: 0.19
Nodes (12): ../../../../core/widgets/reputation_chips.dart, rideInboxViewModelProvider, _aceptando, build, _countdown, createState, initState, _locationRow (+4 more)

### Community 69 - "Error Handling"
Cohesion: 0.15
Nodes (12): ../../di/profile_module.dart, _apellidoMaterno, _apellidoPaterno, canSubmit, _errorMessage, _isLoading, _nombre, _profileRepo (+4 more)

### Community 70 - "Auth Login Flow"
Cohesion: 0.15
Nodes (12): ../entities/register_params.dart, AuthRepositoryImpl, AuthRepository, guardarLicencia, hasSession, loginPassword, loginStart, loginVerify (+4 more)

### Community 71 - "Socket Service"
Cohesion: 0.22
Nodes (13): Equatable, SocketService, HeatmapState, HeatmapViewModel, DriverAvailabilityState, DriverAvailabilityViewModel, RideInboxState, RideInboxViewModel (+5 more)

### Community 72 - "Registration Flow"
Cohesion: 0.17
Nodes (12): _controllers, createState, dispose, _focusNodes, initState, _onContinue, _onDigitChange, RegisterOtpScreen (+4 more)

### Community 73 - "Vehicle Management"
Cohesion: 0.15
Nodes (12): actualizarVehiculo, _api, eliminarVehiculo, getDatosFacturacion, getMiVehiculo, getVehiculos, guardarDatosFacturacion, registrarVehiculo (+4 more)

### Community 74 - "Community 74"
Cohesion: 0.17
Nodes (11): dart:convert, computeDataFingerprint, debugLogSanitized, isValidEmail, isValidMexicanPhone, maskEmail, maskPhone, maskString (+3 more)

### Community 75 - "Navigation & Routing"
Cohesion: 0.17
Nodes (11): ../data/remote/rides_api.dart, ../data/rides_repository_impl.dart, ../../data/services/location_service.dart, ../../data/services/route_service.dart, RidesApi, LocationService, locationServiceProvider, ridesApiProvider (+3 more)

### Community 76 - "Job Vacancy System"
Cohesion: 0.17
Nodes (11): ../entities/postulacion.dart, ../entities/vacante.dart, aceptarPostulacion, cerrarVacante, crearVacante, getMisPostulaciones, getVacantes, misVacantes (+3 more)

### Community 77 - "Community 77"
Cohesion: 0.24
Nodes (9): _In_, _In_opt_, vector, wWinMain(), string, wchar_t, CreateAndAttachConsole(), GetCommandLineArguments() (+1 more)

### Community 78 - "Registration Flow"
Cohesion: 0.18
Nodes (11): _bdayController, build, createState, dispose, _onContinue, _pickDate, RegisterPersonalDataScreen, _RegisterPersonalDataScreenState (+3 more)

### Community 79 - "Error Handling"
Cohesion: 0.17
Nodes (11): _errorMessage, _isLoading, _isUploadingPhoto, loadData, logout, _profileRepo, _sessionService, updateProfile (+3 more)

### Community 80 - "Job Vacancy System"
Cohesion: 0.18
Nodes (11): ChangeNotifier, RegisterViewModel, UpgradePropietarioViewModel, BolsaViewModel, DuenoVacantesViewModel, DriverProfileViewModel, EditProfileViewModel, ProfileViewModel (+3 more)

### Community 81 - "Registration Flow"
Cohesion: 0.18
Nodes (9): core/messaging/firebase_push_messaging_service.dart, FirebasePushMessagingService, initialize, PushMessagingService, DeviceRegistrationService, _messaging, registerCurrentDevice, _repository (+1 more)

### Community 82 - "Document Domain"
Cohesion: 0.18
Nodes (10): ../entities/vehiculo.dart, actualizarVehiculo, eliminarVehiculo, getDatosFacturacion, getMiVehiculo, getVehiculos, guardarDatosFacturacion, registrarVehiculo (+2 more)

### Community 83 - "Auth Login Flow"
Cohesion: 0.18
Nodes (10): _api, AuthApi, guardarLicencia, loginPassword, loginStart, loginVerify, logout, registerComplete (+2 more)

### Community 84 - "Registration Flow"
Cohesion: 0.20
Nodes (10): _confirmController, createState, dispose, _emailController, initState, _obscureConfirm, _obscurePassword, _passwordController (+2 more)

### Community 85 - "Job Vacancy System"
Cohesion: 0.18
Nodes (10): aceptarPostulacion, _api, cerrarVacante, crearVacante, getMisPostulaciones, getMisVacantes, getPostulacionesDeVacante, getVacantes (+2 more)

### Community 86 - "Document Domain"
Cohesion: 0.18
Nodes (10): Documento, DocumentStatus, fileName, fileUrl, id, nombre, optional, rejectionReason (+2 more)

### Community 87 - "Theme System"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 88 - "Community 88"
Cohesion: 0.29
Nodes (10): Launcher Foreground Icon (hdpi), Launcher Foreground Icon (mdpi), Launcher Foreground Icon (xhdpi), Launcher Foreground Icon (xxhdpi), Launcher Foreground Icon (xxxhdpi), App Launcher Icon (hdpi), App Launcher Icon (mdpi), App Launcher Icon (xhdpi) (+2 more)

### Community 89 - "Design & Documentation"
Cohesion: 0.27
Nodes (10): Ride In Progress UI Design Mockup, Adaptive Icon Foreground Layer (Motorcycle with Shield), App Icon (Android Static), Viaje Seguro Logo (Motorcycle with Shield), iOS App Icon 1024x1024 @1x, iOS App Icon 20x20 @1x, iOS App Icon 20x20 @2x, iOS App Icon 20x20 @3x (+2 more)

### Community 90 - "Community 90"
Cohesion: 0.20
Nodes (9): auth_storage.dart, FlutterSecureStorage, _accessTokenKey, clear, readAccessToken, readRefreshToken, _refreshTokenKey, _storage (+1 more)

### Community 91 - "Socket Service"
Cohesion: 0.20
Nodes (9): ../../../../core/session/session_service.dart, ../../../../core/socket/socket_service.dart, ../../../core/storage/auth_storage.dart, _api, hasSession, logout, _socketService, _storage (+1 more)

### Community 92 - "Vehicle Management"
Cohesion: 0.20
Nodes (9): ../data/remote/vehiculos_api.dart, ../data/vehicle_repository_impl.dart, ../../domain/repositories/vehicle_repository.dart, VehiculosApi, VehicleRepositoryImpl, vehicleRepositoryProvider, vehiculosApiProvider, VehicleRepository (+1 more)

### Community 93 - "Community 93"
Cohesion: 0.20
Nodes (10): AppIcon 29x29 @3x, AppIcon 40x40 @1x, AppIcon 40x40 @2x, AppIcon 40x40 @3x, AppIcon 60x60 @2x, AppIcon 60x60 @3x, AppIcon 76x76 @1x, AppIcon 76x76 @2x (+2 more)

### Community 94 - "Registration Flow"
Cohesion: 0.22
Nodes (9): _apellidosController, build, createState, dispose, initState, _nombreController, RegisterNamesScreen, _RegisterNamesScreenState (+1 more)

### Community 95 - "Heatmap Feature"
Cohesion: 0.20
Nodes (9): demandDensity, fromJson, HeatZone, intensidad, lat, lng, nRequests, radioM (+1 more)

### Community 96 - "Navigation & Routing"
Cohesion: 0.20
Nodes (9): _api, distanciaKm, duracionMin, obtenerRuta, points, RouteResult, RouteService, List (+1 more)

### Community 97 - "Vehicle Management"
Cohesion: 0.20
Nodes (9): actualizarVehiculo, _api, eliminarVehiculo, getDatosFacturacion, getVehiculos, guardarDatosFacturacion, registrarVehiculo, setVehiculoActivo (+1 more)

### Community 98 - "Theme System"
Cohesion: 0.25
Nodes (8): build, JalaApp, _pickThemeMode, themeModeProvider, package:device_preview/device_preview.dart, ../../routes/app_router.dart, ../../theme/jala_theme.dart, ../../../../theme/theme_mode_provider.dart

### Community 99 - "Community 99"
Cohesion: 0.22
Nodes (8): clear, isEmpty, readEmail, readPhone, readSessionToken, readUserId, readUsername, writeAll

### Community 100 - "Registration Flow"
Cohesion: 0.22
Nodes (9): registerViewModelProvider, build, _onContinue, _onContinue, _onContinue, build, AppRoutes.registerOtp, AppRoutes.registerPersonalData (+1 more)

### Community 101 - "User Profile"
Cohesion: 0.22
Nodes (8): activarPropietario, _api, deleteAccount, getMe, ProfileApi, updateMe, uploadPhoto, package:http_parser/http_parser.dart

### Community 102 - "Theme System"
Cohesion: 0.22
Nodes (8): _key, _load, setMode, _storage, ThemeModeNotifier, package:flutter_secure_storage/flutter_secure_storage.dart, static const, ThemeMode

### Community 103 - "Auth Dependency Injection"
Cohesion: 0.29
Nodes (8): GetstartedScreen, _GetstartedScreenState, JalaMapView, _JalaMapViewState, SingleTickerProviderStateMixin, State, StatefulWidget, WidgetsBindingObserver

### Community 104 - "User Profile"
Cohesion: 0.25
Nodes (7): apellidoMaterno, apellidoPaterno, nombre, nombreUsuario, telefono, toJson, UpdateProfileParams

### Community 105 - "Theme System"
Cohesion: 0.25
Nodes (7): baseTextTheme, bodyTextTheme, createTextTheme, displayTextTheme, textTheme, package:google_fonts/google_fonts.dart, TextTheme

### Community 106 - "Ride Request Entities"
Cohesion: 0.36
Nodes (8): Linux Runner CMake Build, Linux Flutter Library Build, Linux Runner Executable Build, viajeseguroconductor Project Config, Web Entry Point (index.html), Windows Runner CMake Build, Windows Flutter Library Build, Windows Runner Executable Build

### Community 107 - "Community 107"
Cohesion: 0.32
Nodes (8): macOS App Icon 32px, macOS App Icon 512px, macOS App Icon 64px, Web Favicon, Web PWA Icon 192px, Web PWA Icon 512px, Web PWA Maskable Icon 192px, Web PWA Maskable Icon 512px

### Community 108 - "API Endpoints"
Cohesion: 0.29
Nodes (6): ../../../../core/http/api_client.dart, _api, crearConductor, _endpointForTipo, getDocumentos, subirDocumento

### Community 109 - "API Endpoints"
Cohesion: 0.29
Nodes (6): ../../../core/http/api_endpoints.dart, api, data, map, response, ../../../shared/domain/entities/municipio.dart

### Community 110 - "Socket Service"
Cohesion: 0.29
Nodes (6): ../di/core_module.dart, client, service, socketServiceProvider, return, socket_service.dart

### Community 111 - "Ride Request Entities"
Cohesion: 0.29
Nodes (6): ../../domain/entities/documento.dart, DocumentoMapper, fromJson, _mapStatus, _tipoToNombre, _

### Community 112 - "Ride Request Entities"
Cohesion: 0.29
Nodes (6): ../../domain/entities/vehiculo.dart, fromJson, _mapStatus, toJson, VehiculoMapper, _

### Community 113 - "Firebase & Messaging"
Cohesion: 0.29
Nodes (6): firebase_push_messaging_service.dart, init, _messaging, MessagingGlobals, static FirebasePushMessagingService?, static FirebasePushMessagingService? get

### Community 114 - "Heatmap Feature"
Cohesion: 0.29
Nodes (6): ApiClient, _api, fetchZonas, fetchZonasRaw, HeatmapApi, ../models/heat_zone.dart

### Community 115 - "Community 115"
Cohesion: 0.29
Nodes (6): AuthStorage, clear, readAccessToken, readRefreshToken, writeTokens, SecureAuthStorage

### Community 116 - "Community 116"
Cohesion: 0.29
Nodes (6): demoUsername, seedIfEmpty, SensitiveDataSeeder, _storage, sensitive_data_storage.dart, static const String

### Community 117 - "Community 117"
Cohesion: 0.29
Nodes (7): rideProgressViewModelProvider, build, _drawOriginDestinationPins, initState, _onMapCreated, RideInProgressScreen, _RideInProgressScreenState

### Community 118 - "Community 118"
Cohesion: 0.52
Nodes (6): build_appbundle_normal(), build_appbundle_obfuscated(), build_normal(), build_obfuscated(), print_usage(), build.sh script

### Community 119 - "Community 119"
Cohesion: 0.33
Nodes (6): iOS Launch Image 2x, iOS Launch Image 3x, macOS App Icon 1024px, macOS App Icon 128px, macOS App Icon 16px, macOS App Icon 256px

### Community 120 - "Job Vacancy System"
Cohesion: 0.33
Nodes (6): build, AppRoutes.bolsa, AppRoutes.earnings, AppRoutes.editProfile, AppRoutes.misVacantes, AppRoutes.rideHistory

### Community 121 - "Document Domain"
Cohesion: 0.40
Nodes (4): dart:typed_data, ../entities/documento.dart, getDocumentos, subirDocumento

### Community 122 - "Registration Flow"
Cohesion: 0.40
Nodes (4): ../../domain/entities/register_params.dart, RegisterParamsMapper, toJson, _

### Community 123 - "Ride Request Entities"
Cohesion: 0.40
Nodes (4): ../../domain/entities/user.dart, fromJson, UserMapper, _

### Community 124 - "Community 124"
Cohesion: 0.40
Nodes (4): compressToJpeg, decoded, _encodeJpg, package:image/image.dart

### Community 125 - "Community 125"
Cohesion: 0.67
Nodes (4): Mototaxi Map Icon PNG, Orange Map Pin Marker, Green Map Pin Marker, Mototaxi Map Icon SVG

## Ambiguous Edges - Review These
- `Navigator 1.0 (Named Routes)` → `go_router`  [AMBIGUOUS]
  README.md · relation: references
- `AppIcon 29x29 @3x` → `LaunchImage`  [AMBIGUOUS]
  ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png · relation: conceptually_related_to

## Knowledge Gaps
- **1455 isolated node(s):** `client`, `sensitiveDataStorageProvider`, `apiClientProvider`, `ApiConfig`, `baseUrl` (+1450 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Navigator 1.0 (Named Routes)` and `go_router`?**
  _Edge tagged AMBIGUOUS (relation: references) - confidence is low._
- **What is the exact relationship between `AppIcon 29x29 @3x` and `LaunchImage`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `SensitiveDataStorage` connect `Firebase & Messaging` to `Auth Dependency Injection`, `Auth Dependency Injection`, `Community 99`, `Community 116`?**
  _High betweenness centrality (0.039) - this node is a cross-community bridge._
- **Why does `AuthStorage` connect `Community 115` to `Firebase & Messaging`, `Auth Login Flow`, `Auth Dependency Injection`, `Socket Service`, `API Endpoints`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **Why does `ApiClient` connect `Heatmap Feature` to `Auth Login Flow`, `Navigation & Routing`, `Vehicle Management`, `User Profile`, `Auth Dependency Injection`, `API Endpoints`, `Auth Login Flow`, `Job Vacancy System`, `Ride Request Entities`, `API Endpoints`?**
  _High betweenness centrality (0.015) - this node is a cross-community bridge._
- **What connects `client`, `sensitiveDataStorageProvider`, `apiClientProvider` to the rest of the system?**
  _1455 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Socket Service` be split into smaller, more focused modules?**
  _Cohesion score 0.023255813953488372 - nodes in this community are weakly interconnected._