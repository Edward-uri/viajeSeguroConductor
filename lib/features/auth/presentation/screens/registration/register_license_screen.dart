import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';

class RegisterLicenseScreen extends ConsumerStatefulWidget {
  const RegisterLicenseScreen({super.key});

  @override
  ConsumerState<RegisterLicenseScreen> createState() =>
      _RegisterLicenseScreenState();
}

class _RegisterLicenseScreenState extends ConsumerState<RegisterLicenseScreen> {
  final _numberController = TextEditingController();
  final _expeditionController = TextEditingController();
  final _expirationController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _expeditionController.dispose();
    _expirationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
    );
    if (date != null) {
      ctrl.text =
          '${date.day.toString().padLeft(2, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.year}';
    }
  }

  Future<void> _onContinue() async {
    final vm = ref.read(registerViewModelProvider);
    vm.setLicencia(_numberController.text);
    vm.setLicenciaFechaExpedicion(_expeditionController.text);
    vm.setLicenciaFechaVencimiento(_expirationController.text);
    final ok = await vm.completeRegistration();
    if (ok && context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.documents,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(registerViewModelProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Datos de tu licencia',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa los datos tal como aparecen en tu licencia de conducir.',
                style: text.bodyMedium?.copyWith(
                  color: const Color(0xFF6B6661),
                ),
              ),
              const SizedBox(height: 32),
              _FieldLabel('Número de licencia'),
              const SizedBox(height: 6),
              _TextField(
                controller: _numberController,
                hint: 'ABC123456',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              _FieldLabel('Fecha de expedición'),
              const SizedBox(height: 6),
              _DateField(
                controller: _expeditionController,
                hint: '15 / 03 / 2022',
                onTap: () => _pickDate(_expeditionController),
              ),
              const SizedBox(height: 20),
              _FieldLabel('Fecha de vencimiento'),
              const SizedBox(height: 6),
              _DateField(
                controller: _expirationController,
                hint: '15 / 03 / 2027',
                onTap: () => _pickDate(_expirationController),
              ),
              if (vm.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  vm.errorMessage!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFD84315),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Color(0xFFFF8F00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Verificaremos que tu licencia esté vigente.',
                        style: text.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8A5A12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: vm.isLoading ? 'Creando cuenta...' : 'Continuar',
                onPressed: !vm.isLoading ? _onContinue : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1410),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputAction textInputAction;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1A1410),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B6661),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF8F00)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onTap;

  const _DateField({
    required this.controller,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1A1410),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: Color(0xFF6B6661),
        ),
        suffixIcon: const Icon(
          Icons.calendar_today_outlined,
          color: Color(0xFF6B6661),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF8F00)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      onTap: onTap,
    );
  }
}
