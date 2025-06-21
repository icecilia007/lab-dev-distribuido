// ARQUIVO: app/lib/services/notification_service.dart
// 
// SUBSTITUA o conteúdo atual por este código atualizado para AWS WebSocket

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Function(Map<String, dynamic>)? _onNotificationReceived;

  // URL do WebSocket AWS (substitua pelo seu WebSocket ID)
  static const String _awsWebSocketUrl = 'wss://23b38pazkc.execute-api.us-east-1.amazonaws.com/prod';

  Future init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'channel_id',
      'Logistics Notifications',
      description: 'Channel for logistics app notifications',
      importance: Importance.high,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final payloadData = jsonDecode(details.payload!);
            if (_onNotificationReceived != null) {
              _onNotificationReceived!(payloadData);
            }
          } catch (e) {
            print('Erro ao processar payload da notificação: $e');
          }
        }
      },
    );
  }

  /// Conectar ao WebSocket AWS
  Future<void> connectToWebSocket(String userId, String token) async {
    if (_isConnected) {
      await disconnectWebSocket();
    }
    print("Criando conexão WebSocket AWS para o usuário com id: $userId");

    try {
      // Construir URL com parâmetros de autenticação
      final wsUrl = '$_awsWebSocketUrl?token=$token&userId=$userId';

      print('Conectando ao WebSocket AWS: $wsUrl');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      _isConnected = true;

      _channel!.stream.listen(
              (message) {
            _handleIncomingMessage(message);
          },
          onError: (error) {
            print('WebSocket AWS error: $error');
            _isConnected = false;
            // Tentar reconectar após 5 segundos
            _scheduleReconnection(userId, token);
          },
          onDone: () {
            print('WebSocket AWS connection closed');
            _isConnected = false;
            // Tentar reconectar após 5 segundos
            _scheduleReconnection(userId, token);
          }
      );

      print('WebSocket AWS conectado para usuário $userId');
    } catch (e) {
      print('Falha ao conectar ao WebSocket AWS: $e');
      _isConnected = false;
      // Tentar reconectar após 10 segundos em caso de erro
      _scheduleReconnection(userId, token, delay: 10);
    }
  }

  /// Reagendar reconexão automática
  void _scheduleReconnection(String userId, String token, {int delay = 5}) {
    Future.delayed(Duration(seconds: delay), () {
      if (!_isConnected) {
        print('Tentando reconectar ao WebSocket AWS...');
        connectToWebSocket(userId, token);
      }
    });
  }

  Future<void> disconnectWebSocket() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _isConnected = false;
      print('WebSocket AWS desconectado');
    }
  }

  void _handleIncomingMessage(dynamic message) {
    print('WebSocket AWS - Mensagem recebida: $message');

    try {
      print('WebSocket AWS - Tipo da mensagem: ${message.runtimeType}');

      final Map<String, dynamic> notificationData;
      if (message is String) {
        print('WebSocket AWS - Convertendo string para JSON');
        notificationData = jsonDecode(message);
      } else if (message is Map) {
        print('WebSocket AWS - Mensagem já é um Map');
        notificationData = Map<String, dynamic>.from(message);
      } else {
        print('WebSocket AWS - Tipo de mensagem inesperado');
        return;
      }

      print('WebSocket AWS - Dados da notificação: $notificationData');

      // Verificar se é uma notificação do sistema AWS
      if (notificationData.containsKey('action') &&
          notificationData['action'] == 'notification') {

        final data = notificationData['data'] ?? notificationData;
        _processAWSNotification(data);

      } else {
        // Manter compatibilidade com formato antigo
        _processLegacyNotification(notificationData);
      }

      // Sempre chamar o callback se registrado
      if (_onNotificationReceived != null) {
        print('WebSocket AWS - Chamando callback de notificação');
        _onNotificationReceived!(notificationData);
      } else {
        print('WebSocket AWS - Nenhum callback registrado');
      }

    } catch (e, stackTrace) {
      print('WebSocket AWS - Erro ao processar notificação: $e');
      print('WebSocket AWS - Stack trace: $stackTrace');
    }
  }

  /// Processar notificações do formato AWS
  void _processAWSNotification(Map<String, dynamic> data) {
    final titulo = data['titulo'] ?? data['title'] ?? 'Nova Notificação';
    final mensagem = data['mensagem'] ?? data['message'] ?? data['body'] ?? '';
    final tipo = data['tipo'] ?? data['type'] ?? 'info';
    final id = data['id'] ?? DateTime.now().millisecondsSinceEpoch;

    print('Processando notificação AWS: $titulo - $mensagem');

    // Criar notificação local
    showNotification(
      id: id is int ? id : int.tryParse(id.toString()) ?? DateTime.now().millisecondsSinceEpoch,
      title: titulo,
      body: mensagem,
      payload: jsonEncode(data),
    );

    // Formatar para callback
    final notificacaoFormatada = {
      'id': id,
      'titulo': titulo,
      'mensagem': mensagem,
      'tipo': tipo,
      'dataCriacao': DateTime.now().toIso8601String(),
      'lida': false,
      'payload': jsonEncode(data)
    };

    if (_onNotificationReceived != null) {
      _onNotificationReceived!(notificacaoFormatada);
    }
  }

  /// Manter compatibilidade com formato antigo
  void _processLegacyNotification(Map<String, dynamic> notificationData) {
    String? tipoEvento = notificationData['tipoEvento'] ??
        notificationData['evento'] ??
        notificationData['dadosEvento']?['evento'];

    if (tipoEvento != null) {
      if (tipoEvento == 'PEDIDO_DISPONIVEL') {
        final pedidoId = notificationData['dadosEvento']?['dados']?['pedidoId'];

        final notificacaoFormatada = {
          'id': pedidoId ?? DateTime.now().millisecondsSinceEpoch,
          'titulo': 'Novo pedido disponível',
          'mensagem': notificationData['mensagem'] ?? 'Pedido próximo à sua localização',
          'dataCriacao': DateTime.now().toIso8601String(),
          'lida': false,
          'payload': jsonEncode(notificationData)
        };

        showNotification(
          id: pedidoId ?? DateTime.now().millisecondsSinceEpoch,
          title: 'Novo pedido disponível',
          body: notificationData['mensagem'] ?? 'Pedido próximo à sua localização',
          payload: jsonEncode(notificationData),
        );

        if (_onNotificationReceived != null) {
          _onNotificationReceived!(notificacaoFormatada);
        }
      } else {
        showNotification(
          id: notificationData['id'] ?? DateTime.now().millisecondsSinceEpoch,
          title: notificationData['titulo'] ?? 'Nova notificação',
          body: notificationData['mensagem'] ?? '',
        );
      }
    }
  }

  void setNotificationCallback(Function(Map<String, dynamic>) callback) {
    _onNotificationReceived = callback;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'channel_id',
      'Logistics Notifications',
      channelDescription: 'Channel for logistics app notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  bool get isConnected => _isConnected;
}