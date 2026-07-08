import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
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
            backgroundColor: Colors.red.shade700,
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

class _VacanteCard extends ConsumerStatefulWidget {
  const _VacanteCard({required this.vacante});

  final Vacante vacante;

  @override
  ConsumerState<_VacanteCard> createState() => _VacanteCardState();
}

class _VacanteCardState extends ConsumerState<_VacanteCard> {
  bool _confirmandoCierre = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final vm = ref.watch(duenoVacantesViewModelProvider);
    final vacante = widget.vacante;
    final abierta = vacante.abierta;
    final color = abierta ? const Color(0xFF1E8E5A) : const Color(0xFF9E9E9E);

    return Card(
      child: ListTile(
        onTap: () => context.push(AppRoutes.vacantePostulaciones, extra: vacante),
        title: Text(
          vacante.descripcionVehiculo,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            _EstadoChip(
              label: abierta ? 'Abierta' : 'Cerrada',
              color: color,
            ),
            if (vacante.postulacionesPendientes > 0) ...[
              const SizedBox(width: 8),
              _EstadoChip(
                label: '${vacante.postulacionesPendientes} pendientes',
                color: const Color(0xFFE8A317),
              ),
            ],
          ],
        ),
        trailing: abierta
            ? TextButton(
                onPressed: vm.isWorking
                    ? null
                    : () {
                        if (_confirmandoCierre) {
                          ref
                              .read(duenoVacantesViewModelProvider)
                              .cerrarVacante(vacante.idVacante);
                        } else {
                          setState(() => _confirmandoCierre = true);
                        }
                      },
                child: Text(
                  _confirmandoCierre ? '¿Confirmar cierre?' : 'Cerrar',
                  style: _confirmandoCierre
                      ? TextStyle(color: scheme.error)
                      : null,
                ),
              )
            : const Icon(Icons.chevron_right),
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
