import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../theme/theme.dart';
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
      return JalaBrand.success;
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverProfileViewModelProvider).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(driverProfileViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (vm.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = vm.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(isLandscape ? 16 : 24),
          children: [
            // ─── Avatar ───
            Center(
              child: ClipOval(
                child: Container(
                  width: 88,
                  height: 88,
                  color: JalaBrand.amber,
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
            const SizedBox(height: 6),
            // ─── Rol · estado ───
            if (user != null)
              Center(
                child: Text.rich(
                  TextSpan(
                    text: '${user.rol.toUpperCase()} · ',
                    children: [
                      TextSpan(
                        text: _estadoLabel(user.estadoCuenta),
                        style: TextStyle(
                          color: _estadoColor(user.estadoCuenta),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            SizedBox(height: isLandscape ? 16 : 32),
            // ─── Stats ───
            Row(
              children: [
                Expanded(
                  child: _statItem(
                    vm.stats?.calificacion?.toStringAsFixed(1) ?? '0',
                    'Calificación',
                    text,
                  ),
                ),
                Expanded(
                  child: _statItem('${vm.viajes}', 'Viajes', text),
                ),
                Expanded(
                  child: _statItem(
                    vm.stats?.tasaAceptacion?.toStringAsFixed(0) ?? '0',
                    'Aceptación',
                    text,
                  ),
                ),
              ],
            ),
            SizedBox(height: isLandscape ? 16 : 32),
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
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(user != null && user.esConductor
                        ? 'Mis documentos'
                        : 'Quiero manejar · Documentos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.documents),
                  ),
                  if (user != null && user.esConductor) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.work_outline),
                      title: const Text('Bolsa de trabajo'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.bolsa),
                    ),
                  ],
                  if (user != null && user.esPropietario) ...[
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.assignment_outlined),
                      title: const Text('Mis vacantes'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.misVacantes),
                    ),
                  ],
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.credit_card_outlined),
                    title: const Text('Métodos de cobro'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRoutes.paymentMethods),
                  ),
                ],
              ),
            ),
            SizedBox(height: isLandscape ? 16 : 24),
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
        const SizedBox(height: 2),
        Text(label,
            style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
