class Localizacao {
  final int? id;
  final int pedidoId;
  final int motoristaId;
  final double longitude;
  final double latitude;
  final DateTime timestamp;
  final String statusVeiculo;
  final double distanciaDestinoKm;
  final int tempoEstimadoMinutos;

  Localizacao({
    this.id,
    required this.pedidoId,
    required this.motoristaId,
    required this.longitude,
    required this.latitude,
    required this.timestamp,
    required this.statusVeiculo,
    required this.distanciaDestinoKm,
    required this.tempoEstimadoMinutos,
  });

  factory Localizacao.fromJson(Map<String, dynamic> json) {
    return Localizacao(
      id: json['id'],
      pedidoId: json['pedidoId'],
      motoristaId: json['motoristaId'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      timestamp: DateTime.parse(json['timestamp']),
      statusVeiculo: json['statusVeiculo'],
      distanciaDestinoKm: json['distanciaDestinoKm'],
      tempoEstimadoMinutos: json['tempoEstimadoMinutos'],
    );
  }
}
