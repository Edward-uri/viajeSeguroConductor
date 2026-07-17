import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/jala_theme.dart';
import '../di/core_module.dart';
import '../http/api_endpoints.dart';

class EtiquetaReputacion {
  const EtiquetaReputacion({required this.texto, required this.polaridad});

  factory EtiquetaReputacion.fromJson(Map<String, dynamic> json) =>
      EtiquetaReputacion(
        texto: json['texto'] as String? ?? '',
        polaridad: json['polaridad'] as String? ?? 'positiva',
      );

  final String texto;
  final String polaridad;
}

/// Top-3 de etiquetas de reputación de un usuario (las infiere LLM-JALA
/// a partir de las evaluaciones; el backend las agrega por ventana).
final etiquetasReputacionProvider = FutureProvider.autoDispose
    .family<List<EtiquetaReputacion>, ({int idUsuario, String rol})>(
        (ref, args) async {
  final api = ref.watch(apiClientProvider);
  final json =
      await api.get(ApiEndpoints.usuarioEtiquetas(args.idUsuario, args.rol));
  final data = json['data'] as List<dynamic>? ?? const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(EtiquetaReputacion.fromJson)
      .where((e) => e.texto.isNotEmpty)
      .toList();
});

/// Chips con las etiquetas de reputación de un usuario. Si no hay etiquetas
/// o el fetch falla, no ocupa espacio: la pantalla funciona igual sin ellas.
class ReputationChips extends ConsumerWidget {
  const ReputationChips({
    super.key,
    required this.idUsuario,
    required this.rol,
  });

  final int idUsuario;

  /// 'conductor' o 'pasajero' (el rol del usuario evaluado).
  final String rol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final etiquetas = ref
            .watch(etiquetasReputacionProvider((idUsuario: idUsuario, rol: rol)))
            .valueOrNull ??
        const <EtiquetaReputacion>[];
    if (etiquetas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [for (final e in etiquetas) _chip(context, e)],
      ),
    );
  }

  Widget _chip(BuildContext context, EtiquetaReputacion e) {
    final positiva = e.polaridad == 'positiva';
    final fondo =
        positiva ? context.brand.successLight : context.brand.accentSurface;
    final colorTexto =
        positiva ? context.brand.success : context.brand.greyDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        e.texto,
        style: context.text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorTexto,
        ),
      ),
    );
  }
}
