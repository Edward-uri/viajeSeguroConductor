import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
import '../provider/login_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final vm = ref.read(loginViewModelProvider);
    vm.setEmail(_controller.text.trim());
    final ok = await vm.sendOtp();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.loginOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(loginViewModelProvider);
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
                  const SizedBox(height: 24),
                  Icon(Icons.motorcycle_outlined,
                      size: 80, color: const Color(0xFFFF8F00)),
                  const SizedBox(height: 24),
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
                    controller: _controller,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.email_outlined,
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                    onSubmitted: (_) => _onContinue(),
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
                    label: vm.isLoading ? 'Enviando...' : 'Recibir código',
                    onPressed: vm.isLoading ? null : _onContinue,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppRoutes.loginPassword),
                    child: const Text('Iniciar sesión con contraseña'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () => Navigator.of(context)
                            .pushNamed(AppRoutes.registerEmail),
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
