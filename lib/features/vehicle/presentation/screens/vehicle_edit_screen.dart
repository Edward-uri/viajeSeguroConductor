import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/vehiculo.dart';
import '../provider/vehicle_viewmodel.dart';

const _kColores = [
  'Blanco', 'Rojo', 'Azul', 'Negro', 'Verde', 'Amarillo', 'Gris', 'Naranja',
];

class VehicleEditScreen extends ConsumerStatefulWidget {
  const VehicleEditScreen({super.key});

  @override
  ConsumerState<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends ConsumerState<VehicleEditScreen> {
  final _anioController = TextEditingController();
  String? _color;
  Vehiculo? _vehiculo;
  bool _cargado = false;
  bool _guardando = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cargado) return;
    _cargado = true;
    final v = GoRouterState.of(context).extra as Vehiculo?;
    _vehiculo = v;
    // Solo precarga el color si es uno de la lista fija (los viejos de texto libre quedan sin selección).
    _color = (v != null && _kColores.contains(v.color)) ? v.color : null;
    _anioController.text = (v != null && v.anio > 0) ? v.anio.toString() : '';
  }

  @override
  void dispose() {
    _anioController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final v = _vehiculo;
    if (v == null) return;
    if (_color == null) {
      setState(() => _error = 'Selecciona un color.');
      return;
    }
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(vehicleViewModelProvider).actualizar(
            Vehiculo(
              idVehiculo: v.idVehiculo,
              placa: v.placa,
              numeroSerie: v.numeroSerie,
              marca: v.marca,
              modelo: v.modelo,
              color: _color!,
              anio: int.tryParse(_anioController.text.trim()) ?? v.anio,
              idMunicipio: v.idMunicipio,
              municipio: v.municipio,
              status: v.status,
            ),
          );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _guardando = false;
          _error = 'No se pudo guardar. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _vehiculo ?? GoRouterState.of(context).extra as Vehiculo?;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar vehículo')),
        body: const Center(child: Text('Vehículo no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(v.placa)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (v.status != VehicleStatus.active)
                _EstadoBanner(status: v.status),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _color,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Color'),
                hint: const Text('Selecciona un color'),
                items: _kColores
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _guardando
                    ? null
                    : (val) => setState(() {
                          _color = val;
                          _error = null;
                        }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _anioController,
                enabled: !_guardando,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Año'),
              ),
              if (v.municipio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Municipio: ${v.municipio}',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 8),
              Text(
                'La placa y el número de serie no se pueden editar.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: text.bodySmall?.copyWith(color: scheme.error)),
              ],
              const SizedBox(height: 32),
              GradientButton(
                label: _guardando ? 'Guardando…' : 'Guardar cambios',
                onPressed: _guardando ? null : _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner que explica que el vehículo aún no se puede usar y qué falta.
class _EstadoBanner extends StatelessWidget {
  const _EstadoBanner({required this.status});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final revision = status == VehicleStatus.reviewing;
    final color = revision ? context.brand.warning : context.brand.destructive;
    final bg = revision
        ? context.brand.warningLight
        : context.brand.destructiveLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(revision ? Icons.hourglass_top : Icons.error_outline,
              color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  revision ? 'En revisión' : 'Vehículo incompleto',
                  style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  revision
                      ? 'Tus documentos están en revisión. Podrás usar el vehículo cuando sean aprobados.'
                      : 'Para poder usarlo necesita: datos completos, tarjeta de circulación y foto del vehículo (aprobadas).',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
