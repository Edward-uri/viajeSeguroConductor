import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/theme.dart';
import '../../domain/entities/vehiculo.dart';
import '../provider/vehicle_viewmodel.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() =>
      _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(vehicleViewModelProvider).loadVehiculos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(vehicleViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    ref.listen<String?>(vehicleViewModelProvider.select((v) => v.errorMessage),
        (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi flotilla'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: vm.isLoading ? null : () => vm.loadVehiculos(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.all(isLandscape ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: vm.vehiculos.isEmpty
                          ? Center(
                              child: Text(
                                'Aún no tienes vehículos',
                                style: text.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant),
                              ),
                            )
                          : ListView.separated(
                              itemCount: vm.vehiculos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) {
                                final v = vm.vehiculos[i];
                                return _VehicleCard(
                                  placa: v.placa,
                                  descripcion: [
                                    if (v.marca.isNotEmpty) v.marca,
                                    if (v.modelo.isNotEmpty) v.modelo,
                                    if (v.color.isNotEmpty) v.color,
                                    if (v.anio > 0) '${v.anio}',
                                  ].join(' · '),
                                  status: v.status,
                                  activo: v.activo,
                                  onUsar: () => vm.usarVehiculo(v.idVehiculo),
                                  onTap: () => context.push(
                                    v.status == VehicleStatus.incomplete
                                        ? AppRoutes.vehicleEdit
                                        : AppRoutes.vehicleDetail,
                                    extra: v,
                                  ),
                                  isSaving: vm.isSaving,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Datos de facturación'),
                        subtitle: Text(
                          vm.rfc != null
                              ? 'RFC: ${vm.rfc}'
                              : 'Toca para configurar',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(AppRoutes.vehicleOwner),
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Registrar vehículo',
                      onPressed: () =>
                          context.push(AppRoutes.vehicleRegister),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String placa;
  final String descripcion;
  final VehicleStatus status;
  final bool activo;
  final VoidCallback onTap;
  final VoidCallback onUsar;
  final bool isSaving;

  const _VehicleCard({
    required this.placa,
    required this.descripcion,
    required this.status,
    required this.activo,
    required this.onTap,
    required this.onUsar,
    this.isSaving = false,
  });

  String get _subtitle {
    switch (status) {
      case VehicleStatus.incomplete:
        return 'Faltan datos y documentos';
      default:
        return descripcion.isEmpty ? 'Sin detalles del vehículo' : descripcion;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // Una sola señal de estado: "En uso" manda sobre el estado del vehículo.
    final (Color badgeBg, Color badgeColor, String badgeLabel) =
        switch ((activo, status)) {
      (true, _) => (
          JalaBrand.success.withValues(alpha: 0.12),
          JalaBrand.success,
          'En uso',
        ),
      (false, VehicleStatus.active) => (
          JalaBrand.success.withValues(alpha: 0.12),
          JalaBrand.success,
          'Activo',
        ),
      (false, VehicleStatus.reviewing) => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          'En revisión',
        ),
      (false, VehicleStatus.incomplete) => (
          scheme.surfaceContainerHigh,
          scheme.onSurfaceVariant,
          'Incompleto',
        ),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_car_outlined,
                    size: 20, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(placa,
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(_subtitle,
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    if (!activo)
                      TextButton(
                        onPressed: isSaving ? null : onUsar,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          alignment: Alignment.centerLeft,
                        ),
                        child: const Text('Usar este'),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
