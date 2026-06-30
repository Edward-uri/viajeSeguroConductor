import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/vehiculo.dart';

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

    final statusColor = _statusColor(v.status);
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
              Text(
                '${v.marca} ${v.modelo}',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${v.color} — ${v.anio}',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                v.municipio,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
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
                    ? const Color(0xFF1E8E5A)
                    : const Color(0xFFE8A317),
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
                    ? const Color(0xFF1E8E5A)
                    : const Color(0xFFE8A317),
                text,
              ),
              const Divider(),
              _docItem(
                'Permiso/concesión municipal',
                'Opcional — Toca para subir',
                Colors.grey,
                text,
              ),
              const SizedBox(height: 16),
              Text(
                'El permiso municipal es opcional y no bloquea la activación.',
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return const Color(0xFF1E8E5A);
      case VehicleStatus.reviewing:
        return const Color(0xFFE8A317);
      case VehicleStatus.incomplete:
        return const Color(0xFF9A9A9A);
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
