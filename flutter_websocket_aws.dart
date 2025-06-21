// ARQUIVO: app/lib/services/websocket_aws_service.dart
//
// Novo serviço para conectar ao WebSocket do AWS API Gateway

import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketAWSService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  String? _connectionId;
  
  // URL do WebSocket AWS - substitua pelo seu WebSocket API Gateway
  static const String _websocketUrl = 'wss://23b38pazkc.execute-api.us-east-1.amazonaws.com/prod';
  
  // Callbacks para notificações
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;

  bool get isConnected => _isConnected;
  String? get connectionId => _connectionId;

  /// Conectar ao WebSocket com token JWT
  Future<void> connect(String jwtToken, int userId) async {
    try {
      print('Conectando ao WebSocket AWS: $_websocketUrl');
      
      // Criar conexão WebSocket com headers de autenticação
      final uri = Uri.parse('$_websocketUrl?token=$jwtToken&userId=$userId');
      
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      // Escutar mensagens
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('Erro no WebSocket: $error');
          _isConnected = false;
          onError?.call(error.toString());
        },
        onDone: () {
          print('WebSocket desconectado');
          _isConnected = false;
          onDisconnected?.call();
        },
      );

      _isConnected = true;
      print('WebSocket conectado com sucesso!');
      onConnected?.call();

    } catch (e) {
      print('Erro ao conectar WebSocket: $e');
      _isConnected = false;
      onError?.call('Erro de conexão: $e');
    }
  }

  /// Processar mensagens recebidas
  void _handleMessage(dynamic message) {
    try {
      print('Mensagem WebSocket recebida: $message');
      
      final Map<String, dynamic> data = jsonDecode(message);
      
      // Verificar se é uma mensagem de conexão
      if (data.containsKey('connectionId')) {
        _connectionId = data['connectionId'];
        print('Connection ID recebido: $_connectionId');
        return;
      }

      // Processar notificações
      if (data.containsKey('action') && data['action'] == 'notification') {
        onMessageReceived?.call(data);
      } else {
        // Outras mensagens
        onMessageReceived?.call(data);
      }
      
    } catch (e) {
      print('Erro ao processar mensagem WebSocket: $e');
    }
  }

  /// Enviar mensagem
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket não conectado');
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      print('Mensagem enviada: $jsonMessage');
    } catch (e) {
      print('Erro ao enviar mensagem: $e');
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }

  /// Desconectar
  Future<void> disconnect() async {
    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
      _isConnected = false;
      _connectionId = null;
      print('WebSocket desconectado manualmente');
    } catch (e) {
      print('Erro ao desconectar WebSocket: $e');
    }
  }

  /// Reconectar
  Future<void> reconnect(String jwtToken, int userId) async {
    await disconnect();
    await Future.delayed(Duration(seconds: 2));
    await connect(jwtToken, userId);
  }
}