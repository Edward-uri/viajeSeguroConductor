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
    final color = abierta ? context.brand.success : context.brand.greyLight;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        onTap: () =>
            context.push(AppRoutes.vacantePostulaciones, extra: vacante),
        title: Text(
          vacante.descripcionVehiculo,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _EstadoChip(label: abierta ? 'Abierta' : 'Cerrada', color: color),
              if (vacante.postulacionesPendientes > 0)
                _EstadoChip(
                  label: '${vacante.postulacionesPendientes} pendientes',
                  color: context.brand.warning,
                ),
            ],
          ),
        ),
        trailing: abierta
            ? IconButton(
                tooltip: 'Cerrar vacante',
                icon: Icon(Icons.close_rounded, color: scheme.error),
                onPressed:
                    vm.isWorking ? null : () => _confirmarCierre(context, ref),
              )
            : const Icon(Icons.chevron_right),
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

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
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
