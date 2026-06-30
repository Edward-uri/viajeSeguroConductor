import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../../routes/app_routes.dart';
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
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
                    const Icon(Icons.check_circle, color: Color(0xFF1E8E5A), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Documentos aprobados!',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1410),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded,
                      color: Color(0xFFFF8F00), size: 48),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Registra tu primer vehículo',
                textAlign: TextAlign.center,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Necesitas al menos un vehículo aprobado para ponerte en línea y recibir viajes. Puedes registrarlo ahora u omitir y hacerlo después.',
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: const Color(0xFF6B6661)),
              ),
              const Spacer(),
              GradientButton(
                label: 'Registrar mi vehículo',
                onPressed: () => context.push(AppRoutes.vehicleRegister),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.driverHome),
                  child: const Text('Omitir por ahora'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
