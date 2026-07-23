import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/jala_theme.dart';
import '../../domain/entities/ride_history_item.dart';
import '../provider/ride_history_viewmodel.dart';

const _estadoOpciones = <(String?, String)>[
  (null, 'Todos'),
  ('completado', 'Completados'),
  ('en_curso', 'En curso'),
  ('cancelado', 'Cancelados'),
];
const _fechaOpciones = <(int?, String)>[
  (null, 'Todo'),
  (0, 'Hoy'),
  (7, '7 días'),
  (30, '30 días'),
];

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(rideHistoryViewModelProvider).loadHistory(),
    );
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      ref.read(rideHistoryViewModelProvider).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(rideHistoryViewModelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de viajes')),
      body: SafeArea(
        child: Column(
          children: [
            _FiltrosBar(vm: vm),
            Expanded(child: _contenido(vm)),
          ],
        ),
      ),
    );
  }

  Widget _contenido(RideHistoryViewModel vm) {
    if (vm.isLoading && vm.rides.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && vm.rides.isEmpty) {
      return _Centro(
        icon: Icons.error_outline,
        titulo: vm.errorMessage!,
        accion: TextButton(
          onPressed: () => ref.read(rideHistoryViewModelProvider).loadHistory(),
          child: const Text('Reintentar'),
        ),
      );
    }
    if (vm.isEmpty) {
      return const _Centro(
          icon: Icons.history, titulo: 'Sin viajes con estos filtros');
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(rideHistoryViewModelProvider).loadHistory(),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: vm.rides.length + 1,
        itemBuilder: (context, i) {
          if (i == vm.rides.length) return _Footer(vm: vm);
          return _RideHistoryCard(ride: vm.rides[i]);
        },
      ),
    );
  }
}

class _FiltrosBar extends ConsumerWidget {
  const _FiltrosBar({required this.vm});

  final RideHistoryViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(rideHistoryViewModelProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in _estadoOpciones)
                _chip(
                  label: o.$2,
                  selected: vm.estado == o.$1,
                  onTap: () => notifier.setEstado(o.$1),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in _fechaOpciones)
                _chip(
                  label: o.$2,
                  selected: vm.dias == o.$1,
                  onTap: () => notifier.setDias(o.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.vm});

  final RideHistoryViewModel vm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (vm.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (vm.hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Center(
          child: TextButton(
            onPressed: () => ref.read(rideHistoryViewModelProvider).loadMore(),
            child: const Text('Cargar más'),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          '${vm.total} ${vm.total == 1 ? "viaje" : "viajes"} en total',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = _estadoColor(context, ride.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.motorcycle_outlined, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.origen} → ${ride.destino}',
                        style: text.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ride.fecha != null)
                        Text(
                          _fechaLabel(ride.fecha!),
                          style: text.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${ride.monto.toStringAsFixed(2)}',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _EstadoChip(label: _estadoLabel(ride.estado), color: color),
                if (ride.distanciaKm != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${ride.distanciaKm!.toStringAsFixed(1)} km',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _Centro extends StatelessWidget {
  const _Centro({required this.icon, required this.titulo, this.accion});

  final IconData icon;
  final String titulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.outline),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ],
      ),
    );
  }
}

String _estadoLabel(String estado) {
  switch (estado) {
    case 'solicitado':
      return 'Solicitado';
    case 'aceptado':
      return 'Aceptado';
    case 'en_curso':
      return 'En curso';
    case 'completado':
      return 'Completado';
    case 'cancelado':
      return 'Cancelado';
    default:
      return estado;
  }
}

Color _estadoColor(BuildContext context, String estado) {
  switch (estado) {
    case 'completado':
      return context.brand.success;
    case 'en_curso':
    case 'aceptado':
      return context.brand.warning;
    case 'cancelado':
      return Theme.of(context).colorScheme.error;
    default:
      return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}

String _fechaLabel(DateTime d) {
  const meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${meses[d.month - 1]} ${d.year} · $hh:$mm';
}
