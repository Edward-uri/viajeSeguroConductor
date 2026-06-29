class HeatZone {
  final double lat;
  final double lng;
  final double intensidad;
  final double demandDensity;
  final double supplyDemandRatio;
  final int nRequests;
  final double radioM;

  const HeatZone({
    required this.lat,
    required this.lng,
    required this.intensidad,
    required this.demandDensity,
    required this.supplyDemandRatio,
    required this.nRequests,
    required this.radioM,
  });

  factory HeatZone.fromJson(Map<String, dynamic> json) {
    return HeatZone(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      intensidad: (json['intensidad'] as num).toDouble(),
      demandDensity: (json['demand_density'] as num).toDouble(),
      supplyDemandRatio: (json['supply_demand_ratio'] as num).toDouble(),
      nRequests: (json['n_requests'] as num).toInt(),
      radioM: (json['radio_m'] as num).toDouble(),
    );
  }
}
