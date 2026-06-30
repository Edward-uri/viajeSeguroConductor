import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(() => setState(() {}));
    _apellidosController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final vm = ref.read(registerViewModelProvider);
    vm.setNombre(_nombreController.text.trim());

    final apellidos = _apellidosController.text.trim().split(' ');
    if (apellidos.isNotEmpty) {
      vm.setApellidoPaterno(apellidos.first);
      if (apellidos.length > 1) {
        vm.setApellidoMaterno(apellidos.skip(1).join(' '));
      } else {
        vm.setApellidoMaterno('');
      }
    }

    context.push(AppRoutes.registerPersonalData);
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
                'Ingresa tu nombre completo.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre(s)',
                  hintText: 'Jose Antonio',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apellidosController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Apellidos',
                  hintText: 'Rodriguez Flores',
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Continuar',
                onPressed: _nombreController.text.trim().isEmpty ||
                        _apellidosController.text.trim().isEmpty
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
