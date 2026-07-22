import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
import '../../../../theme/theme.dart';
import '../../../vehicle/presentation/provider/vehicle_viewmodel.dart';
import '../../domain/entities/documento.dart';
import '../provider/documents_viewmodel.dart';

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() =>
      _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentsViewModelProvider).loadDocumentos();
      // Para saber si ya es un conductor con flotilla (no onboarding).
      ref.read(vehicleViewModelProvider).loadVehiculos();
    });
  }

  Color _statusColor(ColorScheme scheme, DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return JalaBrand.success;
      case DocumentStatus.reviewing:
        return scheme.onSecondaryContainer;
      case DocumentStatus.rejected:
        return scheme.error;
      case DocumentStatus.pending:
        return scheme.onSurfaceVariant;
    }
  }

  Color _iconBgColor(ColorScheme scheme, DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return JalaBrand.success.withValues(alpha: 0.12);
      case DocumentStatus.reviewing:
        return scheme.secondaryContainer;
      case DocumentStatus.rejected:
        return scheme.error.withValues(alpha: 0.12);
      case DocumentStatus.pending:
        return scheme.surfaceContainerHigh;
    }
  }

  String _statusLabel(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return 'Aprobado';
      case DocumentStatus.reviewing:
        return 'En revisión';
      case DocumentStatus.rejected:
        return 'Rechazado';
      case DocumentStatus.pending:
        return 'Toca para subir';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(documentsViewModelProvider);
    // Ya tiene al menos un vehículo => es gestión, no onboarding: no mostramos
    // el CTA de "registra tu primer vehículo".
    final tieneVehiculos = ref.watch(
      vehicleViewModelProvider.select((v) => v.vehiculos.isNotEmpty),
    );
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Sube tus documentos',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Te habilitamos para conducir en cuanto los aprobemos.',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _ProgressCard(
                approvedCount: vm.approvedCount,
                totalCount: vm.totalCount,
              ),
              if (vm.allApproved || vm.hasRejected) ...[
                const SizedBox(height: 12),
                _StatusBanner(approved: vm.allApproved),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(documentsViewModelProvider).loadDocumentos(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: vm.documentos.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = vm.documentos[i];
                      return _DocumentCard(
                        doc: doc,
                        statusColor: _statusColor(scheme, doc.status),
                        iconBgColor: _iconBgColor(scheme, doc.status),
                        statusLabel: _statusLabel(doc.status),
                        onTap: doc.status == DocumentStatus.pending
                            ? () => context.push(AppRoutes.documentUpload, extra: doc)
                            : doc.status == DocumentStatus.rejected
                                ? () => context.push(AppRoutes.documentView, extra: doc)
                                : null,
                      );
                    },
                  ),
                ),
              ),
              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: tieneVehiculos
                    // Conductor con vehículos: solo gestiona documentos, sin
                    // el flujo de onboarding "registra tu primer vehículo".
                    ? GradientButton(
                        label: 'Listo',
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go(AppRoutes.driverHome),
                      )
                    : GradientButton(
                        label: 'Continuar',
                        onPressed: vm.allApproved
                            ? () => context.push(AppRoutes.documentsApproved)
                            : null,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final bool approved;
  const _StatusBanner({required this.approved});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = approved ? JalaBrand.success : scheme.error;
    final icon = approved ? Icons.check_circle_rounded : Icons.error_rounded;
    final msg = approved
        ? '¡Documentos aprobados! Toca Continuar para seguir.'
        : 'Un documento fue rechazado. Tócalo para corregirlo.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int approvedCount;
  final int totalCount;

  const _ProgressCard({
    required this.approvedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final progress = totalCount > 0 ? approvedCount / totalCount : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.description_outlined,
                color: scheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completa tus documentos',
                    style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$approvedCount de $totalCount aprobados',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        JalaBrand.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Documento doc;
  final Color statusColor;
  final Color iconBgColor;
  final String statusLabel;
  final VoidCallback? onTap;

  const _DocumentCard({
    required this.doc,
    required this.statusColor,
    required this.iconBgColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.nombre,
                      style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (doc.status == DocumentStatus.rejected &&
                        doc.rejectionReason != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doc.rejectionReason!,
                        style: text.bodySmall?.copyWith(color: scheme.error),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
