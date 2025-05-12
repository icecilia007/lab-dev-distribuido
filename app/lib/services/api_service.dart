import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:app/models/notificacao.dart';
import '../models/pedido.dart';
import '../models/localizacao.dart';
import '../models/user.dart';
import 'database_service.dart';

class ApiService {

  final DatabaseService _databaseService = DatabaseService();
  final String apiGatewayUrl;

  String? _authToken;

  ApiService({String? apiGatewayUrl})
      : this.apiGatewayUrl = apiGatewayUrl ?? 'http://10.0.2.2:8000';

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
      final baseUrl = apiGatewayUrl ?? 'http://10.0.2.2:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print("Resposta do login - Status: ${response.statusCode}");
      print("Headers: ${response.headers}");

      if (response.statusCode == 200) {
        final authHeader = response.headers['authorization'] ??
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
        Uri.parse('$apiGatewayUrl/api/auth/registro/cliente'),
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
        Uri.parse('$apiGatewayUrl/api/auth/registro/motorista'),
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
        Uri.parse('$apiGatewayUrl/api/auth/registro/operador'),
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

  Future<List<Pedido>> getPedidosByCliente(int clienteId) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult != ConnectivityResult.none;

    if (isConnected) {
      try {
        final response = await http.get(
          Uri.parse('$apiGatewayUrl/api/pedidos/cliente/$clienteId'),
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

            for (var pedido in pedidos) {
              if (pedido.status == 'ENTREGUE') {
                await _databaseService.insertPedido(pedido);
              }
            }

            return pedidos;
          } catch (e) {
            print('Erro ao decodificar JSON: $e');
            throw Exception('Erro ao processar resposta: $e');
          }
        } else {
          throw Exception('Falha ao buscar pedidos: ${response.statusCode}');
        }
      } catch (e) {
        print('Erro ao buscar da API: $e. Tentando buscar do banco local...');
        return await _databaseService.getPedidosByCliente(clienteId);
      }
    } else {
      print('Dispositivo offline. Buscando pedidos do banco local...');
      return await _databaseService.getPedidosByCliente(clienteId);
    }
  }

  Future<Pedido> getPedidoById(int pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/pedidos/$pedidoId'),
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
        Uri.parse('$apiGatewayUrl/api/pedidos/$pedidoId/cancelar'),
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
      } else {
        print('Erro ao buscar notificações: ${response.statusCode}');
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
        Uri.parse('$apiGatewayUrl/api/notificacoes/preferencias/$usuarioId'),
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
        Uri.parse('$apiGatewayUrl/api/rastreamento/historico/$pedidoId'),
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
}
