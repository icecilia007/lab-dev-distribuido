import 'dart:convert';

class Notificacao {
  final int id;
  final String tipoEvento;
  final String origem;
  final int destinatarioId;
  final String titulo;
  final String mensagem;
  final String dataCriacao;
  final String? dataLeitura;
  bool lida;
  final String? payload;

  Notificacao({
    required this.id,
    required this.tipoEvento,
    required this.origem,
    required this.destinatarioId,
    required this.titulo,
    required this.mensagem,
    required this.dataCriacao,
    this.dataLeitura,
    this.lida = false,
    this.payload,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    String? payload = jsonEncode(json);

    return Notificacao(
      id: json['id'],
      tipoEvento: json['tipoEvento'] ?? '',
      origem: json['origem'] ?? '',
      destinatarioId: json['destinatarioId'],
      titulo: json['titulo'] ?? 'Notificação',
      mensagem: json['mensagem'] ?? '',
      dataCriacao: json['dataCriacao'] ?? DateTime.now().toIso8601String(),
      dataLeitura: json['dataLeitura'],
      lida: json['dataLeitura'] != null,
      payload: payload,
    );
  }
}
