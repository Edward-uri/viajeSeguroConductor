import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/reputation_chips.dart';
import '../../../../routes/app_routes.dart';
import '../../../../shared/domain/entities/user.dart';
import '../../../../shared/widgets/authed_image.dart';
import '../../../../theme/jala_theme.dart';
import '../../../../theme/theme_mode_provider.dart';
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

Color _estadoColor(BuildContext context, String estado) {
  switch (estado.toLowerCase()) {
    case 'activo':
      return context.brand.success;
    case 'suspendido':
      return context.brand.warning;
    case 'eliminado':
      return context.brand.destructive;
    default:
      return context.colors.onSurfaceVariant;
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

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: vm.isLoading ? null : () => vm.loadData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (vm.isLoading && vm.user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = vm.user;
            if (user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: context.colors.error),
                      const SizedBox(height: 16),
                      Text(
                        vm.errorMessage ?? 'No se pudo cargar el perfil',
                        textAlign: TextAlign.center,
                        style: context.text.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonal(
                        onPressed: () => vm.loadData(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return _ProfileContent(user: user);
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(driverProfileViewModelProvider);
    final scheme = context.colors;
    final text = context.text;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // ─── Avatar ───
        Center(
          child: ClipOval(
            child: Container(
              width: 96,
              height: 96,
              color: scheme.secondaryContainer,
              alignment: Alignment.center,
              child: AuthedImage(
                path: user.fotoPerfilUrl,
                size: 96,
                version: vm.photoVersion,
                fallback: Text(
                  _initials(user.nombreCompleto),
                  style: text.headlineMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ─── Nombre ───
        Center(
          child: Text(
            user.nombreCompleto,
            textAlign: TextAlign.center,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        // ─── Rol · estado (badge de Conductor, estilo del pasajero) ───
        Center(
          child: Text.rich(
            TextSpan(
              text: 'CONDUCTOR · ',
              children: [
                TextSpan(
                  text: _estadoLabel(user.estadoCuenta).toUpperCase(),
                  style: TextStyle(
                    color: _estadoColor(context, user.estadoCuenta),
                  ),
                ),
              ],
            ),
            style: text.labelSmall?.copyWith(
              color: scheme.secondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // ─── Etiquetas de reputación (top-3 inferidas por LLM-JALA) ───
        // El propio widget resuelve carga/error/vacío: si no hay etiquetas
        // no ocupa espacio y el perfil funciona igual sin ellas.
        ReputationChips(idUsuario: user.idUsuario, rol: 'conductor'),
        const SizedBox(height: 32),
        // ─── Cuenta ───
        Text('Cuenta',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _menuTile(
                context,
                Icons.person_outline,
                'Editar perfil',
                () => context.push(AppRoutes.editProfile),
              ),
              _divider(context),
              _menuTile(
                context,
                Icons.description_outlined,
                user.esConductor
                    ? 'Mis documentos'
                    : 'Quiero manejar · Documentos',
                () => context.push(AppRoutes.documents),
              ),
              if (user.esConductor) ...[
                _divider(context),
                _menuTile(
                  context,
                  Icons.work_outline,
                  'Bolsa de trabajo',
                  () => context.push(AppRoutes.bolsa),
                ),
              ] else ...[
                _divider(context),
                ListTile(
                  enabled: false,
                  leading: Icon(Icons.work_outline,
                      color: context.colors.onSurfaceVariant),
                  title: const Text('Bolsa de trabajo'),
                  subtitle: const Text(
                      'Disponible cuando aprueben tu licencia de conductor'),
                  trailing: Icon(Icons.lock_outline,
                      size: 18, color: context.colors.onSurfaceVariant),
                ),
              ],
              if (user.esPropietario) ...[
                _divider(context),
                _menuTile(
                  context,
                  Icons.assignment_outlined,
                  'Mis vacantes',
                  () => context.push(AppRoutes.misVacantes),
                ),
              ],
              _divider(context),
              // Mismo selector de tema que la app pasajero (hoja inferior
              // con claro/oscuro/sistema).
              _menuTile(
                context,
                Icons.dark_mode_outlined,
                'Tema: ${_themeModeLabel(ref.watch(themeModeProvider))}',
                () => _pickThemeMode(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ─── Actividad ───
        Text('Actividad',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _menuTile(
                context,
                Icons.attach_money_outlined,
                'Ganancias',
                () => context.push(AppRoutes.earnings),
              ),
              _divider(context),
              _menuTile(
                context,
                Icons.history_outlined,
                'Historial de viajes',
                () => context.push(AppRoutes.rideHistory),
              ),
            ],
          ),
        ),
        // ─── Error (no bloqueante) ───
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        ],
        const SizedBox(height: 24),
        // ─── Cerrar sesión ───
        OutlinedButton.icon(
          onPressed: () async {
            await vm.logout();
            if (!context.mounted) return;
            context.go(AppRoutes.getstarted);
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  Future<void> _pickThemeMode(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              (ThemeMode.light, Icons.light_mode_outlined, 'Claro'),
              (ThemeMode.dark, Icons.dark_mode_outlined, 'Oscuro'),
              (ThemeMode.system, Icons.brightness_auto_outlined, 'Sistema'),
            ])
              ListTile(
                leading: Icon(entry.$2),
                title: Text(entry.$3),
                trailing: entry.$1 == current
                    ? Icon(Icons.check_rounded, color: context.brand.success)
                    : null,
                onTap: () => Navigator.of(ctx).pop(entry.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      ref.read(themeModeProvider.notifier).setMode(selected);
    }
  }

  String _initials(String name) {
    if (name.isEmpty || name == 'N/A') return 'N/A';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: context.colors.onSurfaceVariant),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      color: context.colors.outlineVariant.withValues(alpha: 0.3),
    );
  }
}
