import '../../routes/app_router.dart';
import '../../routes/app_routes.dart';

/// Acceso a la navegación desde fuera del árbol de widgets (p. ej. al reaccionar
/// a un borrado remoto por FCM) usando el router global de go_router.
class AppNavigator {
  const AppNavigator._();

  /// Envía al usuario a Login y limpia la pila de navegación.
  static void goToLogin() => appRouter.go(AppRoutes.login);
}
