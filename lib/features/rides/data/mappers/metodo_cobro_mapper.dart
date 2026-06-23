import '../../domain/entities/metodo_cobro.dart';

class MetodoCobroMapper {
  const MetodoCobroMapper._();

  static MetodoCobro fromJson(Map<String, dynamic> json) => MetodoCobro(
        id: (json['id'] as num?)?.toInt(),
        tipo: json['tipo']?.toString() ?? 'transferencia',
        clabe: json['clabe']?.toString() ?? '',
        banco: json['banco']?.toString() ?? '',
        titular: json['titular']?.toString() ?? '',
      );

  static Map<String, dynamic> toJson(MetodoCobro mc) => {
        'tipo': mc.tipo,
        'clabe': mc.clabe,
        'banco': mc.banco,
        'titular': mc.titular,
      };
}
