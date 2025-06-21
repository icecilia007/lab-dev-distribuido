// ARQUIVO: app/lib/services/api_service.dart
// 
// Modificações necessárias para remover banco local e usar apenas API AWS

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
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String apiGatewayUrl;
  String? _authToken;

  ApiService({String? apiGatewayUrl})
      : this.apiGatewayUrl = apiGatewayUrl ?? 'https://aq72n5uzcb.execute-api.us-east-1.amazonaws.com/prod';

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

  // MÉTODO DE LOGIN (SEM ALTERAÇÕES)
  Future<User> login(String email, String password) async {
    try {
      _authToken = null;

      print("Iniciando login para: $email");
      final baseUrl = apiGatewayUrl ?? 'https://aq72n5uzcb.execute-api.us-east-1.amazonaws.com/prod';
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

  // MÉTODO getPedidosByCliente MODIFICADO (REMOVIDO BANCO LOCAL)
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

  // MÉTODO buscarNotificacoes MODIFICADO (MELHOR TRATAMENTO DE ERROS)
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

  // RESTO DOS MÉTODOS PERMANECEM IGUAIS...
  // (registrarCliente, registrarMotorista, criarPedido, etc.)
  
  // Copio aqui apenas os métodos que NÃO precisam de modificação
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

  // Outros métodos permanecem os mesmos...
}