import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/authed_image.dart';
import '../../../../shared/widgets/mototaxi_image.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/conductor_asignado.dart';
import '../../domain/entities/vehiculo.dart';
import '../provider/conductores_asignados_viewmodel.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = GoRouterState.of(context).extra as Vehiculo?;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: Text('Vehículo no encontrado')),
      );
    }

    final statusColor = _statusColor(context, v.status);
    final statusLabel = _statusLabel(v.status);
    final progressValue = _progressValue(v.status);

    return Scaffold(
      appBar: AppBar(title: Text(v.placa)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: MototaxiImage(colorNombre: v.color, size: 96)),
              const SizedBox(height: 16),
              Text(
                '${v.marca} ${v.modelo}',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${v.color} — ${v.anio}',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (v.numeroSerie.isNotEmpty)
                Text(
                  'Serie: ${v.numeroSerie}',
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              Text(
                v.municipio,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      v.status == VehicleStatus.active
                          ? Icons.check_circle
                          : Icons.hourglass_top,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(statusLabel,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: statusColor)),
                    const Spacer(),
                    SizedBox(
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor: scheme.surfaceContainerHigh,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _ConductoresAsignados(idVehiculo: v.idVehiculo),
              const SizedBox(height: 24),
              Text(
                'DOCUMENTOS DEL VEHÍCULO',
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _docItem(
                'Tarjeta de circulación',
                v.status == VehicleStatus.active ? 'Aprobado' : 'En revisión',
                v.status == VehicleStatus.active
                    ? context.brand.success
                    : context.brand.warning,
                text,
              ),
              const Divider(),
              _docItem(
                'Foto del vehículo',
                v.status == VehicleStatus.active ||
                        v.status == VehicleStatus.reviewing
                    ? 'Aprobado'
                    : 'Pendiente',
                v.status == VehicleStatus.active
                    ? context.brand.success
                    : context.brand.warning,
                text,
              ),
              const Divider(),
              _docItem(
                'Permiso/concesión municipal',
                'Opcional — Toca para subir',
                context.brand.greyLight,
                text,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return context.brand.success;
      case VehicleStatus.reviewing:
        return context.brand.warning;
      case VehicleStatus.incomplete:
        return context.brand.greyLight;
    }
  }

  String _statusLabel(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return 'Aprobado';
      case VehicleStatus.reviewing:
        return 'En revisión';
      case VehicleStatus.incomplete:
        return 'Incompleto';
    }
  }

  double _progressValue(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return 1.0;
      case VehicleStatus.reviewing:
        return 0.66;
      case VehicleStatus.incomplete:
        return 0.33;
    }
  }

  Widget _docItem(
      String name, String status, Color statusColor, TextTheme text) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        status.contains('Aprobado')
            ? Icons.check_circle
            : Icons.hourglass_top,
        color: statusColor,
      ),
      title: Text(name,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      trailing: Text(status,
          style: text.bodySmall?.copyWith(
              color: statusColor, fontWeight: FontWeight.w600)),
    );
  }
}

/// Sección "Conductores asignados" del vehículo: lista + gestionar (editar/baja).
class _ConductoresAsignados extends ConsumerWidget {
  const _ConductoresAsignados({required this.idVehiculo});

  final int idVehiculo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vm = ref.watch(conductoresAsignadosViewModelProvider(idVehiculo));

