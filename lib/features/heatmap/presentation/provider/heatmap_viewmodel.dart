import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/heat_zone.dart';
import '../../di/heatmap_module.dart';
import '../../domain/repositories/heatmap_repository.dart';

final heatmapViewModelProvider =
    StateNotifierProvider.autoDispose<HeatmapViewModel, HeatmapState>((ref) {
  return HeatmapViewModel(ref.watch(heatmapRepositoryProvider));
});

/// Zonas de alta demanda del municipio. driver_home_screen las pinta como un
/// HeatmapLayer de Mapbox (escala de verde según la intensidad); el color ya no
/// se calcula por zona aquí, lo resuelve la expresión del layer.
class HeatmapViewModel extends StateNotifier<HeatmapState> {
  HeatmapViewModel(this._repository) : super(const HeatmapState());

  final HeatmapRepository _repository;

  Future<void> fetchZonas(int idMunicipio) async {
    state = state.copyWith(isLoading: true);
    try {
      final raw = await _repository.getZonasCalientesRaw(idMunicipio);
      if (!mounted) return;
      // Son pocas zonas (top ~5): el mapeo es trivial, sin isolate.
      state = state.copyWith(zonas: raw.map(HeatZone.fromJson).toList());
      if (kDebugMode) {
        debugPrint('[Heatmap] zonas: ${state.zonas.length} (municipio $idMunicipio)');
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(zonas: const []);
      if (kDebugMode) debugPrint('[Heatmap] zonas no disponibles: $e');
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  /// Al pasar a offline se despeja el mapa.
  void clear() {
    state = state.copyWith(zonas: const []);
  }
}

class HeatmapState extends Equatable {
  const HeatmapState({
    this.zonas = const [],
    this.isLoading = false,
  });

  final List<HeatZone> zonas;
  final bool isLoading;

  HeatmapState copyWith({
    List<HeatZone>? zonas,
    bool? isLoading,
  }) {
    return HeatmapState(
      zonas: zonas ?? this.zonas,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [zonas, isLoading];
}
