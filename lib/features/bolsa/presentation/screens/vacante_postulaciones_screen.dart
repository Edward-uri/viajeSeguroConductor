import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/authed_image.dart';
import '../../../../theme/jala_theme.dart';
import '../../domain/entities/postulacion.dart';
import '../../domain/entities/vacante.dart';
import '../provider/dueno_vacantes_viewmodel.dart';

/// Detalle de una vacante del dueño: arriba la configuración de la oferta
/// (turno, renta, días, horario, condiciones) que ya viene en [vacante]; abajo
/// la lista de conductores postulados con opción de aceptar/asignar.
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
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    ref.listen<String?>(
        duenoVacantesViewModelProvider.select((v) => v.errorMessage),
        (_, msg) {
      if (msg != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: scheme.error,
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

    final postulaciones = vm.postulaciones;
    final cargando = vm.isLoading && postulaciones.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(vacante.descripcionVehiculo)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref
              .read(duenoVacantesViewModelProvider)
              .loadPostulaciones(vacante.idVacante),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              _ConfigCard(vacante: vacante),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'POSTULANTES',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!cargando)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${postulaciones.length}',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (cargando)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (postulaciones.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Aún no hay postulaciones para esta vacante.',
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                )
              else
                ...postulaciones.map(
                  (p) => _PostulacionCard(
                    postulacion: p,
                    idVacante: vacante.idVacante,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resumen de los términos de la oferta. Todo sale de [vacante] (ya cargada en
/// mis-vacantes), sin llamada extra.
class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.vacante});

  final Vacante vacante;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final abierta = vacante.abierta;
    final estadoColor =
        abierta ? context.brand.success : context.brand.greyLight;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vacante.turnoLabel.isNotEmpty
                        ? vacante.turnoLabel
                        : 'Términos de la vacante',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                _Chip(label: abierta ? 'Abierta' : 'Cerrada', color: estadoColor),
              ],
            ),
            if (vacante.rentaLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    vacante.rentaLabel,
                    style: text.headlineSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'de renta por turno',
                    style:
                        text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (vacante.diasLabel.isNotEmpty)
              _InfoLinea(
                  icon: Icons.calendar_today_outlined,
                  label: vacante.diasLabel),
            if (vacante.horario != null && vacante.horario!.isNotEmpty)
              _InfoLinea(icon: Icons.schedule_outlined, label: vacante.horario!),
            if (vacante.condiciones != null && vacante.condiciones!.isNotEmpty)
              _InfoLinea(
                  icon: Icons.info_outline, label: vacante.condiciones!),
          ],
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
    final scheme = Theme.of(context).colorScheme;
    final vm = ref.watch(duenoVacantesViewModelProvider);
    final calificacion = postulacion.conductorCalificacion;
    final mensaje = postulacion.mensaje;
    final esPendiente = postulacion.estado == EstadoPostulacion.pendiente;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Avatar(
                  nombre: postulacion.conductorNombre,
                  fotoPath: postulacion.conductorFotoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postulacion.conductorNombre ?? 'Conductor',
                        style: text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.star,
                              size: 15, color: context.brand.warning),
                          const SizedBox(width: 3),
                          Text(
                            calificacion != null
                                ? calificacion.toStringAsFixed(1)
                                : 'Sin calificación',
                            style: text.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: postulacion.estado.label,
                  color: postulacion.estado.color,
                ),
              ],
            ),
            if (mensaje != null && mensaje.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(mensaje, style: text.bodySmall),
              ),
            ],
            if (esPendiente) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: vm.isWorking
                      ? null
                      : () => ref
                          .read(duenoVacantesViewModelProvider)
                          .aceptarPostulacion(
                              postulacion.idPostulacion, idVacante),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Aceptar y asignar conductor'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Foto del conductor (protegida por token) con fallback a iniciales.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.nombre, required this.fotoPath});

  final String? nombre;
  final String? fotoPath;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = 48.0;
    final fallback = Container(
      width: size,
      height: size,
      color: scheme.secondaryContainer,
      alignment: Alignment.center,
      child: Text(
        _iniciales(nombre),
        style: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
    return ClipOval(
      child: (fotoPath == null || fotoPath!.isEmpty)
          ? fallback
          : AuthedImage(path: fotoPath, size: size, fallback: fallback),
    );
  }

  static String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '?';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final a = partes.first.isNotEmpty ? partes.first[0] : '';
    final b = partes.length > 1 && partes[1].isNotEmpty ? partes[1][0] : '';
    final ini = (a + b).toUpperCase();
    return ini.isEmpty ? '?' : ini;
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style:
                  text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
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
