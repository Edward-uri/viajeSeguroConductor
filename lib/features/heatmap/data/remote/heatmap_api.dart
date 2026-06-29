import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/heat_zone.dart';

class HeatmapApi {
  static const String _baseUrl = 'https://zonas.codigoverse.space';

  Future<List<HeatZone>> fetchZonas({
    required int municipio,
    required int diaSemana,
    required int hora,
  }) async {
    final uri = Uri.parse('$_baseUrl/inferencias');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'municipio': municipio,
        'dia_semana': diaSemana,
        'hora': hora,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al obtener zonas: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final zonas = body['zonas'] as List<dynamic>? ?? [];
    return zonas
        .map((z) => HeatZone.fromJson(z as Map<String, dynamic>))
        .toList();
  }
}
