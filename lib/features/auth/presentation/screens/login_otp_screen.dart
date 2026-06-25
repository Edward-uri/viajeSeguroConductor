import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../features/documents/di/documents_module.dart';
import '../../../../features/documents/presentation/utils/document_route_helper.dart';
import '../provider/login_viewmodel.dart';

class LoginOtpScreen extends ConsumerStatefulWidget {
  const LoginOtpScreen({super.key});

  @override
  ConsumerState<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends ConsumerState<LoginOtpScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());
  int _secondsLeft = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      }
      return _secondsLeft > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChange(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _onContinue() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) return;

    final vm = ref.read(loginViewModelProvider);
    final ok = await vm.verifyOtp(code);
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
    final vm = ref.watch(loginViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text(
                'Código de verificación',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa el código de 4 dígitos que enviamos a tu correo.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) {
                  return SizedBox(
                    width: 64,
                    height: 64,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: scheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: scheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF8F00), width: 2),
                        ),
                      ),
                      onChanged: (v) => _onDigitChange(i, v),
                    ),
                  );
                }),
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  vm.errorMessage!,
                  style: text.bodySmall?.copyWith(color: scheme.error),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _secondsLeft == 0
                      ? () {
                          setState(() => _secondsLeft = 60);
                          _startTimer();
                        }
                      : null,
                  child: Text(
                    _secondsLeft > 0
                        ? 'Reenviar código en $_secondsLeft s'
                        : 'Reenviar código',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: vm.isLoading ? 'Verificando...' : 'Iniciar sesión',
                onPressed: vm.isLoading ? null : _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
