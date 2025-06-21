import 'package:intl/intl.dart';

import 'RotaResponse.dart';

class Pedido {
  final int id;
  final String origemLongitude;
  final String origemLatitude;
  final String destinoLongitude;
  final String destinoLatitude;
  final String tipoMercadoria;
  final String status;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final DateTime? dataEntregaEstimada;
  final double distanciaKm;
  final int tempoEstimadoMinutos;
  final int clienteId;
  final int? motoristaId;
  final RotaResponse? rotaMotorista;

  Pedido({
    required this.id,
    required this.origemLongitude,
    required this.origemLatitude,
    required this.destinoLongitude,
    required this.destinoLatitude,
    required this.tipoMercadoria,
    required this.status,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.dataEntregaEstimada,
    required this.distanciaKm,
    required this.tempoEstimadoMinutos,
    required this.clienteId,
    this.motoristaId,
    this.rotaMotorista,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      id: json['id'],
      origemLongitude: json['origemLongitude'],
      origemLatitude: json['origemLatitude'],
      destinoLongitude: json['destinoLongitude'],
      destinoLatitude: json['destinoLatitude'],
      tipoMercadoria: json['tipoMercadoria'],
      status: json['status'],
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataAtualizacao: DateTime.parse(json['dataAtualizacao']),
      dataEntregaEstimada: json['dataEntregaEstimada'] != null
          ? DateTime.parse(json['dataEntregaEstimada'])
          : null,
      distanciaKm: json['distanciaKm'],
      tempoEstimadoMinutos: json['tempoEstimadoMinutos'],
      clienteId: json['clienteId'],
      motoristaId: json['motoristaId'],
      rotaMotorista: json['rotaMotorista'] != null
          ? RotaResponse.fromJson(json['rotaMotorista'])
          : null,
    );
  }

  String get formattedStatus {
    switch (status.toLowerCase()) {
      case 'aguardando_coleta': return 'Aguardando Coleta';
      case 'em_rota': return 'Em Rota';
      case 'entregue': return 'Entregue';
      case 'cancelado': return 'Cancelado';
      default: return status;
    }
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm').format(dataCriacao);
  }
}

