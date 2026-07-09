import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/theme.dart';
import '../../domain/entities/documento.dart';
import '../provider/documents_viewmodel.dart';

class DocumentsReviewScreen extends ConsumerStatefulWidget {
  const DocumentsReviewScreen({super.key});

  @override
  ConsumerState<DocumentsReviewScreen> createState() =>
      _DocumentsReviewScreenState();
}

class _DocumentsReviewScreenState extends ConsumerState<DocumentsReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(documentsViewModelProvider).loadDocumentos(),
    );
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Documentos')),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        Icons.hourglass_top,
                        color: scheme.onSecondaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'En revisión',
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Revisamos tus documentos (1-2 días).',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: vm.totalCount > 0
                                  ? vm.approvedCount / vm.totalCount
                                  : 0,
                              minHeight: 6,
                              backgroundColor: scheme.surfaceContainerLowest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: vm.documentos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final doc = vm.documentos[i];
                    return _DocCard(
                      doc: doc,
                      statusColor: _statusColor(scheme, doc.status),
                      iconBgColor: _iconBgColor(scheme, doc.status),
                      statusLabel: _statusLabel(doc.status),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Documento doc;
  final Color statusColor;
  final Color iconBgColor;
  final String statusLabel;

  const _DocCard({
    required this.doc,
    required this.statusColor,
    required this.iconBgColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
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
              child: Text(
                doc.nombre,
                style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}