    ref.listen<String?>(
        conductoresAsignadosViewModelProvider(idVehiculo)
            .select((v) => v.errorMessage), (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
    ref.listen<String?>(
        conductoresAsignadosViewModelProvider(idVehiculo)
            .select((v) => v.successMessage), (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CONDUCTORES ASIGNADOS',
              style: text.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (!vm.isLoading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${vm.conductores.length}',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (vm.conductores.isEmpty)
          Text(
            'Aún no tienes conductores asignados a este vehículo. Publica una '
            'vacante en la bolsa para reclutar.',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          )
        else
          ...vm.conductores.map(
            (c) => _ConductorCard(idVehiculo: idVehiculo, conductor: c),
          ),
      ],
    );
  }
}

class _ConductorCard extends ConsumerWidget {
  const _ConductorCard({required this.idVehiculo, required this.conductor});

  final int idVehiculo;
  final ConductorAsignado conductor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vm = ref.watch(conductoresAsignadosViewModelProvider(idVehiculo));
    final cal = conductor.calificacion;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(nombre: conductor.nombre, fotoPath: conductor.fotoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conductor.nombre ?? 'Conductor',
                        style: text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 15, color: context.brand.warning),
                          const SizedBox(width: 3),
                          Text(
                            cal != null
                                ? cal.toStringAsFixed(1)
                                : 'Sin calificación',
                            style: text.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (conductor.turnoLabel.isNotEmpty)
                  _Chip(label: conductor.turnoLabel, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            if (conductor.rentaLabel.isNotEmpty)
              _InfoLinea(
                icon: Icons.payments_outlined,
                label: '${conductor.rentaLabel} de renta por turno',
              ),
            if (conductor.diasLabel.isNotEmpty)
              _InfoLinea(
                  icon: Icons.calendar_today_outlined,
                  label: conductor.diasLabel),
            if (conductor.horario != null && conductor.horario!.isNotEmpty)
              _InfoLinea(
                  icon: Icons.schedule_outlined, label: conductor.horario!),
            if (conductor.turnoLabel.isEmpty &&
                conductor.rentaLabel.isEmpty &&
                conductor.diasLabel.isEmpty)
              _InfoLinea(
                icon: Icons.info_outline,
                label: 'Asignación directa, sin términos definidos.',
              ),
            const Divider(height: 22),
            Row(
              children: [
                TextButton.icon(
                  onPressed:
                      vm.isWorking ? null : () => _editar(context, ref),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar términos'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed:
                      vm.isWorking ? null : () => _darDeBaja(context, ref),
                  icon: Icon(Icons.person_remove_outlined,
                      size: 18, color: scheme.error),
                  label: Text('Dar de baja',
                      style: TextStyle(color: scheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editar(BuildContext context, WidgetRef ref) async {
    final form = await showModalBottomSheet<_TerminosForm>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditarTerminosSheet(conductor: conductor),
    );
    if (form == null) return;
    await ref
        .read(conductoresAsignadosViewModelProvider(idVehiculo))
        .editarTerminos(
          conductor.idConductor,
          tipoTurno: form.tipoTurno,
          rentaTurno: form.rentaTurno,
          dias: form.dias,
          horario: form.horario,
        );
  }

  Future<void> _darDeBaja(BuildContext context, WidgetRef ref) async {
    final nombre = conductor.nombre ?? 'este conductor';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Dar de baja?'),
        content: Text(
            '$nombre dejará de tener acceso a este vehículo. Podrás asignar a '
            'alguien más después.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(conductoresAsignadosViewModelProvider(idVehiculo))
          .darDeBaja(conductor.idConductor);
    }
  }
}

/// Datos que devuelve el sheet de edición.
class _TerminosForm {
  const _TerminosForm({
    required this.tipoTurno,
    required this.rentaTurno,
    required this.dias,
    this.horario,
  });

  final String tipoTurno;
  final double rentaTurno;
  final List<String> dias;
  final String? horario;
}

const _kTurnos = [
  ('completo', 'Jornada completa'),
  ('matutino', 'Matutino'),
  ('vespertino', 'Vespertino'),
  ('nocturno', 'Nocturno'),
];
const _kDias = [
  ('lun', 'Lun'),
  ('mar', 'Mar'),
  ('mie', 'Mié'),
  ('jue', 'Jue'),
  ('vie', 'Vie'),
  ('sab', 'Sáb'),
  ('dom', 'Dom'),
];

class _EditarTerminosSheet extends StatefulWidget {
  const _EditarTerminosSheet({required this.conductor});

  final ConductorAsignado conductor;

  @override
  State<_EditarTerminosSheet> createState() => _EditarTerminosSheetState();
}

class _EditarTerminosSheetState extends State<_EditarTerminosSheet> {
  late String _turno;
  late Set<String> _dias;
  late TextEditingController _renta;
  late TextEditingController _horario;
  bool _intentado = false;

  @override
  void initState() {
    super.initState();
    final c = widget.conductor;
    _turno = c.tipoTurno.isNotEmpty ? c.tipoTurno : 'completo';
    _dias = c.dias.toSet();
    final r = c.rentaTurno;
    _renta = TextEditingController(
        text: r == null || r <= 0
            ? ''
            : (r.truncateToDouble() == r
                ? r.toStringAsFixed(0)
                : r.toStringAsFixed(2)));
    _horario = TextEditingController(text: c.horario ?? '');
  }

  @override
  void dispose() {
    _renta.dispose();
    _horario.dispose();
    super.dispose();
  }

  double? get _rentaValida {
    final v = double.tryParse(_renta.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return v;
  }

  void _guardar() {
    setState(() => _intentado = true);
    final renta = _rentaValida;
    if (renta == null || _dias.isEmpty) return;
    Navigator.of(context).pop(_TerminosForm(
      tipoTurno: _turno,
      rentaTurno: renta,
      dias: _kDias.map((d) => d.$1).where(_dias.contains).toList(),
      horario: _horario.text.trim().isEmpty ? null : _horario.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final rentaError = _intentado && _rentaValida == null;
    final diasError = _intentado && _dias.isEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editar términos',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              widget.conductor.nombre ?? 'Conductor',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text('Turno',
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _kTurnos
                  .map((t) => ChoiceChip(
                        label: Text(t.$2),
                        selected: _turno == t.$1,
                        onSelected: (_) => setState(() => _turno = t.$1),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text('Días',
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _kDias
                  .map((d) => FilterChip(
                        label: Text(d.$2),
                        selected: _dias.contains(d.$1),
                        onSelected: (sel) => setState(() {
                          if (sel) {
                            _dias.add(d.$1);
                          } else {
                            _dias.remove(d.$1);
                          }
                        }),
                      ))
                  .toList(),
            ),
            if (diasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Elige al menos un día',
                    style: text.bodySmall?.copyWith(color: scheme.error)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _renta,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Renta por turno (MXN)',
                prefixText: '\$ ',
                errorText: rentaError ? 'Ingresa un monto válido' : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _horario,
              decoration: const InputDecoration(
                labelText: 'Horario (opcional)',
                hintText: 'Ej. 6:00 a 14:00',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _guardar,
                child: const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Foto del conductor (protegida por token) con fallback a iniciales.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.nombre, required this.fotoPath});

  final String? nombre;
  final String? fotoPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 48.0;
    final fallback = Container(
      width: size,
      height: size,
      color: scheme.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        _iniciales(nombre),
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
    return ClipOval(
      child: (fotoPath == null || fotoPath!.isEmpty)
          ? fallback
          : AuthedImage(path: fotoPath, size: size, fallback: fallback),
    );
  }

  static String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '?';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final a = partes.first.isNotEmpty ? partes.first[0] : '';
    final b = partes.length > 1 && partes[1].isNotEmpty ? partes[1][0] : '';
    final ini = (a + b).toUpperCase();
    return ini.isEmpty ? '?' : ini;
  }
}

class _InfoLinea extends StatelessWidget {
  const _InfoLinea({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
