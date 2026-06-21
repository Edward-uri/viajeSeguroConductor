import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';

class VehicleRegisterScreen extends ConsumerStatefulWidget {
  const VehicleRegisterScreen({super.key});

  @override
  ConsumerState<VehicleRegisterScreen> createState() =>
      _VehicleRegisterScreenState();
}

class _VehicleRegisterScreenState
    extends ConsumerState<VehicleRegisterScreen> {
  final _placaController = TextEditingController();
  final _municipioController = TextEditingController();
  final _modeloController = TextEditingController();
  final _colorController = TextEditingController();
  final _anioController = TextEditingController();

  @override
  void dispose() {
    _placaController.dispose();
    _municipioController.dispose();
    _modeloController.dispose();
    _colorController.dispose();
    _anioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar vehículo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _placaController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Placa *',
                  hintText: 'ABC-123',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _municipioController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Municipio *',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modeloController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _colorController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Color',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _anioController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Año',
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Registrar vehículo',
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.vehicleOwner),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
