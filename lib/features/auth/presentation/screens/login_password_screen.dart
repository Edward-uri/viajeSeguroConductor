import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../features/documents/di/documents_module.dart';
import '../../../../features/documents/presentation/utils/document_route_helper.dart';
import '../provider/login_password_viewmodel.dart';

class LoginPasswordScreen extends ConsumerStatefulWidget {
  const LoginPasswordScreen({super.key});

  @override
  ConsumerState<LoginPasswordScreen> createState() =>
      _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends ConsumerState<LoginPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final vm = ref.read(loginPasswordViewModelProvider);
    vm.setEmail(_emailCtrl.text.trim());
    vm.setPassword(_passwordCtrl.text);
    final ok = await vm.login();
    if (ok && context.mounted) {
      final repo = ref.read(documentoRepositoryProvider);
      final route = await resolveDocumentsRoute(repo);
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginPasswordViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(Icons.motorcycle_outlined,
                      size: 80, color: const Color(0xFFFF8F00)),
                  const SizedBox(height: 24),
                  Text(
                    'Inicia sesión con contraseña',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1410),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.email_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.lock_outlined),
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
                  ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Usar código de verificación'),
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
