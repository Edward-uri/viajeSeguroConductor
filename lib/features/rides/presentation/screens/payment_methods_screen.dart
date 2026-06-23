import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/metodo_cobro_viewmodel.dart';
import '../../domain/entities/metodo_cobro.dart';

class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  ConsumerState<PaymentMethodsScreen> createState() =>
      _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  final _clabeController = TextEditingController();
  final _bankController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedMethod = 'transferencia';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(metodoCobroViewModelProvider.notifier).load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final vm = ref.watch(metodoCobroViewModelProvider);
    final mc = vm.metodoCobro;
    if (mc != null) {
      if (_clabeController.text.isEmpty) {
        _clabeController.text = mc.clabe;
        _bankController.text = mc.banco;
        _nameController.text = mc.titular;
        _selectedMethod = mc.tipo;
      }
    }
  }

  @override
  void dispose() {
    _clabeController.dispose();
    _bankController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(metodoCobroViewModelProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de cobro')),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecciona tu método de cobro',
                            style: text.bodyMedium?.copyWith(
                              color: const Color(0xFF6B6661),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _MethodOption(
                            icon: Icons.account_balance,
                            title: 'Transferencia bancaria',
                            selected: _selectedMethod == 'transferencia',
                            onTap: () => setState(
                                () => _selectedMethod = 'transferencia'),
                          ),
                          const SizedBox(height: 12),
                          _MethodOption(
                            icon: Icons.payments_outlined,
                            title: 'Efectivo',
                            subtitle: 'Cobras en el momento',
                            selected: _selectedMethod == 'efectivo',
                            onTap: () =>
                                setState(() => _selectedMethod = 'efectivo'),
                          ),
                          const SizedBox(height: 12),
                          _MethodOption(
                            icon: Icons.credit_card_outlined,
                            title: 'Tarjeta de débito',
                            subtitle: 'Próximamente',
                            selected: _selectedMethod == 'tarjeta',
                            onTap: null,
                          ),
                          if (_selectedMethod == 'transferencia') ...[
                            const SizedBox(height: 32),
                            const Text(
                              'CLABE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1410),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _clabeController,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A1410),
                              ),
                              decoration: _inputDecoration('18 dígitos'),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Banco',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1410),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _bankController,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A1410),
                              ),
                              decoration: _inputDecoration('Nombre del banco'),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Titular',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1410),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _nameController,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF1A1410),
                              ),
                              decoration:
                                  _inputDecoration('Nombre del titular'),
                            ),
                          ],
                          if (vm.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: vm.noDisponible
                                    ? const Color(0xFFE3F2FD)
                                    : Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(vm.errorMessage!,
                                  style: TextStyle(
                                      color: vm.noDisponible
                                          ? const Color(0xFF1565C0)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer)),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: vm.isSaving || vm.noDisponible
                            ? null
                            : _guardar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: vm.isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Guardar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _guardar() async {
    final mc = MetodoCobro(
      tipo: _selectedMethod,
      clabe: _clabeController.text,
      banco: _bankController.text,
      titular: _nameController.text,
    );
    final success =
        await ref.read(metodoCobroViewModelProvider.notifier).save(mc);
    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 15,
        color: Color(0xFFB6B3B1),
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
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _MethodOption({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    this.onTap,
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
          border: Border.all(
            color: selected ? const Color(0xFFFF8F00) : const Color(0xFFECECEC),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFFFF1E0)
                    : const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? const Color(0xFFFF8F00) : const Color(0xFF9A9A9A),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? const Color(0xFF1A1410)
                          : const Color(0xFF1A1410),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B6661),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFFFF8F00) : const Color(0xFFD0D0D0),
                  width: selected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
