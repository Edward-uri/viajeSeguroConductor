import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/registration/getstarted_screen.dart';
import 'features/auth/presentation/screens/registration/register_email_screen.dart';
import 'features/auth/presentation/screens/registration/register_lastnames_screen.dart';
import 'features/auth/presentation/screens/registration/register_license_screen.dart';
import 'features/auth/presentation/screens/registration/register_municipio_screen.dart';
import 'features/auth/presentation/screens/registration/register_names_screen.dart';
import 'features/auth/presentation/screens/registration/register_otp_screen.dart';
import 'features/auth/presentation/screens/registration/register_personal_data_screen.dart';
import 'features/auth/presentation/screens/login_otp_screen.dart';
import 'features/auth/presentation/screens/login_password_screen.dart';
import 'features/documents/presentation/screens/document_upload_screen.dart';
import 'features/documents/presentation/screens/document_view_screen.dart';
import 'features/documents/presentation/screens/documents_approved_screen.dart';
import 'features/documents/presentation/screens/documents_list_screen.dart';
import 'features/documents/presentation/screens/documents_review_screen.dart';
import 'features/profile/presentation/screens/driver_profile_screen.dart';
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/rides/presentation/screens/driver_home_screen.dart';
import 'features/rides/presentation/screens/earnings_screen.dart';
import 'features/rides/presentation/screens/payment_methods_screen.dart';
import 'features/rides/presentation/screens/ride_evaluation_screen.dart';
import 'features/rides/presentation/screens/ride_history_screen.dart';
import 'features/rides/presentation/screens/ride_in_progress_screen.dart';
import 'features/rides/presentation/screens/ride_request_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/vehicle/presentation/screens/vehicle_detail_screen.dart';
import 'features/vehicle/presentation/screens/vehicle_edit_screen.dart';
import 'features/vehicle/presentation/screens/vehicle_list_screen.dart';
import 'features/vehicle/presentation/screens/vehicle_owner_screen.dart';
import 'features/vehicle/presentation/screens/vehicle_register_screen.dart';
import 'routes/app_routes.dart';
import 'theme/theme.dart';
import 'theme/util.dart';

class JalaApp extends StatelessWidget {
  const JalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    final textTheme =
        createTextTheme(context, 'Plus Jakarta Sans', 'Plus Jakarta Sans');
    final theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: 'Jala',
      navigatorKey: AppNavigator.key,
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: theme.light(),
      darkTheme: theme.dark(),
      themeMode:
          brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      routes: <String, WidgetBuilder>{
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.loginOtp: (_) => const LoginOtpScreen(),
        AppRoutes.loginPassword: (_) => const LoginPasswordScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.getstarted: (_) => const GetstartedScreen(),
        AppRoutes.registerEmail: (_) => const RegisterEmailScreen(),
        AppRoutes.registerOtp: (_) => const RegisterOtpScreen(),
        AppRoutes.registerNames: (_) => const RegisterNamesScreen(),
        AppRoutes.registerLastnames: (_) => const RegisterLastnamesScreen(),
        AppRoutes.registerPersonalData: (_) =>
            const RegisterPersonalDataScreen(),
        AppRoutes.registerMunicipio: (_) => const RegisterMunicipioScreen(),
        AppRoutes.license: (_) => const RegisterLicenseScreen(),
        AppRoutes.documents: (_) => const DocumentsListScreen(),
        AppRoutes.documentUpload: (_) => const DocumentUploadScreen(),
        AppRoutes.documentView: (_) => const DocumentViewScreen(),
        AppRoutes.documentsReview: (_) => const DocumentsReviewScreen(),
        AppRoutes.documentsApproved: (_) => const DocumentsApprovedScreen(),
        AppRoutes.driverHome: (_) => const DriverHomeScreen(),
        AppRoutes.rideRequest: (_) => const RideRequestScreen(),
        AppRoutes.driverProfile: (_) => const DriverProfileScreen(),
        AppRoutes.editProfile: (_) => const EditProfileScreen(),
        AppRoutes.vehicles: (_) => const VehicleListScreen(),
        AppRoutes.vehicleRegister: (_) => const VehicleRegisterScreen(),
        AppRoutes.vehicleDetail: (_) => const VehicleDetailScreen(),
        AppRoutes.vehicleEdit: (_) => const VehicleEditScreen(),
        AppRoutes.vehicleOwner: (_) => const VehicleOwnerScreen(),
        AppRoutes.rideInProgress: (_) => const RideInProgressScreen(),
        AppRoutes.rideEvaluation: (_) => const RideEvaluationScreen(),
        AppRoutes.rideHistory: (_) => const RideHistoryScreen(),
        AppRoutes.earnings: (_) => const EarningsScreen(),
        AppRoutes.paymentMethods: (_) => const PaymentMethodsScreen(),
      },
    );
  }
}
