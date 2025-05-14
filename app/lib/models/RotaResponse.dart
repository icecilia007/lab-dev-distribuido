
import 'dart:convert';

class RotaResponse {
  final double distanciaKm;
  final int tempoEstimadoMinutos;
  final dynamic rota;

  RotaResponse({
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    required this.rota,
  });

  Map<String, dynamic> toJson() {
    return {
      'distanciaKm': distanciaKm,
      'tempoEstimadoMinutos': tempoEstimadoMinutos,
      'rota': rota is Map || rota is List ? rota : jsonEncode(rota.toString()),
    };
  }

  factory RotaResponse.fromJson(Map<String, dynamic> json) {
    return RotaResponse(
      distanciaKm: json['distanciaKm'],
      tempoEstimadoMinutos: json['tempoEstimadoMinutos'],
      rota: json['rota'],
    );
  }
}