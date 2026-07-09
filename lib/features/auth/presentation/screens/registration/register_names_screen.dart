import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';
import 'paso_registro_scaffold.dart';

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
    return PasoRegistroScaffold(
      paso: 3,
      titulo: '¿Cómo te llamas?',
      caption: 'Ingresa tu nombre completo.',
      ctaLabel: 'Continuar',
      onCta: _nombreController.text.trim().isEmpty ||
              _apellidosController.text.trim().isEmpty
          ? null
          : _onContinue,
      children: [
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
      ],
    );
  }
}
