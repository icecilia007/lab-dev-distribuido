import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pedido.dart';
import '../models/localizacao.dart';
import '../models/user.dart';

class ApiService {
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
    try {
      final response = await http.get(
        Uri.parse('$apiGatewayUrl/api/pedidos/cliente/$clienteId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        List pedidosJson = jsonDecode(response.body);
        return pedidosJson.map((json) => Pedido.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
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
