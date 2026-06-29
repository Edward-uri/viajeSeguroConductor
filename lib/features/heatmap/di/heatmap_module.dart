import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/heatmap_repository_impl.dart';
import '../data/remote/heatmap_api.dart';
import '../domain/repositories/heatmap_repository.dart';

final heatmapApiProvider = Provider<HeatmapApi>((ref) => HeatmapApi());

final heatmapRepositoryProvider = Provider<HeatmapRepository>((ref) {
  return HeatmapRepositoryImpl(ref.watch(heatmapApiProvider));
});
