import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/entities/documento.dart';

class DocumentViewScreen extends ConsumerWidget {
  const DocumentViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = GoRouterState.of(context).extra as Documento?;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(doc?.nombre ?? 'Documento')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (doc?.status == DocumentStatus.rejected) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.error.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doc?.rejectionReason ?? 'Documento rechazado',
                          style: text.bodySmall?.copyWith(color: scheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    Icons.description_outlined,
                    size: 64,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (doc?.fileName != null) ...[
                Text(
                  'Archivo: ${doc!.fileName}',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (doc.uploadedDate != null)
                  Text(
                    'Subido el ${doc.uploadedDate}',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
              const Spacer(),
              if (doc?.status == DocumentStatus.rejected)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.pushReplacement(
                      AppRoutes.documentUpload,
                      extra: doc,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a subir'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
