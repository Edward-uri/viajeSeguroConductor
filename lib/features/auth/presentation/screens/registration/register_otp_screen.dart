import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';
import 'paso_registro_scaffold.dart';

class RegisterOtpScreen extends ConsumerStatefulWidget {
  const RegisterOtpScreen({super.key});

  @override
  ConsumerState<RegisterOtpScreen> createState() => _RegisterOtpScreenState();
}

class _RegisterOtpScreenState extends ConsumerState<RegisterOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
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
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  Future<void> _onContinue() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) return;

    final vm = ref.read(registerViewModelProvider);
    final ok = await vm.verifyOtp(code);
    if (ok && context.mounted) {
      context.push(AppRoutes.registerNames);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return PasoRegistroScaffold(
      paso: 2,
      titulo: 'Código de verificación',
      caption: 'Ingresa el código de 6 dígitos que enviamos a tu correo.',
      ctaLabel: vm.isLoading ? 'Verificando...' : 'Continuar',
      onCta: vm.isLoading ? null : _onContinue,
      belowCta: TextButton(
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
      children: [
        Row(
          children: List.generate(6, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 4,
                  right: i == 5 ? 0 : 4,
                ),
                child: SizedBox(
                  height: 64,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (v) => _onDigitChange(i, v),
                  ),
                ),
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
      ],
    );
  }
}
