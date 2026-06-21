import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8F00),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ganancias de hoy',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '\$340.00',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Chip('8 viajes'),
                        const SizedBox(width: 8),
                        _Chip('5.2 h en línea'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Últimos viajes',
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1410),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    return _EarningRow(
                      hora: '${9 + i}:30',
                      monto: 48.0 - i * 3,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  final String hora;
  final double monto;

  const _EarningRow({required this.hora, required this.monto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle_outlined, size: 20, color: Color(0xFFC4C4C4)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Viaje · $hora',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1410),
              ),
            ),
          ),
          Text(
            '\$${monto.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF8F00),
            ),
          ),
        ],
      ),
    );
  }
}
