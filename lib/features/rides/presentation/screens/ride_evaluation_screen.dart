import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../provider/ride_evaluation_viewmodel.dart';

class RideEvaluationScreen extends ConsumerStatefulWidget {
  const RideEvaluationScreen({super.key});

  @override
  ConsumerState<RideEvaluationScreen> createState() =>
      _RideEvaluationScreenState();
}

class _RideEvaluationScreenState
    extends ConsumerState<RideEvaluationScreen> {
  String? _rideId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra;
    if (args is String) {
      _rideId = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(rideEvaluationViewModelProvider);
    final text = Theme.of(context).textTheme;

    if (vm.isSubmitted) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8E5A).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1E8E5A),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Evaluación enviada!',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1410),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gracias por tu retroalimentación',
                    style: text.bodyMedium?.copyWith(
                      color: const Color(0xFF6B6661),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.driverHome),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8F00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Volver al inicio',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluar pasajero'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1E0),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: Color(0xFFFF8F00),
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¿Cómo fue tu pasajero?',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1410),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final starValue = i + 1;
                          return GestureDetector(
                            onTap: () => vm.setCalificacion(starValue),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                starValue <= vm.calificacion
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 44,
                                color: starValue <= vm.calificacion
                                    ? const Color(0xFFFF8F00)
                                    : const Color(0xFFE2E2E2),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _starLabel(vm.calificacion),
                        style: text.bodyMedium?.copyWith(
                          color: const Color(0xFF6B6661),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        maxLines: 3,
                        maxLength: 160,
                        decoration: InputDecoration(
                          hintText: 'Agrega un comentario (opcional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF8F00)),
                          ),
                        ),
                        onChanged: vm.setComentario,
                      ),
                      if (vm.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          vm.errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: vm.isSubmitting || _rideId == null
                      ? null
                      : () => vm.submit(_rideId!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8F00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    vm.isSubmitting
                        ? 'Enviando…'
                        : 'Enviar evaluación',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _starLabel(int stars) {
    switch (stars) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
