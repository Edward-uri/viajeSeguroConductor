import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/theme.dart';
import '../../../profile/di/profile_module.dart';
import '../provider/login_password_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final vm = ref.read(loginPasswordViewModelProvider);
    vm.setEmail(_emailCtrl.text.trim());
    vm.setPassword(_passwordCtrl.text);
    final ok = await vm.login();
    if (!ok || !context.mounted) return;
    // El viewmodel de login no expone el user: se pide getMe (mismo patrón
    // que el preflight del splash) para decidir si es una cuenta solo-pasajero.
    try {
      final user = await ref.read(profileRepositoryProvider).getMe();
      if (!context.mounted) return;
      if (!user.esConductor && !user.esPropietario) {
        context.go(AppRoutes.upgradePropietario);
        return;
      }
    } catch (_) {
      // Sin red / error del servidor: no bloquear el login, el preflight
      // del splash/home ya cubre este caso en el próximo arranque.
    }
    if (context.mounted) context.go(AppRoutes.driverHome);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginPasswordViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Lockup de marca (Figma: mototaxi línea + wordmark) ───
                  // En dark el trazo tinta del SVG se pierde: disco crema detrás.
                  Center(
                    child: Container(
                      padding: isDark
                          ? const EdgeInsets.all(16)
                          : EdgeInsets.zero,
                      decoration: isDark
                          ? const BoxDecoration(
                              color: JalaBrand.cream,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        width: 132,
                        semanticsLabel: 'Jala',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jala',
                    textAlign: TextAlign.center,
                    style: text.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // ─── Título + caption alineados a la izquierda ───
                  Text(
                    'Inicia sesión',
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bienvenido de nuevo, listo para conducir',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.none,
                    keyboardType: TextInputType.visiblePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onSubmitted: (_) => _onLogin(),
                    onChanged: (v) => vm.setPassword(v),
                  ),
                  if (vm.errorMessage != null && vm.passwordError == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage!,
                      style: text.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      // CTA fijo al fondo (Figma); sube con el teclado vía viewInsets.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientButton(
                  label:
                      vm.isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
                  onPressed: vm.isLoading ? null : _onLogin,
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: vm.isLoading
                      ? null
                      : () => context.push(AppRoutes.registerEmail),
                  child: const Text('¿No tenés cuenta? Crear una'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
