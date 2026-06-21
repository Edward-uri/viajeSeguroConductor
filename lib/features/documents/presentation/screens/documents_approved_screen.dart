import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/documento.dart';
import '../provider/documents_viewmodel.dart';

class DocumentsApprovedScreen extends ConsumerStatefulWidget {
  const DocumentsApprovedScreen({super.key});

  @override
  ConsumerState<DocumentsApprovedScreen> createState() =>
      _DocumentsApprovedScreenState();
}

class _DocumentsApprovedScreenState
    extends ConsumerState<DocumentsApprovedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(documentsViewModelProvider).loadDocumentos(),
    );
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
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA8DCBE)),
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
                        Icons.check_circle,
                        color: Color(0xFF1E8E5A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¡Listo para conducir!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1410),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tus documentos fueron aprobados.',
                            style: text.bodySmall?.copyWith(
                              color: const Color(0xFF6B6661),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: 1,
                              minHeight: 6,
                              backgroundColor: Colors.white,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E8E5A),
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
                    return _DocCard(doc: doc);
                  },
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                label: 'Empezar a conducir',
                onPressed: () =>
                    Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.driverHome,
                  (route) => false,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final Documento doc;

  const _DocCard({required this.doc});

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
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF1E8E5A),
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
              color: const Color(0xFF1E8E5A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Aprobado',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E8E5A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
