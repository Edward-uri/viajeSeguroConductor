import 'package:flutter/material.dart';

class RideInProgressScreen extends StatefulWidget {
  const RideInProgressScreen({super.key});

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  bool _hasStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: _hasStarted
                  ? const Color(0xFF1E8E5A)
                  : Colors.white,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1A1410),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      Text(
                        _hasStarted ? 'Viaje en curso' : 'Llegada al origen',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _hasStarted
                              ? Colors.white
                              : const Color(0xFF1A1410),
                        ),
                      ),
                      if (!_hasStarted)
                        const Text(
                          '3 min para llegar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B6661),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFE9ECEA),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 120,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1E0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFFFF8F00),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'María G.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1410),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Av. Hidalgo 123 → Primaria 5 de mayo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6661),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_hasStarted)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _hasStarted = true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8F00),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Iniciar viaje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8E5A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Completar viaje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
