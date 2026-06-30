import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../features/documents/di/documents_module.dart';
import '../../../../features/documents/domain/entities/documento.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../provider/driver_profile_viewmodel.dart';


String _estadoLabel(String estado) {
  switch (estado.toLowerCase()) {
    case 'activo':
      return 'Habilitado';
    case 'suspendido':
      return 'Suspendido';
    case 'eliminado':
      return 'Eliminado';
    default:
      return 'N/A';
  }
}

Color _estadoColor(String estado) {
  switch (estado.toLowerCase()) {
    case 'activo':
      return const Color(0xFF1E8E5A);
    case 'suspendido':
      return const Color(0xFFD84315);
    case 'eliminado':
      return const Color(0xFFB71C1C);
    default:
      return Colors.grey;
  }
}


class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  bool _docsApproved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProfileViewModelProvider).loadData();
      _checkDocsApproved();
    });
  }

  Future<void> _checkDocsApproved() async {
    final repo = ref.read(documentoRepositoryProvider);
    try {
      final docs = await repo.getDocumentos();
      if (mounted) {
        setState(() {
          _docsApproved = docs.every((d) => d.status == DocumentStatus.approved);
        });
      }
    } catch (_) {
      // si falla, asumimos que no están aprobados
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(driverProfileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (vm.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = vm.user;
    final vehicle = vm.vehiculo;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── Avatar ───
            Center(
              child: ClipOval(
                child: Container(
                  width: 88,
                  height: 88,
                  color: const Color(0xFFFF8F00),
                  alignment: Alignment.center,
                  child: AuthedImage(
                    path: user?.fotoPerfilUrl,
                    size: 88,
                    fallback: Text(
                      _initials(user?.nombreCompleto ?? vm.displayName),
                      style: text.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ─── Nombre ───
            Center(
              child: Text(
                user?.nombreCompleto ?? vm.displayName,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // ─── Rol ───
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user != null
                        ? user.rol.toUpperCase()
                        : 'N/A',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ─── Estado badge ───
            if (user != null)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _estadoColor(user.estadoCuenta).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _estadoLabel(user.estadoCuenta),
                    style: TextStyle(
                      color: _estadoColor(user.estadoCuenta),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // ─── Stats ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(
                  vm.stats?.calificacion?.toStringAsFixed(1) ?? '0',
                  'Calificación',
                  text,
                ),
                _statItem('${vm.viajes}', 'Viajes', text),
                _statItem(
                  vm.stats?.tasaAceptacion?.toStringAsFixed(0) ?? '0',
                  'Aceptación',
                  text,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ─── Vehículo ───
            if (vehicle != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bike_outlined),
                  title: Text(
                    vehicle.marca.isNotEmpty && vehicle.modelo.isNotEmpty
                        ? '${vehicle.marca} — ${vehicle.modelo}'
                        : vehicle.placa,
                  ),
                  subtitle: Text('Placa ${vehicle.placa.isNotEmpty ? vehicle.placa : 'N/A'}'),
                ),
              ),
            if (vehicle == null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_bike_outlined),
                  title: const Text('Sin vehículo registrado'),
                  subtitle: const Text('N/A'),
                ),
              ),
            const SizedBox(height: 24),
            // ─── CUENTA ───
            Text('CUENTA',
                style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Editar perfil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.editProfile),
                  ),
                  if (!_docsApproved) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Mis documentos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.documents),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                  ListTile(
                    leading: const Icon(Icons.credit_card_outlined),
                    title: const Text('Métodos de cobro'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.paymentMethods),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ─── ACTIVIDAD ───
            Text('ACTIVIDAD',
                style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attach_money_outlined),
                    title: const Text('Ganancias'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.earnings),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Historial de viajes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.rideHistory),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Centro de ayuda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ─── Error ───
            if (vm.errorMessage != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 18, color: scheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.errorMessage!,
                        style: text.bodySmall
                            ?.copyWith(color: scheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            // ─── Logout ───
            TextButton.icon(
              onPressed: () async {
                await vm.logout();
                if (!context.mounted) return;
                context.go(AppRoutes.getstarted);
              },
              icon: Icon(Icons.logout, color: scheme.error),
              label: Text('Cerrar sesión',
                  style: TextStyle(color: scheme.error)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty || name == 'N/A') return 'N/A';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Widget _statItem(String value, String label, TextTheme text) {
    return Column(
      children: [
        Text(value,
            style: text.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
