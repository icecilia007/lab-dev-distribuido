import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pedido.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../manager/notification_manager.dart';
import 'new_order_screen.dart';
import '../notifications_screen.dart';
import '../order_tracking_screen.dart';
import 'order_history_screen.dart';
import '../settings_screen.dart';
import 'package:badges/badges.dart' as badges;


class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;

  const HomeScreen({
    Key? key,
    required this.authService,
    required this.apiService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Future<List<Pedido>> _pedidosAtivos;

  @override
  void initState() {
    super.initState();
    _loadPedidosAtivos();
  }

  void _loadPedidosAtivos() {
    final user = widget.authService.currentUser!;
    _pedidosAtivos = widget.apiService.getPedidosByCliente(user.id,user.type.toLowerCase() );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _loadPedidosAtivos();
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

    final List<Widget> _widgetOptions = <Widget>[
      _buildDashboard(user.id),
      OrderHistoryScreen(userId: user.id, apiService: widget.apiService,userType: user.type,),
      SettingsScreen(onLogout: _logout, authService: widget.authService, apiService: widget.apiService,),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
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

  Widget _buildDashboard(int clienteId) {
    return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadPedidosAtivos();
          });
        },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${widget.authService.currentUser!.name}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8), // Add spacing between name and button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NewOrderScreen(
                      apiService: widget.apiService,
                      authService: widget.authService,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const Text(
        'Pedidos Ativos',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<Pedido>>(
        future: _pedidosAtivos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar pedidos: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadPedidosAtivos();
                      });
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.grey,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Você não possui pedidos ativos no momento',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => NewOrderScreen(
                            apiService: widget.apiService,
                            authService: widget.authService,
                          ),
                        ),
                      );
                    },
                    child: const Text('Fazer um Pedido'),
                  ),
                ],
              ),
            );
          } else {
            final activeOrders = snapshot.data!.where((order) =>
            order.status != 'ENTREGUE' &&
                order.status != 'CANCELADO').toList();

            if (activeOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Colors.grey,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Você não possui pedidos ativos no momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NewOrderScreen(
                              apiService: widget.apiService,
                              authService: widget.authService,
                            ),
                          ),
                        );
                      },
                      child: const Text('Fazer um Pedido'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final pedido = activeOrders[index];
                return _buildOrderCard(pedido);
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

  Widget _buildOrderCard(Pedido pedido) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OrderTrackingScreen(
                pedidoId: pedido.id,
                apiService: widget.apiService,
              ),
            ),
          );
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
                    'Pedido #${pedido.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  _buildStatusChip(pedido.status),
                ],
              ),
              const Divider(height: 24),
              Text('Tipo: ${pedido.tipoMercadoria}'),
              const SizedBox(height: 8),
              Text(
                'Data: ${pedido.formattedDate}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                'Distância: ${pedido.distanciaKm.toStringAsFixed(1)} Km',
              ),
              const SizedBox(height: 8),
              Text(
                'Tempo estimado: ${pedido.tempoEstimadoMinutos} minutos',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OrderTrackingScreen(
                            pedidoId: pedido.id,
                            apiService: widget.apiService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Rastrear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (pedido.status != 'CANCELADO' &&
                      pedido.status != 'ENTREGUE' &&
                      pedido.status != 'EM_ROTA')
                    TextButton.icon(
                      onPressed: () => _showCancelDialog(pedido.id),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _showCancelDialog(int pedidoId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Pedido'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem certeza que deseja cancelar este pedido?'),
                Text(
                  'Esta ação não pode ser desfeita.',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Não'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sim, Cancelar'),
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final success = await widget.apiService.cancelarPedido(pedidoId);

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pedido cancelado com sucesso'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Erro ao cancelar pedido'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }

                  setState(() {
                    _loadPedidosAtivos();
                  });
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao cancelar pedido: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

