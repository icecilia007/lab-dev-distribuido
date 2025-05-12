import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_manager.dart';
import '../services/notification_service.dart';
import 'dialog/new_order_details_dialog.dart';
import 'notifications_screen.dart';
import 'package:badges/badges.dart' as badges;

class DriverHomeScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const DriverHomeScreen({
    Key? key,
    required this.authService,
    required this.apiService,
  }) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Pedido>> _entregasAtivas;

  @override
  void initState() {
    super.initState();
    _loadEntregasAtivas();
    _initializeLocationService();
    _setupNotificationHandling();
  }

  void _loadEntregasAtivas() {
    final user = widget.authService.currentUser!;
    _entregasAtivas = widget.apiService.getPedidosByMotorista(user.id);
  }

  Future<void> _initializeLocationService() async {
    final locationService = LocationService();
    bool hasPermission = await locationService.init();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de localização necessária para funcionamento completo do app'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _setupNotificationHandling() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    notificationService.setNotificationCallback((data) {
      // Verificar diferentes estruturas possíveis
      if (data['tipoEvento'] == 'PEDIDO_DISPONIVEL' ||
          (data['dadosEvento'] != null && data['dadosEvento']['evento'] == 'PEDIDO_DISPONIVEL')) {

        _showPedidoDisponivel(data);
      }
    });

    // Ajustar também o método que processa notificações quando o app é aberto por uma notificação
    FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails().then((details) {
      if (details != null && details.didNotificationLaunchApp &&
          details.notificationResponse?.payload != null) {
        try {
          final data = jsonDecode(details.notificationResponse!.payload!);
          if (data['tipoEvento'] == 'PEDIDO_DISPONIVEL' ||
              (data['dadosEvento'] != null && data['dadosEvento']['evento'] == 'PEDIDO_DISPONIVEL')) {
            _showPedidoDisponivel(data);
          }
        } catch (e) {
          print('Erro ao processar payload da notificação: $e');
        }
      }
    });
  }

  void _showPedidoDisponivel(Map<String, dynamic> data) {
    // Obter os dados do pedido da estrutura correta
    final pedidoData = data['dadosEvento'] != null ?
    data['dadosEvento']['dados'] :
    data['dados'];

    if (pedidoData == null) {
      print('Dados do pedido não encontrados na notificação');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewOrderDetailsDialog(
        pedidoData: pedidoData,
        apiService: widget.apiService,
        motoristaId: widget.authService.currentUser!.id,
        onAccepted: () {
          setState(() {
            _loadEntregasAtivas();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pedido aceito com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _loadEntregasAtivas();
      }
    });
  }

  Future<void> _logout() async {
    await widget.authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser!;
    final List<Widget> _widgetOptions = [
      _buildDashboard(user.id),
      _buildEntregasHistorico(user.id),
      _buildConfiguracoesMotorista(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logística'),
        actions: [
          Consumer<NotificationManager>(
            builder: (context, notificationManager, child) {
              return badges.Badge(
                position: badges.BadgePosition.topEnd(top: 5, end: 5),
                showBadge: notificationManager.unreadCount > 0,
                badgeContent: Text(
                  notificationManager.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Entregas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDashboard(int motoristId) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadEntregasAtivas();
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Olá, ${widget.authService.currentUser!.name}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusButton(),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Entregas Atribuídas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Pedido>>(
              future: _entregasAtivas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar entregas: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loadEntregasAtivas();
                            });
                          },
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined, color: Colors.grey, size: 60),
                        SizedBox(height: 16),
                        Text(
                          'Você não possui entregas atribuídas no momento',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final entrega = snapshot.data![index];
                      return _buildEntregaCard(entrega);
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showStatusDialog();
      },
      icon: const Icon(Icons.online_prediction),
      label: const Text('Status: Disponível'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atualizar Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Disponível'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar atualização de status
                },
              ),
              ListTile(
                leading: const Icon(Icons.delivery_dining, color: Colors.blue),
                title: const Text('Em Entrega'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar atualização de status
                },
              ),
              ListTile(
                leading: const Icon(Icons.do_not_disturb_on, color: Colors.red),
                title: const Text('Indisponível'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar atualização de status
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntregaCard(Pedido entrega) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Implementar navegação para detalhes da entrega
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Entrega #${entrega.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(entrega.status),
                ],
              ),
              const Divider(height: 24),
              Text('Tipo: ${entrega.tipoMercadoria}'),
              const SizedBox(height: 8),
              Text(
                'Data: ${entrega.formattedDate}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Distância: ${entrega.distanciaKm.toStringAsFixed(1)} Km',
              ),
              const SizedBox(height: 8),
              Text(
                'Tempo estimado: ${entrega.tempoEstimadoMinutos} minutos',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      // Implementar navegação para rota
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Iniciar Rota'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showUpdateStatusDialog(entrega.id);
                    },
                    icon: const Icon(Icons.update),
                    label: const Text('Atualizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(int entregaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atualizar Status da Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.local_shipping, color: Colors.blue),
                title: const Text('Em Rota'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar atualização de status
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Entregue'),
                onTap: () {
                  Navigator.pop(context);
                  // Implementar atualização de status
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_problem, color: Colors.orange),
                title: const Text('Reportar Problema'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportProblemDialog(entregaId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportProblemDialog(int entregaId) {
    final _problemaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reportar Problema'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Problema',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACIDENTE', child: Text('Acidente')),
                  DropdownMenuItem(value: 'BLOQUEIO', child: Text('Bloqueio na Via')),
                  DropdownMenuItem(value: 'VEICULO', child: Text('Problema no Veículo')),
                  DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                ],
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _problemaController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implementar envio do relatório
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Problema reportado com sucesso'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Reportar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor = Colors.white;
    String statusText;

    switch (status) {
      case 'AGUARDANDO_COLETA':
        bgColor = Colors.orange;
        statusText = 'Aguardando Coleta';
        break;
      case 'EM_ROTA':
        bgColor = Colors.blue;
        statusText = 'Em Rota';
        break;
      case 'ENTREGUE':
        bgColor = Colors.green;
        statusText = 'Entregue';
        break;
      case 'CANCELADO':
        bgColor = Colors.red;
        statusText = 'Cancelado';
        break;
      default:
        bgColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEntregasHistorico(int motoristId) {
    // Implementar histórico de entregas do motorista
    return const Center(
      child: Text('Histórico de Entregas'),
    );
  }

  Widget _buildConfiguracoesMotorista() {
    // Implementar configurações do motorista
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            widget.authService.currentUser!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.authService.currentUser!.email,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (widget.authService.currentUser!.phone != null)
            Text(
              widget.authService.currentUser!.phone!,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.directions_car),
            title: const Text('Meus Veículos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Implementar navegação para tela de veículos
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Desempenho'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Implementar navegação para tela de desempenho
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Implementar navegação para tela de notificações
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}