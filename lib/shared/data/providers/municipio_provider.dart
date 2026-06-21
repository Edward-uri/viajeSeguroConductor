import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/core_module.dart';
import '../../../core/http/api_endpoints.dart';
import '../../../shared/domain/entities/municipio.dart';

final municipiosProvider = FutureProvider<List<Municipio>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get(ApiEndpoints.municipios);
  final data = response['data'] as List<dynamic>?;
  if (data == null) return [];
  return data.map((e) {
    final m = e as Map<String, dynamic>;
    return Municipio(
      idMunicipio: (m['idMunicipio'] as num).toInt(),
      nombre: m['nombre'] as String,
      estado: m['estado'] as String? ?? '',
    );
  }).toList();
});
