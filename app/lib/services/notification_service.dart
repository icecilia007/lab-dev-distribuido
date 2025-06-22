import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Function(Map<String, dynamic>)? _onNotificationReceived;

  late final String _awsWebSocketUrl;

  NotificationService() {
    _awsWebSocketUrl = dotenv.env['AWS_WEBSOCKET_URL'] ?? '';
    if (_awsWebSocketUrl.isEmpty) {
      throw Exception('AWS_WEBSOCKET_URL não está definido no .env');
    }
  }

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

  Future<void> connectToWebSocket(String userId, String token) async {
    if (_isConnected) {
      await disconnectWebSocket();
    }

    print("Criando conexão WebSocket AWS para o usuário com id: $userId");

    try {
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
          _scheduleReconnection(userId, token);
        },
        onDone: () {
          print('WebSocket AWS connection closed');
          _isConnected = false;
          _scheduleReconnection(userId, token);
        },
      );

      print('WebSocket AWS conectado para usuário $userId');
    } catch (e) {
      print('Falha ao conectar ao WebSocket AWS: $e');
      _isConnected = false;
      _scheduleReconnection(userId, token, delay: 10);
    }
  }

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
      final Map<String, dynamic> notificationData;

      if (message is String) {
        notificationData = jsonDecode(message);
      } else if (message is Map) {
        notificationData = Map<String, dynamic>.from(message);
      } else {
        print('Tipo de mensagem inesperado: ${message.runtimeType}');
        return;
      }

      if (notificationData.containsKey('action') &&
          notificationData['action'] == 'notification') {
        final data = notificationData['data'] ?? notificationData;
        _processAWSNotification(data);
      } else {
        _processLegacyNotification(notificationData);
      }

      if (_onNotificationReceived != null) {
        _onNotificationReceived!(notificationData);
      }
    } catch (e, stackTrace) {
      print('Erro ao processar notificação: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _processAWSNotification(Map<String, dynamic> data) {
    final titulo = data['titulo'] ?? data['title'] ?? 'Nova Notificação';
    final mensagem = data['mensagem'] ?? data['message'] ?? data['body'] ?? '';
    final tipo = data['tipo'] ?? data['type'] ?? 'info';
    final id = data['id'] ?? DateTime.now().millisecondsSinceEpoch;

    showNotification(
      id: id is int ? id : int.tryParse(id.toString()) ?? DateTime.now().millisecondsSinceEpoch,
      title: titulo,
      body: mensagem,
      payload: jsonEncode(data),
    );

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
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
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
