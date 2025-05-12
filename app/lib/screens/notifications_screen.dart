import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/notificacao.dart';
import '../services/notification_manager.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationManager = Provider.of<NotificationManager>(context);
    final notificacoes = notificationManager.notificacoes;

    if (notificationManager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notificacoes.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      itemCount: notificacoes.length,
      itemBuilder: (context, index) {
        final notificacao = notificacoes[index];
        return NotificationItem(
          notificacao: notificacao,
          onTap: () => _handleNotificationTap(context, notificacao),
        );
      },
    );
  }

  void _handleNotificationTap(BuildContext context, Notificacao notificacao) async {
    final notificationManager = Provider.of<NotificationManager>(context, listen: false);

    if (!notificacao.lida) {
      await notificationManager.marcarComoLida(notificacao);
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
