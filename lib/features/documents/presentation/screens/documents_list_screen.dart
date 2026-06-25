import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';
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
              _ProgressCard(
                approvedCount: vm.approvedCount,
                totalCount: vm.totalCount,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: vm.documentos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final doc = vm.documentos[i];
                    return _DocumentCard(
                      doc: doc,
                      statusColor: _statusColor(doc.status),
                      iconBgColor: _iconBgColor(doc.status),
                      statusLabel: _statusLabel(doc.status),
                      onTap: doc.status == DocumentStatus.approved
                      ? null
                      : () {
                          if (doc.status == DocumentStatus.pending) {
                            Navigator.of(context).pushNamed(
                              AppRoutes.documentUpload,
                              arguments: doc,
                            );
                          } else {
                            Navigator.of(context).pushNamed(
                              AppRoutes.documentView,
                              arguments: doc,
                            );
                          }
                        },
                    );
                  },
                ),
              ),
              if (vm.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
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
    final progress = totalCount > 0 ? approvedCount / totalCount : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(16),
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
              Icons.description_outlined,
              color: Color(0xFF1A1410),
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$approvedCount de $totalCount aprobados',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6661),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFDADADA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF8F00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1410),
                    ),
                  ),
                  if (doc.status == DocumentStatus.rejected &&
                      doc.rejectionReason != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      doc.rejectionReason!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9A3B1E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFC4C4C4)),
          ],
        ),
      ),
    );
  }
}
