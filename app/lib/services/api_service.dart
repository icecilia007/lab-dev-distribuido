import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/notificacao.dart';
import '../models/pedido.dart';
import '../models/localizacao.dart';
import '../models/user.dart';
import 'database_service.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiService {

  final DatabaseService _databaseService = DatabaseService();
  final String apiGatewayUrl;

  String? _authToken;

  ApiService({String? apiGatewayUrl})
      : this.apiGatewayUrl = apiGatewayUrl ?? 'https://j0dh1wfnjf.execute-api.us-east-1.amazonaws.com/prod';

  set authToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> get _authHeaders {
    final headers = {'Content-Type': 'application/json'};

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  Future<User> login(String email, String password) async {
    try {
      _authToken = null;

      print("Iniciando login para: $email");
      final baseUrl = apiGatewayUrl ?? 'https://j0dh1wfnjf.execute-api.us-east-1.amazonaws.com/prod';
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': password,
        }),
      );

      print("Resposta do login - Status: ${response.statusCode}");
      print("Headers: ${response.headers}");

      if (response.statusCode == 200) {
        final authHeader = response.headers['x-amzn-remapped-authorization'] ??
            response.headers['Authorization'];

        print("Auth Header: $authHeader");

        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          _authToken = authHeader.substring(7);
          print("Token extraído: $_authToken");
        } else {
          print("Token não encontrado nos headers ou em formato inválido");
        }

        final userData = jsonDecode(response.body);
        print("Dados do usuário: $userData");
        return User.fromJson(userData);
      } else {
        throw Exception('Falha no login: ${response.body}');
      }
    } catch (e) {
      print("Exceção durante login: $e");
      throw Exception('Erro na requisição: $e');
    }
  }


  Future<bool> registrarCliente(Map<String, dynamic> clienteData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/auth/registro-cliente'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(clienteData),
      );

      if (response.statusCode == 201) {
        // Extrair o token do header Authorization
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          _authToken = authHeader.substring(7);
        }
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> registrarMotorista(Map<String, dynamic> motoristaData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/auth/registro-motorista'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(motoristaData),
      );

      if (response.statusCode == 201) {
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          _authToken = authHeader.substring(7);
        }
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> registrarOperador(Map<String, dynamic> operadorData) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/auth/registro-operador'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(operadorData),
      );

      if (response.statusCode == 201) {
        final authHeader = response.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          _authToken = authHeader.substring(7);
        }
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<List<Pedido>> getPedidosByMotorista(int motoristaId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/pedidos/motorista/$motoristaId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        List pedidosJson = jsonDecode(response.body);
        return pedidosJson.map((json) => Pedido.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar pedidos do motorista: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<List<Pedido>> getPedidosByCliente(int clienteId, userType) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/pedidos/usuario-info/$userType/$clienteId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        print('Response headers: ${response.headers}');
        print('Response content type: ${response.headers['content-type']}');

        if (response.body.isEmpty) {
          print('API retornou uma lista vazia para pedidos');
          return [];
        }

        try {
          // Adicione log para ver o início do body
          print('Primeiros 100 caracteres: ${response.body.substring(0, min(100, response.body.length))}');

          List<dynamic> pedidosJson = jsonDecode(response.body);
          print('JSON decodificado com sucesso. Encontrados ${pedidosJson.length} pedidos');
          List<Pedido> pedidos = pedidosJson.map((json) => Pedido.fromJson(json)).toList();

          return pedidos;
        } catch (e) {
          print('Erro ao decodificar JSON: $e');
          throw Exception('Erro ao processar resposta: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Token expirado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Acesso negado. Verifique suas permissões.');
      } else {
        throw Exception('Falha ao buscar pedidos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro ao buscar da API: $e');
      rethrow; // Propaga o erro sem tentar banco local
    }
  }

  Future<Pedido> getPedidoById(int pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/pedidos/consulta/$pedidoId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return Pedido.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao buscar pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<Pedido> criarPedido(
      String origemLatitude,
      String origemLongitude,
      String destinoLatitude,
      String destinoLongitude,
      String tipoMercadoria,
      int clienteId,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/pedidos'),
        headers: _authHeaders,
        body: jsonEncode({
          'origemLatitude': origemLatitude,
          'origemLongitude': origemLongitude,
          'destinoLatitude': destinoLatitude,
          'destinoLongitude': destinoLongitude,
          'tipoMercadoria': tipoMercadoria,
          'clienteId': clienteId,
        }),
      );

      if (response.statusCode == 201) {
        return Pedido.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao criar pedido: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> cancelarPedido(int pedidoId) async {
    try {
      final response = await http.patch(
        Uri.parse('$apiGatewayUrl/api/pedidos/acoes/cancelar/$pedidoId'),
        headers: _authHeaders,
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> atualizarPreferenciasNotificacao(
      int usuarioId,
      bool emailEnabled,
      bool pushEnabled,
      String email) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/notificacoes/preferencias'),
        headers: _authHeaders,
        body: jsonEncode({
          'usuarioId': usuarioId,
          'tipoPreferido': pushEnabled && emailEnabled ? 'AMBOS'
              : pushEnabled ? 'PUSH'
              : emailEnabled ? 'EMAIL'
              : 'NENHUM',
          'email': email,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erro ao atualizar preferências: $e');
      return false;
    }
  }

  Future<List<Notificacao>> buscarNotificacoes(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/notificacoes/destinatario/$userId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Notificacao.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        print('Token expirado para notificações');
        throw Exception('Token expirado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        print('Acesso negado para notificações');
        throw Exception('Acesso negado às notificações.');
      } else {
        print('Erro ao buscar notificações: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exceção ao buscar notificações: $e');
      return [];
    }
  }

  Future<bool> marcarNotificacaoComoLida(int notificacaoId) async {
    try {
      final response = await http.patch(
        Uri.parse('$apiGatewayUrl/api/notificacoes/$notificacaoId/marcar-lida'),
        headers: _authHeaders,
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Erro ao marcar notificação como lida: $e');
      return false;
    }
  }


  Future<Map<String, dynamic>?> buscarPreferenciasNotificacao(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/notificacoes/preferencias-usuario/$usuarioId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar preferências: $e');
      return null;
    }
  }

  Future<Localizacao> getLocalizacaoPedido(int pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/rastreamento/pedido/$pedidoId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return Localizacao.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha ao buscar localização: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<List<Localizacao>> getHistoricoLocalizacaoPedido(int pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/rastreamento/historico-pedido/$pedidoId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        List historicoJson = jsonDecode(response.body);
        return historicoJson.map((json) => Localizacao.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> aceitarPedido(int pedidoId, int motoristaId, double latitude, double longitude) async {
    try {
      final uri = Uri.parse('$apiGatewayUrl/api/pedidos/$pedidoId/aceitar?motoristaId=$motoristaId&latitude=$latitude&longitude=$longitude');
      final response = await http.post(
        uri,
        headers: _authHeaders,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao aceitar pedido: $e');
      return false;
    }
  }

  Future<bool> hasOngoingOrder(int motoristaId) async {
    try {
      final pedidos = await getPedidosByMotorista(motoristaId);
      return pedidos.any((pedido) =>
      pedido.status == 'EM_ROTA' || pedido.status == 'AGUARDANDO_COLETA');
    } catch (e) {
      print('Erro ao verificar pedidos em andamento: $e');
      return false;
    }
  }



  Future<bool> updateDeliveryStatus(
      int pedidoId,
      String newStatus,
      {required String imagePath}
      ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiGatewayUrl/api/pedidos/$pedidoId/status'),
      );

      _authHeaders.forEach((key, value) {
        request.headers[key] = value;
      });

      request.fields['status'] = newStatus;

      request.files.add(
        await http.MultipartFile.fromPath(
          'evidenceImage',
          imagePath,
        ),
      );

      var response = await request.send();

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<bool> atualizarLocalizacaoMotorista(
      int motoristaId,
      double latitude,
      double longitude,
      String statusVeiculo,
      {int? pedidoId}
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/rastreamento/registrar-localizacao'),
        headers: _authHeaders,
        body: jsonEncode({
          'motoristaId': motoristaId,
          'pedidoId': pedidoId,
          'latitude': latitude,
          'longitude': longitude,
          'statusVeiculo': statusVeiculo
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as bool;
      } else {
        throw Exception('Falha ao atualizar localização: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future confirmarEntrega(int pedidoId, int motoristaId) async {
    final url = '$apiGatewayUrl/api/rastreamento/acao-entrega/$pedidoId/?motoristaId=$motoristaId';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _authHeaders,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        _logError('confirmarEntrega', response);
        return false;
      }
    } catch (e) {
      debugPrint('Erro ao confirmar entrega: $e');
      return false;
    }
  }

  Future<bool> confirmarColetaComFoto(int pedidoId, int motoristaId, File fotoColeta) async {
    try {
      var uri = Uri.parse('$apiGatewayUrl/api/rastreamento/acao-coleta/$pedidoId/?motoristaId=$motoristaId');
      var request = http.MultipartRequest('POST', uri);

      _authHeaders.forEach((key, value) {
        request.headers[key] = value;
      });

      if (fotoColeta.existsSync()) {
        final foto = await http.MultipartFile.fromPath(
          'foto',
          fotoColeta.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(foto);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData == true;
        print('true');
      } else {
        print('Erro ao confirmar coleta: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exceção ao confirmar coleta: $e');
      return false;
    }
  }

  void _logError(String methodName, http.Response response) {
    print('Error in $methodName: Status Code ${response.statusCode}');
    if (response.body.isNotEmpty) {
      try {
        final errorData = jsonDecode(response.body);
        print('Error details: $errorData');
      } catch (e) {
        print('Response body (not JSON): ${response.body}');
      }
    }
  }

  Future<Map<String, dynamic>> getDriverStatistics(
      int driverId,
      String dataInicio,
      String dataFim
      ) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/rastreamento/motorista/estatistica/$driverId?dataInicio=$dataInicio&dataFim=$dataFim'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Falha ao buscar estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  Future<Map<String, dynamic>?> reportarIncidente(
      int motoristaId,
      double latitude,
      double longitude,
      String tipo,
      String descricao,
      double raioImpactoKm,
      int duracaoHoras
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$apiGatewayUrl/api/incidentes'),
        headers: _authHeaders,
        body: jsonEncode({
          'motoristaId': motoristaId,
          'latitude': latitude,
          'longitude': longitude,
          'tipo': tipo,
          'descricao': descricao,
          'raioImpactoKm': raioImpactoKm,
          'duracaoHoras': duracaoHoras
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print('Erro ao reportar incidente: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exceção ao reportar incidente: $e');
      return null;
    }
  }
}
