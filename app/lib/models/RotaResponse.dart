
class RotaResponse {
  final double distanciaKm;
  final int tempoEstimadoMinutos;
  final dynamic rota;

  RotaResponse({
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    required this.rota,
  });

  factory RotaResponse.fromJson(Map<String, dynamic> json) {
    return RotaResponse(
      distanciaKm: json['distanciaKm'],
      tempoEstimadoMinutos: json['tempoEstimadoMinutos'],
      rota: json['rota'],
    );
  }
}