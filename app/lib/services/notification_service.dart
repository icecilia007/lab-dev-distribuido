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
    print("Criando conexão web socket para o cliente com id: { $userId }");

    try {

      // final wsUrl = Uri(
      //     scheme: 'ws',
      //     host: '10.0.2.2',
      //     port: 8000,
      //     path: '/ws-notificacao',
      //     queryParameters: {'userId': userId}
      // ).toString();

      final wsUrl = 'ws://10.0.2.2:8000/ws-notificacao?userId=$userId';

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        headers: {
          'Authorization': 'Bearer $token'
        },
      );

      _isConnected = true;

      _channel!.stream.listen((message) {
        _handleIncomingMessage(message);
      }, onError: (error) {
        print('WebSocket error: $error');
        _isConnected = false;
      }, onDone: () {
        print('WebSocket connection closed');
        _isConnected = false;
      });

      print('WebSocket conectado para usuário $userId');
    } catch (e) {
      print('Falha ao conectar ao WebSocket: $e');
      _isConnected = false;
    }
  }


  Future<void> disconnectWebSocket() async {
    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
      _isConnected = false;
    }
  }

  void _handleIncomingMessage(dynamic message) {
    print('WebSocket - Mensagem recebida: $message');

    try {
      print('WebSocket - Tipo da mensagem: ${message.runtimeType}');

      final Map<String, dynamic> notificationData;
      if (message is String) {
        print('WebSocket - Convertendo string para JSON');
        notificationData = jsonDecode(message);
      } else if (message is Map) {
        print('WebSocket - Mensagem já é um Map');
        notificationData = Map<String, dynamic>.from(message);
      } else {
        print('WebSocket - Tipo de mensagem inesperado');
        return;
      }

      print('WebSocket - Dados da notificação: $notificationData');

      String? tipoEvento = notificationData['tipoEvento'] ??
          notificationData['evento'] ??
          notificationData['dadosEvento']?['evento'];

      if(tipoEvento!=null) {
        if (tipoEvento == 'PEDIDO_DISPONIVEL') {
          final pedidoId = notificationData['dadosEvento']?['dados']?['pedidoId'];

          final notificacaoFormatada = {
            'id': pedidoId ?? DateTime
                .now()
                .millisecondsSinceEpoch,
            'titulo': 'Novo pedido disponível',
            'mensagem': notificationData['mensagem'] ?? 'Pedido próximo à sua localização',
            'dataCriacao': DateTime.now().toIso8601String(),
            'lida': false,
            'payload': jsonEncode(notificationData)
          };

          showNotification(
            id: pedidoId ?? DateTime
                .now()
                .millisecondsSinceEpoch,
            title: 'Novo pedido disponível',
            body: notificationData['mensagem'] ?? 'Pedido próximo à sua localização',
            payload: jsonEncode(notificationData),
          );

          if (_onNotificationReceived != null) {
            _onNotificationReceived!(notificacaoFormatada);
          }
        } else{
          showNotification(
            id: notificationData['id'] ?? DateTime.now().millisecondsSinceEpoch,
            title: notificationData['titulo'] ?? 'Nova notificação',
            body: notificationData['mensagem'] ?? '',
          );
        }

      }

      if (_onNotificationReceived != null) {
        print('WebSocket - Chamando callback de notificação');
        _onNotificationReceived!(notificationData);
      } else {
        print('WebSocket - Nenhum callback registrado');
      }
    } catch (e, stackTrace) {
      print('WebSocket - Erro ao processar notificação: $e');
      print('WebSocket - Stack trace: $stackTrace');
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
