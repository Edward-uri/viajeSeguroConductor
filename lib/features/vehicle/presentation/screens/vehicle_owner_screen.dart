import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';

class VehicleOwnerScreen extends ConsumerStatefulWidget {
  const VehicleOwnerScreen({super.key});

  @override
  ConsumerState<VehicleOwnerScreen> createState() =>
      _VehicleOwnerScreenState();
}

class _VehicleOwnerScreenState extends ConsumerState<VehicleOwnerScreen> {
  final _rfcController = TextEditingController();
  final _razonController = TextEditingController();

  @override
  void dispose() {
    _rfcController.dispose();
    _razonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Datos de facturación')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos de facturación',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Opcional — solo si eres persona moral.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _rfcController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'RFC',
                  hintText: 'MEND920101AB1',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _razonController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Razón social',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Si eres persona física, déjalo en blanco.',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Guardar',
                onPressed: () => context.go(AppRoutes.vehicles),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
