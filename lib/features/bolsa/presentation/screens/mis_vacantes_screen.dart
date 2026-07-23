import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/vacante.dart';
import '../provider/dueno_vacantes_viewmodel.dart';

class MisVacantesScreen extends ConsumerStatefulWidget {
  const MisVacantesScreen({super.key});

  @override
  ConsumerState<MisVacantesScreen> createState() => _MisVacantesScreenState();
}

class _MisVacantesScreenState extends ConsumerState<MisVacantesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(duenoVacantesViewModelProvider).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(duenoVacantesViewModelProvider);

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

    final initialLoading = vm.isLoading && vm.vacantes.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Mis vacantes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.vacanteForm),
        icon: const Icon(Icons.add),
        label: const Text('Publicar vacante'),
      ),
      body: SafeArea(
        child: initialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref.read(duenoVacantesViewModelProvider).load(),
                child: vm.vacantes.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: const [
                          Text('Aún no has publicado ninguna vacante.'),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: vm.vacantes.length,
                        itemBuilder: (context, i) =>
                            _VacanteCard(vacante: vm.vacantes[i]),
                      ),
              ),
      ),
    );
  }
}

class _VacanteCard extends ConsumerWidget {
  const _VacanteCard({required this.vacante});

  final Vacante vacante;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vm = ref.watch(duenoVacantesViewModelProvider);
    final abierta = vacante.abierta;
    final estadoColor =
        abierta ? context.brand.success : context.brand.greyLight;
    final pendientes = vacante.postulacionesPendientes;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push(AppRoutes.vacantePostulaciones, extra: vacante),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vacante.descripcionVehiculo,
                      style:
                          text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Chip(label: abierta ? 'Abierta' : 'Cerrada', color: estadoColor),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (vacante.turnoLabel.isNotEmpty)
                    _Chip(label: vacante.turnoLabel, color: scheme.primary),
                  if (vacante.rentaLabel.isNotEmpty)
                    Text(
                      '${vacante.rentaLabel} / turno',
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                ],
              ),
              if (vacante.diasLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                _InfoLinea(
                    icon: Icons.calendar_today_outlined,
                    label: vacante.diasLabel),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.people_alt_outlined,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pendientes > 0
                          ? '$pendientes ${pendientes == 1 ? "postulante" : "postulantes"} por revisar'
                          : 'Ver postulantes',
                      style: text.bodyMedium?.copyWith(
                        fontWeight:
                            pendientes > 0 ? FontWeight.w700 : FontWeight.w400,
                        color: pendientes > 0
                            ? context.brand.warning
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (abierta)
                    TextButton(
                      onPressed:
                          vm.isWorking ? null : () => _confirmarCierre(context, ref),
                      child: Text('Cerrar',
                          style: TextStyle(color: scheme.error)),
                    ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarCierre(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cerrar vacante?'),
        content: const Text(
            'Dejará de recibir postulaciones. No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar vacante'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(duenoVacantesViewModelProvider)
          .cerrarVacante(vacante.idVacante);
    }
  }
}

/// Ícono + texto en gris para un término de la vacante (días, horario…).
class _InfoLinea extends StatelessWidget {
  const _InfoLinea({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
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
