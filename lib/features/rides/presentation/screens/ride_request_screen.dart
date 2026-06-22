import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../provider/home_viewmodel.dart';

class RideRequestScreen extends ConsumerStatefulWidget {
  const RideRequestScreen({super.key});

  @override
  ConsumerState<RideRequestScreen> createState() =>
      _RideRequestScreenState();
}

class _RideRequestScreenState extends ConsumerState<RideRequestScreen> {
  int _countdown = 15;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_countdown > 0) {
        setState(() => _countdown--);
      }
      return _countdown > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final request = vm.currentRequest;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitud de viaje')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nueva solicitud',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF8F00),
                    ),
                  ),
                  if (request != null)
                    Text(
                      '\$${request.monto.toStringAsFixed(2)}',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1410),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (request != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.money,
                              size: 14, color: Color(0xFF1E8E5A)),
                          const SizedBox(width: 4),
                          Text(
                            request.metodoPago,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E8E5A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${request.distanciaKm.toStringAsFixed(1)} km · ${request.duracionMin} min',
                      style: text.bodyMedium?.copyWith(
                        color: const Color(0xFF6B6661),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _countdown / 15,
                        strokeWidth: 6,
                        backgroundColor: scheme.surfaceContainerHigh,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF8F00)),
                      ),
                      Center(
                        child: Text(
                          '${_countdown}s',
                          style: text.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _countdown <= 3
                                ? const Color(0xFFD84315)
                                : const Color(0xFFFF8F00),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (request != null) ...[
                Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFFFF8F00),
                    child: Text(
                      request.pasajeroIniciales,
                      style: text.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    request.pasajeroNombre,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1410),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star,
                          size: 16, color: Color(0xFFFF8F00)),
                      const SizedBox(width: 4),
                      Text(
                        '${request.pasajeroCalificacion.toStringAsFixed(1)} · Pasajera',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6661),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _locationRow(
                  Icons.circle_outlined,
                  request.origen,
                  'Recoger · ${request.origenDistancia}',
                  const Color(0xFFFF8F00),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Container(
                    width: 2,
                    height: 24,
                    color: const Color(0xFFD0D0D0),
                  ),
                ),
                _locationRow(
                  Icons.location_on_outlined,
                  request.destino,
                  'Destino del pasajero',
                  const Color(0xFFFF8F00),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        vm.rejectRide();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: Color(0xFFECECEC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: const Color(0xFF6B6661),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54,
                      child: GradientButton(
                        label: 'Aceptar viaje',
                        onPressed: () {
                          vm.acceptRide(idVehiculo: 1);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationRow(
      IconData icon, String title, String subtitle, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1410),
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6661),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
