import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/upgrade_propietario_screen.dart';
import '../features/auth/presentation/screens/registration/getstarted_screen.dart';
import '../features/auth/presentation/screens/registration/register_email_screen.dart';
import '../features/auth/presentation/screens/registration/register_municipio_screen.dart';
import '../features/auth/presentation/screens/registration/register_names_screen.dart';
import '../features/auth/presentation/screens/registration/register_otp_screen.dart';
import '../features/auth/presentation/screens/registration/register_personal_data_screen.dart';
import '../features/auth/presentation/screens/registration/register_photo_screen.dart';
import '../features/bolsa/presentation/screens/bolsa_screen.dart';
import '../features/bolsa/presentation/screens/mis_vacantes_screen.dart';
import '../features/bolsa/presentation/screens/vacante_form_screen.dart';
import '../features/bolsa/presentation/screens/vacante_postulaciones_screen.dart';
import '../features/bolsa/domain/entities/vacante.dart';
import '../features/documents/presentation/screens/document_upload_screen.dart';
import '../features/documents/presentation/screens/document_view_screen.dart';
import '../features/documents/presentation/screens/documents_approved_screen.dart';
import '../features/documents/presentation/screens/documents_list_screen.dart';
import '../features/documents/presentation/screens/documents_review_screen.dart';
import '../features/profile/presentation/screens/driver_profile_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/rides/presentation/screens/driver_home_screen.dart';
import '../features/rides/presentation/screens/earnings_screen.dart';
import '../features/rides/presentation/screens/ride_evaluation_screen.dart';
import '../features/rides/presentation/screens/ride_history_screen.dart';
import '../features/rides/presentation/screens/ride_in_progress_screen.dart';
import '../features/rides/presentation/screens/ride_request_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_detail_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_edit_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_list_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_owner_screen.dart';
import '../features/vehicle/presentation/screens/vehicle_register_screen.dart';
import '../shared/widgets/main_shell.dart';
import 'app_routes.dart';
import 'page_transitions.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRoute _page(String path, Widget Function(GoRouterState) child) => GoRoute(
      path: path,
      pageBuilder: (context, state) => fadePage(state, child(state)),
    );

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  routes: [
    _page(AppRoutes.splash, (_) => const SplashScreen()),
    _page(AppRoutes.getstarted, (_) => const GetstartedScreen()),
    _page(AppRoutes.login, (_) => const LoginScreen()),
    _page(AppRoutes.upgradePropietario, (_) => const UpgradePropietarioScreen()),
    _page(AppRoutes.registerEmail, (_) => const RegisterEmailScreen()),
    _page(AppRoutes.registerOtp, (_) => const RegisterOtpScreen()),
    _page(AppRoutes.registerNames, (_) => const RegisterNamesScreen()),
    _page(AppRoutes.registerPersonalData, (_) => const RegisterPersonalDataScreen()),
    _page(AppRoutes.registerMunicipio, (_) => const RegisterMunicipioScreen()),
    _page(AppRoutes.registerPhoto, (_) => const RegisterPhotoScreen()),
    _page(AppRoutes.documents, (_) => const DocumentsListScreen()),
    _page(AppRoutes.documentUpload, (_) => const DocumentUploadScreen()),
    _page(AppRoutes.documentView, (_) => const DocumentViewScreen()),
    _page(AppRoutes.documentsReview, (_) => const DocumentsReviewScreen()),
    _page(AppRoutes.documentsApproved, (_) => const DocumentsApprovedScreen()),
    _page(AppRoutes.editProfile, (_) => const EditProfileScreen()),
    _page(AppRoutes.rideRequest, (_) => const RideRequestScreen()),
    _page(AppRoutes.rideInProgress, (_) => const RideInProgressScreen()),
    _page(AppRoutes.rideEvaluation, (_) => const RideEvaluationScreen()),
    _page(AppRoutes.earnings, (_) => const EarningsScreen()),
    _page(AppRoutes.vehicleRegister, (_) => const VehicleRegisterScreen()),
    _page(AppRoutes.vehicleDetail, (_) => const VehicleDetailScreen()),
    _page(AppRoutes.vehicleEdit, (_) => const VehicleEditScreen()),
    _page(AppRoutes.vehicleOwner, (_) => const VehicleOwnerScreen()),
    _page(AppRoutes.bolsa, (_) => const BolsaScreen()),
    _page(AppRoutes.misVacantes, (_) => const MisVacantesScreen()),
    _page(AppRoutes.vacanteForm, (_) => const VacanteFormScreen()),
    _page(AppRoutes.vacantePostulaciones,
        (state) => VacantePostulacionesScreen(vacante: state.extra as Vacante?)),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.driverHome, builder: (_, _) => const DriverHomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.rideHistory, builder: (_, _) => const RideHistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.vehicles, builder: (_, _) => const VehicleListScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: AppRoutes.driverProfile, builder: (_, _) => const DriverProfileScreen()),
        ]),
      ],
    ),
  ],
);
