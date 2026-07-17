import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/jala_theme.dart';
import '../../data/models/heat_zone.dart';
import '../../di/heatmap_module.dart';
import '../../domain/repositories/heatmap_repository.dart';

final heatmapViewModelProvider =
    StateNotifierProvider.autoDispose<HeatmapViewModel, HeatmapState>((ref) {
  return HeatmapViewModel(ref.watch(heatmapRepositoryProvider));
});

/// Corre en un isolate de background. Procesa los mapas crudos de zonas
/// calientes: extrae valores numéricos y pre-computa el color del marcador
/// para evitar trabajo pesado en el hilo principal.
List<Map<String, dynamic>> _processHeatZoneMaps(List<Map<String, dynamic>> raw) {
  int lerpColor(int a, int b, double t) {
    final ar = (a >> 16) & 0xFF, ag = (a >> 8) & 0xFF, ab = a & 0xFF;
    final br = (b >> 16) & 0xFF, bg = (b >> 8) & 0xFF, bb = b & 0xFF;
    return 0xFF000000 |
        ((ar + ((br - ar) * t).round()) << 16) |
        ((ag + ((bg - ag) * t).round()) << 8) |
        ((ab + ((bb - ab) * t).round()));
  }

  return raw.map((z) {
    final intensidad = (z['intensidad'] as num).toDouble();
    return <String, dynamic>{
      'lat': (z['lat'] as num).toDouble(),
      'lng': (z['lng'] as num).toDouble(),
      'intensidad': intensidad,
      'demand_density': (z['demand_density'] as num).toDouble(),
      'supply_demand_ratio': (z['supply_demand_ratio'] as num).toDouble(),
      'n_requests': (z['n_requests'] as num).toInt(),
      'radio_m': (z['radio_m'] as num).toDouble(),
      'color': lerpColor(
          JalaBrand.warning.toARGB32(), JalaBrand.destructive.toARGB32(),
          intensidad),
    };
  }).toList();
}

/// Zonas calientes del municipio: fetch + procesado (colores) en isolate.
/// driver_home_screen las dibuja como CircleAnnotations sobre el mapa.
class HeatmapViewModel extends StateNotifier<HeatmapState> {
  HeatmapViewModel(this._repository) : super(const HeatmapState());

  final HeatmapRepository _repository;

  Future<void> fetchZonas(int idMunicipio) async {
    state = state.copyWith(isLoading: true);
    try {
      final raw = await _repository.getZonasCalientesRaw(idMunicipio);
      final processed = await compute(_processHeatZoneMaps, raw);
      if (!mounted) return;

      state = state.copyWith(
        zonas: processed.map((m) => HeatZone(
          lat: (m['lat'] as num).toDouble(),
          lng: (m['lng'] as num).toDouble(),
          intensidad: (m['intensidad'] as num).toDouble(),
          demandDensity: (m['demand_density'] as num).toDouble(),
          supplyDemandRatio: (m['supply_demand_ratio'] as num).toDouble(),
          nRequests: (m['n_requests'] as num).toInt(),
          radioM: (m['radio_m'] as num).toDouble(),
        )).toList(),
        colores: processed
            .map((m) => Color((m['color'] as num).toInt()))
            .toList(),
      );

      if (kDebugMode) {
        debugPrint('[Heatmap] zonas calientes: ${state.zonas.length} (municipio $idMunicipio)');
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(zonas: const [], colores: const []);
      if (kDebugMode) debugPrint('[Heatmap] zonas calientes no disponibles: $e');
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  /// Al pasar a offline se despeja el mapa.
  void clear() {
    state = state.copyWith(zonas: const [], colores: const []);
  }
}

class HeatmapState extends Equatable {
  const HeatmapState({
    this.zonas = const [],
    this.colores = const [],
    this.isLoading = false,
  });

  final List<HeatZone> zonas;
  final List<Color> colores;
  final bool isLoading;

  HeatmapState copyWith({
    List<HeatZone>? zonas,
    List<Color>? colores,
    bool? isLoading,
  }) {
    return HeatmapState(
      zonas: zonas ?? this.zonas,
      colores: colores ?? this.colores,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [zonas, colores, isLoading];
}
