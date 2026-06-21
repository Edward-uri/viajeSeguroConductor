import 'package:flutter/material.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hoy',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B6661),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    return _RideHistoryCard(
                      hora: '${10 + i}:30',
                      origen: 'Av. Hidalgo 123',
                      destino: 'Primaria 5 de mayo',
                      monto: 48.0 - i * 5,
                      pasajero: 'María G.',
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

class _RideHistoryCard extends StatelessWidget {
  final String hora;
  final String origen;
  final String destino;
  final double monto;
  final String pasajero;

  const _RideHistoryCard({
    required this.hora,
    required this.origen,
    required this.destino,
    required this.monto,
    required this.pasajero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pasajero[0],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF8F00),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
          '$origen → $destino',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$hora · $pasajero',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B6661),
                  ),
                ),
              ],
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
