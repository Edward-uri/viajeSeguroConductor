import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../vehicle/domain/entities/vehiculo.dart';
import '../provider/dueno_vacantes_viewmodel.dart';

class VacanteFormScreen extends ConsumerStatefulWidget {
  const VacanteFormScreen({super.key});

  @override
  ConsumerState<VacanteFormScreen> createState() => _VacanteFormScreenState();
}

class _VacanteFormScreenState extends ConsumerState<VacanteFormScreen> {
  final _condicionesCtrl = TextEditingController();
  int? _idVehiculoSeleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(duenoVacantesViewModelProvider).load(),
    );
  }

  @override
  void dispose() {
    _condicionesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(duenoVacantesViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final vehiculos = vm.vehiculosSinVacante;

    ref.listen<String?>(
        duenoVacantesViewModelProvider.select((v) => v.errorMessage),
        (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    if (_idVehiculoSeleccionado != null &&
        vehiculos.every((v) => v.idVehiculo != _idVehiculoSeleccionado)) {
      _idVehiculoSeleccionado = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar vacante')),
      body: SafeArea(
        child: vm.isLoading && vehiculos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(20),
                child: vehiculos.isEmpty
                    ? const Text(
                        'No tienes vehículos disponibles: todos ya tienen una vacante abierta o no tienes vehículos registrados.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VEHÍCULO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            initialValue: _idVehiculoSeleccionado,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Selecciona un vehículo',
                            ),
                            items: vehiculos
                                .map((v) => DropdownMenuItem<int>(
                                      value: v.idVehiculo,
                                      child: Text(_descripcion(v)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _idVehiculoSeleccionado = v),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'CONDICIONES (OPCIONAL)',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _condicionesCtrl,
                            maxLines: 4,
                            maxLength: 1000,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Ej. Turno matutino, reparto 60/40',
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: vm.isWorking ||
                                      _idVehiculoSeleccionado == null
                                  ? null
                                  : () async {
                                      final ok = await ref
                                          .read(duenoVacantesViewModelProvider)
                                          .crearVacante(
                                            _idVehiculoSeleccionado!,
                                            _condicionesCtrl.text.trim(),
                                          );
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Vacante publicada'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        context.pop();
                                      }
                                    },
                              child: const Text('Publicar'),
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  String _descripcion(Vehiculo v) {
    final partes = [
      if (v.modelo.isNotEmpty) v.modelo,
      if (v.color.isNotEmpty) v.color,
      if (v.anio > 0) '${v.anio}',
    ];
    if (partes.isNotEmpty) return partes.join(' · ');
    return v.placa.isNotEmpty ? v.placa : 'Vehículo #${v.idVehiculo}';
  }
}
