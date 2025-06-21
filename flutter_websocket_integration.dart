// ARQUIVO: Como integrar o WebSocket AWS no seu app Flutter
//
// 1. ADICIONAR DEPENDÊNCIA no pubspec.yaml:
// dependencies:
//   web_socket_channel: ^2.4.0
//
// 2. MODIFICAR o arquivo principal onde você gerencia o estado do usuário
// (provavelmente main.dart ou um service de autenticação)

import 'package:flutter/material.dart';
import 'services/websocket_aws_service.dart';
import 'services/api_service.dart';

class AuthenticationManager {
  final WebSocketAWSService _websocketService = WebSocketAWSService();
  final ApiService _apiService = ApiService();
  
  User? _currentUser;
  String? _authToken;

  // Configurar callbacks do WebSocket
  void _setupWebSocketCallbacks() {
    _websocketService.onConnected = () {
      print('WebSocket AWS conectado!');
    };

    _websocketService.onDisconnected = () {
      print('WebSocket AWS desconectado!');
      // Tentar reconectar após 5 segundos
      Future.delayed(Duration(seconds: 5), () {
        if (_authToken != null && _currentUser != null) {
          _websocketService.reconnect(_authToken!, _currentUser!.id);
        }
      });
    };

    _websocketService.onError = (error) {
      print('Erro WebSocket AWS: $error');
    };

    _websocketService.onMessageReceived = (message) {
      print('Nova notificação recebida: $message');
      _handleWebSocketNotification(message);
    };
  }

  // Processar notificações do WebSocket
  void _handleWebSocketNotification(Map<String, dynamic> message) {
    try {
      if (message['action'] == 'notification') {
        final notification = message['data'];
        
        // Aqui você pode:
        // 1. Mostrar uma notificação push local
        // 2. Atualizar a UI
        // 3. Salvar no estado da aplicação
        // 4. Reproduzir um som
        
        print('Notificação recebida:');
        print('Título: ${notification['titulo']}');
        print('Mensagem: ${notification['mensagem']}');
        print('Tipo: ${notification['tipo']}');
        
        // Exemplo: mostrar um SnackBar
        _showNotificationSnackBar(notification);
      }
    } catch (e) {
      print('Erro ao processar notificação: $e');
    }
  }

  // Mostrar notificação na UI
  void _showNotificationSnackBar(Map<String, dynamic> notification) {
    // Você precisará ter acesso ao BuildContext aqui
    // Uma opção é usar um GlobalKey<ScaffoldMessengerState>
    
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            notification['titulo'] ?? 'Nova Notificação',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(notification['mensagem'] ?? ''),
        ],
      ),
      duration: Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Ver',
        onPressed: () {
          // Navegar para tela de notificações
          _navigateToNotifications();
        },
      ),
    );

    // Mostrar o SnackBar
    // ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Fazer login e conectar WebSocket
  Future<bool> login(String email, String password) async {
    try {
      // 1. Fazer login na API
      final user = await _apiService.login(email, password);
      final token = _apiService.authToken;

      if (user != null && token != null) {
        _currentUser = user;
        _authToken = token;

        // 2. Configurar callbacks do WebSocket
        _setupWebSocketCallbacks();

        // 3. Conectar ao WebSocket AWS
        await _websocketService.connect(token, user.id);

        return true;
      }

      return false;
    } catch (e) {
      print('Erro no login: $e');
      return false;
    }
  }

  // Fazer logout e desconectar WebSocket
  Future<void> logout() async {
    await _websocketService.disconnect();
    _currentUser = null;
    _authToken = null;
  }

  // Navegar para notificações (implementar conforme sua estrutura)
  void _navigateToNotifications() {
    // Navigator.pushNamed(context, '/notifications');
  }
}

// EXEMPLO DE USO NO WIDGET PRINCIPAL:

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthenticationManager _authManager = AuthenticationManager();

  @override
  void dispose() {
    _authManager.logout(); // Desconectar WebSocket ao fechar app
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logistics App',
      home: LoginScreen(authManager: _authManager),
    );
  }
}

// EXEMPLO NO LOGIN SCREEN:

class LoginScreen extends StatelessWidget {
  final AuthenticationManager authManager;

  LoginScreen({required this.authManager});

  Future<void> _handleLogin(String email, String password) async {
    final success = await authManager.login(email, password);
    
    if (success) {
      // Navegar para tela principal
      print('Login bem-sucedido! WebSocket conectado.');
    } else {
      // Mostrar erro
      print('Erro no login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sua UI de login aqui...
    return Container();
  }
}