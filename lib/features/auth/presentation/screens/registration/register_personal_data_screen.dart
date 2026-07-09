import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';
import 'paso_registro_scaffold.dart';

class RegisterPersonalDataScreen extends ConsumerStatefulWidget {
  const RegisterPersonalDataScreen({super.key});

  @override
  ConsumerState<RegisterPersonalDataScreen> createState() =>
      _RegisterPersonalDataScreenState();
}

class _RegisterPersonalDataScreenState
    extends ConsumerState<RegisterPersonalDataScreen> {
  int? _selectedSexo;
  final _bdayController = TextEditingController();

  static const _sexos = [
    (1, 'Masculino'),
    (2, 'Femenino'),
    (3, 'Prefiero no decirlo'),
  ];

  @override
  void dispose() {
    _bdayController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
    );
    if (date != null && mounted) {
      _bdayController.text =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      ref.read(registerViewModelProvider).setFechaNacimiento(_bdayController.text);
    }
  }

  void _onContinue() {
    if (_selectedSexo == null) return;
    ref.read(registerViewModelProvider).setIdSexo(_selectedSexo);
    context.push(AppRoutes.registerMunicipio);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return PasoRegistroScaffold(
      paso: 4,
      titulo: 'Información adicional',
      caption: 'Ayúdanos con algunos datos más.',
      ctaLabel: 'Continuar',
      onCta: _selectedSexo == null ? null : _onContinue,
      children: [
        Text(
          'Sexo',
          style: text.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ..._sexos.map((s) => RadioListTile<int>(
              title: Text(s.$2),
              value: s.$1,
              groupValue: _selectedSexo,
              onChanged: (v) => setState(() => _selectedSexo = v),
              contentPadding: EdgeInsets.zero,
            )),
        const SizedBox(height: 24),
        TextField(
          controller: _bdayController,
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Fecha de nacimiento',
            hintText: 'Selecciona tu fecha',
            suffixIcon: Icon(Icons.calendar_today_outlined,
                color: scheme.onSurfaceVariant, size: 20),
          ),
          onTap: _pickDate,
        ),
      ],
    );
  }
}
