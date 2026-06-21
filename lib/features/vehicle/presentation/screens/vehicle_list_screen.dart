import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Mi flotilla')),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RfcCard(
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.vehicleOwner),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'TUS VEHÍCULOS (${vm.vehiculos.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B6661),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: vm.vehiculos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final v = vm.vehiculos[i];
                          return _VehicleCard(
                            placa: v.placa,
                            descripcion:
                                '${v.marca} · ${v.color} · ${v.anio}',
                            status: v.status,
                            onTap: () =>
                                Navigator.of(context).pushNamed(
                              v.status == VehicleStatus.incomplete
                                  ? AppRoutes.vehicleEdit
                                  : AppRoutes.vehicleDetail,
                              arguments: v,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GradientButton(
                      label: 'Registrar vehículo',
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.vehicleRegister),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RfcCard extends StatelessWidget {
  final VoidCallback onTap;

  const _RfcCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E0),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFFFF8F00),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos de facturación',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1410),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'RFC: MEND920101AB1',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6661),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC4C4C4)),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String placa;
  final String descripcion;
  final VehicleStatus status;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.placa,
    required this.descripcion,
    required this.status,
    required this.onTap,
  });

  Color get _iconBg {
    switch (status) {
      case VehicleStatus.active:
        return const Color(0xFFE6F4EA);
      case VehicleStatus.incomplete:
        return const Color(0xFFF0F0F0);
      case VehicleStatus.reviewing:
        return const Color(0xFFFDF3DD);
    }
  }

  Color get _badgeBg {
    switch (status) {
      case VehicleStatus.active:
        return const Color(0xFFE6F4EA);
      case VehicleStatus.incomplete:
        return const Color(0xFFF0F0F0);
      case VehicleStatus.reviewing:
        return const Color(0xFFFDF3DD);
    }
  }

  Color get _badgeColor {
    switch (status) {
      case VehicleStatus.active:
        return const Color(0xFF1E8E5A);
      case VehicleStatus.incomplete:
        return const Color(0xFF9A9A9A);
      case VehicleStatus.reviewing:
        return const Color(0xFFE8A317);
    }
  }

  String get _badgeLabel {
    switch (status) {
      case VehicleStatus.active:
        return 'Activo';
      case VehicleStatus.incomplete:
        return 'Incompleto';
      case VehicleStatus.reviewing:
        return 'En revisión';
    }
  }

  String get _subtitle {
    switch (status) {
      case VehicleStatus.incomplete:
        return 'Faltan datos y documentos';
      default:
        return descripcion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 20,
                color: Color(0xFF1A1410),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placa,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1410),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: status == VehicleStatus.incomplete
                          ? const Color(0xFF6B6661)
                          : const Color(0xFF6B6661),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _badgeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _badgeColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC4C4C4)),
          ],
        ),
      ),
    );
  }
}
