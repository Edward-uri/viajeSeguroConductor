import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/gradient_button.dart';
import '../../../../../routes/app_routes.dart';
import '../../provider/register_viewmodel.dart';

class RegisterLastnamesScreen extends ConsumerStatefulWidget {
  const RegisterLastnamesScreen({super.key});

  @override
  ConsumerState<RegisterLastnamesScreen> createState() =>
      _RegisterLastnamesScreenState();
}

class _RegisterLastnamesScreenState
    extends ConsumerState<RegisterLastnamesScreen> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _firstController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final vm = ref.read(registerViewModelProvider);
    vm.setApellidoPaterno(_firstController.text.trim());
    vm.setApellidoMaterno(_secondController.text.trim());
    Navigator.of(context).pushNamed(AppRoutes.registerPersonalData);
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
              const Spacer(flex: 2),
              Text(
                'Completa tu perfil',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ayúdanos proporcionando tus apellidos',
                style: text.bodyLarge?.copyWith(
                  color: const Color(0xFF6B6661),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Primer apellido',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _firstController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1410),
                ),
                decoration: const InputDecoration(
                  hintText: 'Perez',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB6B3B1),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFFF8F00)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Segundo apellido',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _secondController,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1410),
                ),
                decoration: const InputDecoration(
                  hintText: 'Cruz',
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB6B3B1),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFD0D0D0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFFFF8F00)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const Spacer(flex: 3),
              GradientButton(
                label: 'Continuar',
                onPressed: _firstController.text.trim().isEmpty
                    ? null
                    : _onContinue,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Jala',
                  style: text.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1410),
                  ),
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
