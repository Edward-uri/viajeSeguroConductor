import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/mototaxi_image.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/vehiculo.dart';
import '../provider/vehicle_viewmodel.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
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

    ref.listen<String?>(vehicleViewModelProvider.select((v) => v.errorMessage),
        (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: scheme.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final initialLoading = vm.isLoading && vm.vehiculos.isEmpty;

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.vehicleRegister),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: SafeArea(
        child: initialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref.read(vehicleViewModelProvider).loadVehiculos(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  children: [
                    if (vm.vehiculos.isEmpty)
                      _EmptyState(text: text, scheme: scheme)
                    else ...[
                      for (final v in vm.vehiculos)
                        _VehiculoCard(
                          vehiculo: v,
                          isSaving: vm.isSaving,
                          onTap: () => context.push(
                            v.status == VehicleStatus.incomplete
                                ? AppRoutes.vehicleEdit
                                : AppRoutes.vehicleDetail,
                            extra: v,
                          ),
                          onUsar: () => vm.usarVehiculo(v.idVehiculo),
                        ),
                    ],
                    const SizedBox(height: 8),
                    _FacturacionTile(rfc: vm.rfc),
                  ],
                ),
              ),
      ),
    );
  }
}

class _VehiculoCard extends StatelessWidget {
  const _VehiculoCard({
    required this.vehiculo,
    required this.onTap,
    required this.onUsar,
    required this.isSaving,
  });

  final Vehiculo vehiculo;
  final VoidCallback onTap;
  final VoidCallback onUsar;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final v = vehiculo;
    final incompleto = v.status == VehicleStatus.incomplete;
    final aprobado = v.status == VehicleStatus.active;

    final (Color color, String label) = v.activo
        ? (context.brand.success, 'En uso')
        : switch (v.status) {
            VehicleStatus.active => (context.brand.success, 'Activo'),
            VehicleStatus.reviewing => (context.brand.warning, 'En revisión'),
            VehicleStatus.incomplete => (context.brand.greyLight, 'Incompleto'),
          };

    final detalles = [
      if (v.marca.isNotEmpty) v.marca,
      if (v.modelo.isNotEmpty) v.modelo,
      if (v.color.isNotEmpty) v.color,
      if (v.anio > 0) '${v.anio}',
    ].join(' · ');
    final subtitulo = incompleto
        ? 'Faltan datos y documentos'
        : (detalles.isEmpty ? 'Sin detalles del vehículo' : detalles);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: v.activo
            ? BorderSide(color: color.withValues(alpha: 0.6), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MototaxiImage(colorNombre: v.color, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.placa.isNotEmpty ? v.placa : 'Sin placa',
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitulo,
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (v.municipio.isNotEmpty)
                          Text(
                            v.municipio,
                            style: text.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        if (v.conductoresAsignados > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.person_pin_circle_outlined,
                                    size: 14, color: context.brand.success),
                                const SizedBox(width: 4),
                                Text(
                                  v.conductoresAsignados == 1
                                      ? '1 conductor asignado'
                                      : '${v.conductoresAsignados} conductores asignados',
                                  style: text.bodySmall?.copyWith(
                                    color: context.brand.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EstadoChip(label: label, color: color),
                ],
              ),
              if (aprobado && !v.activo) ...[
                const Divider(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: isSaving ? null : onUsar,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Usar este vehículo'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _FacturacionTile extends StatelessWidget {
  const _FacturacionTile({required this.rfc});

  final String? rfc;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: const Text('Datos de facturación'),
        subtitle: Text(rfc != null ? 'RFC: $rfc' : 'Toca para configurar'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.vehicleOwner),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text, required this.scheme});

  final TextTheme text;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined,
              size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes vehículos',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Registra tu primer mototaxi con el botón de abajo.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
