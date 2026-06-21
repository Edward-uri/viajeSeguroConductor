import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';

class RegisterEmailScreen extends ConsumerStatefulWidget {
  const RegisterEmailScreen({super.key});

  @override
  ConsumerState<RegisterEmailScreen> createState() =>
      _RegisterEmailScreenState();
}

class _RegisterEmailScreenState extends ConsumerState<RegisterEmailScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    final vm = ref.read(registerViewModelProvider);
    vm.setEmail(_controller.text.trim());
    final ok = await vm.sendOtp();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.registerOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Tu correo electrónico',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Te enviaremos un código de verificación.',
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
                  hintText: 'ejemplo@correo.com',
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
              const SizedBox(height: 32),
              GradientButton(
                label: vm.isLoading ? 'Enviando...' : 'Continuar',
                onPressed: vm.isLoading ? null : _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
