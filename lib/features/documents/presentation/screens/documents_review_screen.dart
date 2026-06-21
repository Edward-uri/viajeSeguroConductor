import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Color _statusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return const Color(0xFF1E8E5A);
      case DocumentStatus.reviewing:
        return const Color(0xFFE8A317);
      case DocumentStatus.rejected:
        return const Color(0xFFD84315);
      case DocumentStatus.pending:
        return const Color(0xFFFF8F00);
    }
  }

  Color _iconBgColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.approved:
        return const Color(0xFFE6F4EA);
      case DocumentStatus.reviewing:
        return const Color(0xFFFDF3DD);
      case DocumentStatus.rejected:
        return const Color(0xFFFCEAE6);
      case DocumentStatus.pending:
        return const Color(0xFFFFF1E0);
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
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Te habilitamos para conducir en cuanto los aprobemos.',
                style: text.bodyMedium?.copyWith(
                  color: const Color(0xFF6B6661),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF3DD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF2D98A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.hourglass_top,
                        color: Color(0xFFE8A317),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'En revisión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1410),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Revisamos tus documentos (1-2 días).',
                            style: text.bodySmall?.copyWith(
                              color: const Color(0xFF6B6661),
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
                              backgroundColor: Colors.white,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFFE8A317),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: vm.documentos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = vm.documentos[i];
                    return _DocCard(
                      doc: doc,
                      statusColor: _statusColor(doc.status),
                      iconBgColor: _iconBgColor(doc.status),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1410),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
