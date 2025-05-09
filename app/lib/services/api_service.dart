// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pedido.dart';
import '../models/localizacao.dart';
import '../models/user.dart';

class ApiService {
  // URLs para cada serviço
  final String usuarioServiceUrl;
  final String pedidoServiceUrl;
  final String rastreamentoServiceUrl;

  ApiService({
    this.usuarioServiceUrl = 'http://10.0.2.2:8080',
    this.pedidoServiceUrl = 'http://10.0.2.2:8081',
    this.rastreamentoServiceUrl = 'http://10.0.2.2:8082',
  });

  // Métodos do serviço de Usuários
  Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$usuarioServiceUrl/api/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Falha no login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  // Métodos do serviço de Pedidos
  Future<List<Pedido>> getPedidosByCliente(int clienteId) async {
    try {
      final response = await http.get(
        Uri.parse('$pedidoServiceUrl/api/pedidos/cliente/$clienteId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> pedidosJson = jsonDecode(response.body);
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
        Uri.parse('$pedidoServiceUrl/api/pedidos/$pedidoId'),
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
        Uri.parse('$pedidoServiceUrl/api/pedidos'),
        headers: {'Content-Type': 'application/json'},
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
        Uri.parse('$pedidoServiceUrl/api/pedidos/$pedidoId/cancelar'),
      );

      return response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }

  // Métodos do serviço de Rastreamento
  Future<Localizacao> getLocalizacaoPedido(int pedidoId) async {
    try {
      final response = await http.get(
        Uri.parse('$rastreamentoServiceUrl/api/rastreamento/pedido/$pedidoId'),
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
        Uri.parse('$rastreamentoServiceUrl/api/rastreamento/historico/$pedidoId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> historicoJson = jsonDecode(response.body);
        return historicoJson.map((json) => Localizacao.fromJson(json)).toList();
      } else {
        throw Exception('Falha ao buscar histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro na requisição: $e');
    }
  }
}
