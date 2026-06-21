import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';

class RegisterNamesScreen extends ConsumerStatefulWidget {
  const RegisterNamesScreen({super.key});

  @override
  ConsumerState<RegisterNamesScreen> createState() =>
      _RegisterNamesScreenState();
}

class _RegisterNamesScreenState extends ConsumerState<RegisterNamesScreen> {
  final _firstNameController = TextEditingController();
  final _secondNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final vm = ref.read(registerViewModelProvider);
    vm.setNombre(_firstNameController.text.trim());
    Navigator.of(context).pushNamed(AppRoutes.registerLastnames);
  }

  @override
  Widget build(BuildContext context) {
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
                '¿Cómo te llamas?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tus nombres.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Primer nombre',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _secondNameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Segundo nombre (opcional)',
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Continuar',
                onPressed: _firstNameController.text.trim().isEmpty
                    ? null
                    : _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
