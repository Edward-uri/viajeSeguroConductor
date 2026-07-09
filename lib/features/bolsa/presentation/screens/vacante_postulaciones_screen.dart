import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../provider/dueno_vacantes_viewmodel.dart';

class VacantePostulacionesScreen extends ConsumerStatefulWidget {
  const VacantePostulacionesScreen({super.key, required this.vacante});

  final Vacante? vacante;

  @override
  ConsumerState<VacantePostulacionesScreen> createState() =>
      _VacantePostulacionesScreenState();
}

class _VacantePostulacionesScreenState
    extends ConsumerState<VacantePostulacionesScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.vacante != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref
            .read(duenoVacantesViewModelProvider)
            .loadPostulaciones(widget.vacante!.idVacante),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vacante = widget.vacante;
    if (vacante == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Postulaciones')),
        body: const Center(child: Text('Vacante no encontrada')),
      );
    }

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

    ref.listen<String?>(
        duenoVacantesViewModelProvider.select((v) => v.successMessage),
        (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
        );
      }
    });

    final initialLoading = vm.isLoading && vm.postulaciones.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(vacante.descripcionVehiculo)),
      body: SafeArea(
        child: initialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(duenoVacantesViewModelProvider)
                    .loadPostulaciones(vacante.idVacante),
                child: vm.postulaciones.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: const [
                          Text('Aún no hay postulaciones para esta vacante.'),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: vm.postulaciones.length,
                        itemBuilder: (context, i) => _PostulacionCard(
                          postulacion: vm.postulaciones[i],
                          idVacante: vacante.idVacante,
                        ),
                      ),
              ),
      ),
    );
  }
}

class _PostulacionCard extends ConsumerWidget {
  const _PostulacionCard({required this.postulacion, required this.idVacante});

  final Postulacion postulacion;
  final int idVacante;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final vm = ref.watch(duenoVacantesViewModelProvider);
    final calificacion = postulacion.conductorCalificacion;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    postulacion.conductorNombre ?? 'Conductor',
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (calificacion != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFE8A317)),
                        const SizedBox(width: 2),
                        Text(calificacion.toStringAsFixed(1),
                            style: text.bodySmall),
                      ],
                    ),
                  if (postulacion.mensaje != null &&
                      postulacion.mensaje!.isNotEmpty)
                    Text(postulacion.mensaje!, style: text.bodySmall),
                  const SizedBox(height: 4),
                  _EstadoChip(
                    label: postulacion.estado.label,
                    color: postulacion.estado.color,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (postulacion.estado == EstadoPostulacion.pendiente)
              FilledButton(
                onPressed: vm.isWorking
                    ? null
                    : () => ref
                        .read(duenoVacantesViewModelProvider)
                        .aceptarPostulacion(postulacion.idPostulacion, idVacante),
                child: const Text('Aceptar'),
              ),
          ],
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
