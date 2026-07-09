import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routes/app_routes.dart';
import '../../../../../shared/data/providers/municipio_provider.dart';
import '../../../../../shared/domain/entities/municipio.dart';
import '../../provider/register_viewmodel.dart';
import 'paso_registro_scaffold.dart';

class RegisterMunicipioScreen extends ConsumerStatefulWidget {
  const RegisterMunicipioScreen({super.key});

  @override
  ConsumerState<RegisterMunicipioScreen> createState() =>
      _RegisterMunicipioScreenState();
}

class _RegisterMunicipioScreenState
    extends ConsumerState<RegisterMunicipioScreen> {
  Municipio? _selected;

  Future<void> _onContinue() async {
    if (_selected == null) return;
    final vm = ref.read(registerViewModelProvider);
    vm.setIdMunicipio(_selected!.idMunicipio);
    final ok = await vm.completeRegistration();
    if (ok && context.mounted) {
      // Ya autenticado: paso opcional de foto de perfil antes de entrar a la app.
      context.go(AppRoutes.registerPhoto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final municipios = ref.watch(municipiosProvider);
    final vm = ref.watch(registerViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return PasoRegistroScaffold(
      paso: 5,
      titulo: 'Tu municipio',
      caption: 'Selecciona el municipio donde operarás.',
      ctaLabel: vm.isLoading ? 'Creando cuenta...' : 'Continuar',
      onCta: (_selected == null || vm.isLoading) ? null : _onContinue,
      children: [
        municipios.when(
          data: (lista) => DropdownButtonFormField<Municipio>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'Municipio',
            ),
            items: lista
                .map((m) => DropdownMenuItem<Municipio>(
                      value: m,
                      child: Text('${m.nombre}, ${m.estado}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(
            'Error al cargar municipios: $e',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        if (vm.errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            vm.errorMessage!,
            style: text.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }
}
