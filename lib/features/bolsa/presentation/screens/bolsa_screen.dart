import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/data/providers/municipio_provider.dart';
import '../../../../shared/domain/entities/municipio.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../provider/bolsa_viewmodel.dart';

class BolsaScreen extends ConsumerStatefulWidget {
  const BolsaScreen({super.key});

  @override
  ConsumerState<BolsaScreen> createState() => _BolsaScreenState();
}

class _BolsaScreenState extends ConsumerState<BolsaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(bolsaViewModelProvider).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(bolsaViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final municipios =
        ref.watch(municipiosProvider).value ?? const <Municipio>[];

    ref.listen<String?>(bolsaViewModelProvider.select((v) => v.errorMessage),
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

    final initialLoading =
        vm.isLoading && vm.vacantes.isEmpty && vm.postulaciones.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Bolsa de trabajo')),
      body: SafeArea(
        child: initialLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => ref.read(bolsaViewModelProvider).load(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'VACANTES',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (vm.vacantes.isEmpty)
                      Text(
                        'No hay vacantes abiertas en tu municipio por ahora.',
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      )
                    else
                      ...vm.vacantes.map(
                        (v) => _VacanteCard(
                          vacante: v,
                          municipio: _nombreMunicipio(municipios, v.idMunicipio),
                          postulacion: vm.postulacionDe(v.idVacante),
                          vm: vm,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'MIS POSTULACIONES',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (vm.postulaciones.isEmpty)
                      Text(
                        'Aún no has postulado a ninguna vacante.',
                        style: text.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      )
                    else
                      ...vm.postulaciones.map(
                        (p) => _PostulacionCard(postulacion: p, vm: vm),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _nombreMunicipio(List<Municipio> municipios, int id) {
    for (final m in municipios) {
      if (m.idMunicipio == id) return m.nombre;
    }
    return 'Municipio $id';
  }
}

class _VacanteCard extends StatelessWidget {
  const _VacanteCard({
    required this.vacante,
    required this.municipio,
    required this.postulacion,
    required this.vm,
  });

  final Vacante vacante;
  final String municipio;
  final Postulacion? postulacion;
  final BolsaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final condiciones = vacante.condiciones;
    final miPostulacion = postulacion;

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
                    vacante.descripcionVehiculo,
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    municipio,
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  if (condiciones != null && condiciones.isNotEmpty)
                    Text(condiciones, style: text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (miPostulacion != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EstadoChip(
                    label: miPostulacion.estado.label,
                    color: miPostulacion.estado.color,
                  ),
                  if (miPostulacion.estado == EstadoPostulacion.retirada) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: vm.isWorking
                          ? null
                          : () => vm.postular(vacante.idVacante),
                      child: const Text('Postularme de nuevo'),
                    ),
                  ],
                ],
              )
            else
              TextButton(
                onPressed:
                    vm.isWorking ? null : () => vm.postular(vacante.idVacante),
                child: const Text('Postularme'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PostulacionCard extends StatelessWidget {
  const _PostulacionCard({required this.postulacion, required this.vm});

  final Postulacion postulacion;
  final BolsaViewModel vm;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

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
                    vm.vehiculoDe(postulacion),
                    style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (postulacion.estadoVacante == 'cerrada')
                    Text(
                      'Vacante cerrada',
                      style: text.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _EstadoChip(
              label: postulacion.estado.label,
              color: postulacion.estado.color,
            ),
            if (postulacion.puedeRetirar)
              TextButton(
                onPressed: vm.isWorking
                    ? null
                    : () => vm.retirar(postulacion.idPostulacion),
                child: const Text('Retirar'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mismo patrón visual que el badge de estado en driver_profile_screen.
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
