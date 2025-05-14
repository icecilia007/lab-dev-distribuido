import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/notificacao.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_manager.dart';
import 'dialog/new_order_details_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final userId = authService.currentUser!.id;
        Provider.of<NotificationManager>(context, listen: false)
            .carregarNotificacoes(userId);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final notificationManager = Provider.of<NotificationManager>(context);
    final notificacoes = notificationManager.notificacoes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
      ),
      body: notificationManager.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificacoes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Sem notificações',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: notificacoes.length,
        itemBuilder: (context, index) {
          final notificacao = notificacoes[index];
          return NotificationItem(
            notificacao: notificacao,
            onTap: () => _handleNotificationTap(context, notificacao),
          );
        },
      ),
    );
  }


  void _handleNotificationTap(BuildContext context, Notificacao notificacao) async {
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final apiService = Provider.of<ApiService>(context, listen: false);

    if (!notificacao.lida) {
      await notificationManager.marcarComoLida(notificacao);
    }

    print("Paylod da notifição recebida ${notificacao.payload} ");

    if (notificacao.titulo.toLowerCase().contains("pedido dispon") && notificacao.payload != null) {
      try {
        // Processar dados independentemente da estrutura
        final data = jsonDecode(notificacao.payload!);

        // Extrair os dados do pedido com tratamento para diferentes estruturas
        Map<String, dynamic>? pedidoData;

        // Tentar todas as estruturas possíveis
        if (data['dadosEvento'] != null && data['dadosEvento']['dados'] != null) {
          pedidoData = Map<String, dynamic>.from(data['dadosEvento']['dados']);
        } else if (data['dados'] != null) {
          pedidoData = Map<String, dynamic>.from(data['dados']);
        }

        // Mostrar o diálogo de aceitação
        if (pedidoData != null) {
          // IMPORTANTE: Uso do Navigator.of para garantir contexto correto
          Navigator.of(context).push(
            DialogRoute(
              context: context,
              builder: (dialogContext) => NewOrderDetailsDialog(
                pedidoData: pedidoData!,
                apiService: apiService,
                motoristaId: authService.currentUser!.id,
                onAccepted: () {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido aceito com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );
          return;
        }
      } catch (e) {
        print('Erro ao processar payload para diálogo: $e');
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notificacao.titulo),
        content: Text(notificacao.mensagem),
        actions: [
          TextButton(
            child: const Text('Fechar'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

}

class NotificationItem extends StatelessWidget {
  final Notificacao notificacao;
  final VoidCallback onTap;

  const NotificationItem({
    Key? key,
    required this.notificacao,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM HH:mm');
    final date = DateTime.parse(notificacao.dataCriacao);
    final formattedDate = dateFormat.format(date);

    return ListTile(
      title: Text(
        notificacao.titulo,
        style: TextStyle(
          fontWeight: notificacao.lida ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Text(
        notificacao.mensagem,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formattedDate,
            style: TextStyle(fontSize: 12),
          ),
          if (!notificacao.lida)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
