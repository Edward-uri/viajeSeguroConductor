import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../../../../shared/data/providers/municipio_provider.dart';
import '../../../../../shared/domain/entities/municipio.dart';
import '../../provider/register_viewmodel.dart';

class RegisterMunicipioScreen extends ConsumerStatefulWidget {
  const RegisterMunicipioScreen({super.key});

  @override
  ConsumerState<RegisterMunicipioScreen> createState() =>
      _RegisterMunicipioScreenState();
}

class _RegisterMunicipioScreenState extends ConsumerState<RegisterMunicipioScreen> {
  Municipio? _selected;

  void _onContinue() {
    if (_selected == null) return;
    ref.read(registerViewModelProvider).setIdMunicipio(_selected!.idMunicipio);
    context.push(AppRoutes.license);
  }

  @override
  Widget build(BuildContext context) {
    final municipios = ref.watch(municipiosProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tu municipio',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el municipio donde operarás.',
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              municipios.when(
                data: (lista) => DropdownButtonFormField<Municipio>(
                  initialValue: _selected,
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                  ),
                  items: lista.map((m) => DropdownMenuItem<Municipio>(
                        value: m,
                        child: Text('${m.nombre}, ${m.estado}'),
                      )).toList(),
                  onChanged: (v) => setState(() => _selected = v),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error al cargar municipios: $e'),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Continuar',
                onPressed: _selected == null ? null : _onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
