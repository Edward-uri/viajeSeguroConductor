import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/vehiculo.dart';

class VehicleEditScreen extends ConsumerStatefulWidget {
  const VehicleEditScreen({super.key});

  @override
  ConsumerState<VehicleEditScreen> createState() =>
      _VehicleEditScreenState();
}

class _VehicleEditScreenState extends ConsumerState<VehicleEditScreen> {
  late TextEditingController _colorController;
  late TextEditingController _anioController;
  late TextEditingController _municipioController;

  @override
  void initState() {
    super.initState();
    final v = ModalRoute.of(context)?.settings.arguments as Vehiculo?;
    _colorController = TextEditingController(text: v?.color ?? '');
    _anioController =
        TextEditingController(text: v?.anio.toString() ?? '');
    _municipioController =
        TextEditingController(text: v?.municipio ?? '');
  }

  @override
  void dispose() {
    _colorController.dispose();
    _anioController.dispose();
    _municipioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = ModalRoute.of(context)?.settings.arguments as Vehiculo?;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(v?.placa ?? 'Editar vehículo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _colorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _anioController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Año'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _municipioController,
                textInputAction: TextInputAction.done,
                decoration:
                    const InputDecoration(labelText: 'Municipio'),
              ),
              const SizedBox(height: 8),
              Text(
                'La placa no se puede editar.',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Guardar cambios',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
