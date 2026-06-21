import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/app_routes.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: CircleAvatar(
                radius: 44,
                backgroundColor: const Color(0xFFFF8F00),
                child: Text(
                  'CM',
                  style: text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Carlos Méndez',
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 16, color: Color(0xFFFF8F00)),
                  const SizedBox(width: 4),
                  Text(
                    '4.9 — Conductor',
                    style: text.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E8E5A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Habilitado',
                  style: TextStyle(
                    color: Color(0xFF1E8E5A),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem('4.9', 'Calificación', text),
                _statItem('320', 'Viajes', text),
                _statItem('95%', 'Aceptación', text),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.directions_bike_outlined),
                title: const Text('Mototaxi — Naranja'),
                subtitle: const Text('Placa ABC-123'),
              ),
            ),
            const SizedBox(height: 24),
            Text('CUENTA',
                style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Editar perfil'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Mis documentos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.documents),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.credit_card_outlined),
                    title: const Text('Métodos de cobro'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.paymentMethods),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('ACTIVIDAD',
                style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attach_money_outlined),
                    title: const Text('Ganancias'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.earnings),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Historial de viajes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.rideHistory),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Centro de ayuda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.getstarted,
                (route) => false,
              ),
              icon: Icon(Icons.logout, color: scheme.error),
              label: Text('Cerrar sesión',
                  style: TextStyle(color: scheme.error)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, TextTheme text) {
    return Column(
      children: [
        Text(value,
            style: text.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}
