import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/http/api_exception.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/logo_badge.dart';
import '../../../../features/documents/di/documents_module.dart';
import '../../../../features/documents/presentation/utils/document_route_helper.dart';
import '../../../../routes/app_routes.dart';
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
    if (ok && context.mounted) {
      final repo = ref.read(documentoRepositoryProvider);
      String route;
      try {
        route = await resolveDocumentsRoute(repo);
      } on UnauthorizedException {
        route = AppRoutes.documents;
      }
      if (!context.mounted) return;
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginPasswordViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  const LogoBadge(size: 100),
                  const SizedBox(height: 20),
                  Text(
                    'Jala',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para conducir',
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.email_outlined,
                            color: scheme.onSurfaceVariant),
                      ),
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
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.lock_outlined,
                            color: scheme.onSurfaceVariant),
                      ),
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
                  const SizedBox(height: 24),
                  GradientButton(
                    label: vm.isLoading ? 'Iniciando sesión...' : 'Iniciar sesión',
                    onPressed: vm.isLoading ? null : _onLogin,
                  ),
                  const SizedBox(height: 8),
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
      ),
    );
  }
}
