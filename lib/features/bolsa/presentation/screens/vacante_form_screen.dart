import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../vehicle/domain/entities/vehiculo.dart';
import '../provider/dueno_vacantes_viewmodel.dart';

const _turnos = <(String, String)>[
  ('completo', 'Jornada completa'),
  ('matutino', 'Matutino'),
  ('vespertino', 'Vespertino'),
  ('nocturno', 'Nocturno'),
];

const _dias = <(String, String)>[
  ('lun', 'Lun'),
  ('mar', 'Mar'),
  ('mie', 'Mié'),
  ('jue', 'Jue'),
  ('vie', 'Vie'),
  ('sab', 'Sáb'),
  ('dom', 'Dom'),
];

class VacanteFormScreen extends ConsumerStatefulWidget {
  const VacanteFormScreen({super.key});

  @override
  ConsumerState<VacanteFormScreen> createState() => _VacanteFormScreenState();
}

class _VacanteFormScreenState extends ConsumerState<VacanteFormScreen> {
  final _rentaCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();
  final _condicionesCtrl = TextEditingController();
  int? _idVehiculoSeleccionado;
  String _tipoTurno = 'completo';
  final Set<String> _diasSeleccionados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(duenoVacantesViewModelProvider).load(),
    );
  }

  @override
  void dispose() {
    _rentaCtrl.dispose();
    _horarioCtrl.dispose();
    _condicionesCtrl.dispose();
    super.dispose();
  }

  bool get _esValido {
    if (_idVehiculoSeleccionado == null) return false;
    final renta = double.tryParse(_rentaCtrl.text.trim());
    if (renta == null || renta <= 0) return false;
    if (_diasSeleccionados.isEmpty) return false;
    return true;
  }

  Future<void> _publicar() async {
    final renta = double.tryParse(_rentaCtrl.text.trim()) ?? 0;
    final horario = _horarioCtrl.text.trim();
    final condiciones = _condicionesCtrl.text.trim();
    final ok = await ref.read(duenoVacantesViewModelProvider).crearVacante(
          idVehiculo: _idVehiculoSeleccionado!,
          tipoTurno: _tipoTurno,
          rentaTurno: renta,
          dias: _diasSeleccionados.toList(),
          horario: horario.isEmpty ? null : horario,
          condiciones: condiciones.isEmpty ? null : condiciones,
        );
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vacante publicada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(duenoVacantesViewModelProvider);
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

    // El vehículo seleccionado dejó de estar disponible: límpialo.
    if (_idVehiculoSeleccionado != null &&
        vehiculos.every((v) => v.idVehiculo != _idVehiculoSeleccionado)) {
      _idVehiculoSeleccionado = null;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Publicar vacante')),
      body: SafeArea(
        child: vm.isLoading && vehiculos.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : vehiculos.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No tienes vehículos disponibles: todos ya tienen una vacante abierta o no tienes vehículos registrados.',
                    ),
                  )
                : _buildForm(context, vehiculos, vm.isWorking),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<Vehiculo> vehiculos, bool working) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _label(context, 'VEHÍCULO'),
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
          onChanged: (v) => setState(() => _idVehiculoSeleccionado = v),
        ),
        const SizedBox(height: 20),
        _label(context, 'TIPO DE TURNO'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _turnos
              .map((t) => ChoiceChip(
                    label: Text(t.$2),
                    selected: _tipoTurno == t.$1,
                    onSelected: (_) => setState(() => _tipoTurno = t.$1),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _label(context, 'RENTA POR TURNO'),
        const SizedBox(height: 8),
        TextField(
          controller: _rentaCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixText: '\$ ',
            suffixText: 'MXN',
            hintText: '0',
            helperText: 'Lo que el conductor te da por turno',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _label(context, 'DÍAS QUE SE TRABAJA'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _dias
              .map((d) => FilterChip(
                    label: Text(d.$2),
                    selected: _diasSeleccionados.contains(d.$1),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _diasSeleccionados.add(d.$1);
                      } else {
                        _diasSeleccionados.remove(d.$1);
                      }
                    }),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _label(context, 'HORARIO (OPCIONAL)'),
        const SizedBox(height: 8),
        TextField(
          controller: _horarioCtrl,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ej. 06:00 – 14:00',
          ),
        ),
        const SizedBox(height: 20),
        _label(context, 'INFORMACIÓN ADICIONAL (OPCIONAL)'),
        const SizedBox(height: 8),
        TextField(
          controller: _condicionesCtrl,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Ej. Punto de entrega, requisitos, reparto…',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: working || !_esValido ? null : _publicar,
            child: Text(working ? 'Publicando…' : 'Publicar'),
          ),
        ),
      ],
    );
  }

  Widget _label(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      );

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
