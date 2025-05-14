import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pedido.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_manager.dart';
import '../services/notification_service.dart';
import 'dialog/new_order_details_dialog.dart';
import 'driver_statistics_screen.dart';
import 'notifications_screen.dart';
import 'package:badges/badges.dart' as badges;
import 'order_tracking_screen.dart';
import '../services/location_update_service.dart';

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
  bool _isDarkMode = false;
  bool _pushNotificationsEnabled = false;
  bool _emailNotificationsEnabled = false;
  late Future<List<Pedido>> _entregasAtivas;
  late LocationUpdateService _locationUpdateService;

  @override
  void initState() {
    super.initState();
    _loadEntregasAtivas();
    _initializeLocationService();
    _setupNotificationHandling();
    _loadSettings();

    _locationUpdateService = LocationUpdateService(
      apiService: widget.apiService,
      driverId: widget.authService.currentUser!.id,
    );

    _locationUpdateService.setStatusCallback((newStatus) {
      setState(() {
        _currentStatus = newStatus;
      });
    });

    _currentStatus = _locationUpdateService.lastSentStatus;

    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    int? activeOrderId = await _getActiveOrderId();
    _locationUpdateService.startLocationUpdates(activeOrderId);
  }

  Future<int?> _getActiveOrderId() async {
    try {
      final entregas = await widget.apiService.getPedidosByMotorista(
          widget.authService.currentUser!.id
      );

      final activeOrders = entregas.where((pedido) =>
      pedido.status == 'EM_ROTA' || pedido.status == 'AGUARDANDO_COLETA'
      ).toList();

      return activeOrders.isNotEmpty ? activeOrders.first.id : null;
    } catch (e) {
      print('Error getting active order: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _locationUpdateService.stopLocationUpdates();
    super.dispose();
  }

  Future<void> _loadEntregasAtivas() async {
    final user = widget.authService.currentUser!;
    setState(() {
      _entregasAtivas = widget.apiService.getPedidosByMotorista(user.id);
    });

    try {
      final entregas = await _entregasAtivas;

      bool hasActiveDeliveries = entregas.any((pedido) =>
      pedido.status == 'EM_ROTA' || pedido.status == 'AGUARDANDO_COLETA');

      setState(() {
        if (!hasActiveDeliveries) {
          _currentStatus = 'DISPONIVEL';
        }
      });
    } catch (e) {
      print('Erro ao verificar pedidos ativos: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _pushNotificationsEnabled = prefs.getBool('pushNotifications') ?? false;
      _emailNotificationsEnabled = prefs.getBool('emailNotifications') ?? false;
    });


    if (widget.authService.currentUser != null) {
      final userId = widget.authService.currentUser!.id;
      final apiPreferences = await widget.apiService.buscarPreferenciasNotificacao(userId);

      if (apiPreferences != null) {
        final tipoPreferido = apiPreferences['tipoPreferido'] as String;
        setState(() {
          _pushNotificationsEnabled = tipoPreferido == 'PUSH' || tipoPreferido == 'AMBOS';
          _emailNotificationsEnabled = tipoPreferido == 'EMAIL' || tipoPreferido == 'AMBOS';
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setBool('pushNotifications', _pushNotificationsEnabled);
    await prefs.setBool('emailNotifications', _emailNotificationsEnabled);

    if (widget.authService.currentUser != null) {
      final userId = widget.authService.currentUser!.id;
      final userEmail = widget.authService.currentUser!.email;


      await widget.apiService.atualizarPreferenciasNotificacao(
        userId,
        _emailNotificationsEnabled,
        _pushNotificationsEnabled,
        userEmail,
      );
    }
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
      if (data['tipoEvento'] == 'PEDIDO_DISPONIVEL' ||
          (data['dadosEvento'] != null && data['dadosEvento']['evento'] == 'PEDIDO_DISPONIVEL')) {

        _showPedidoDisponivel(data);
      }
    });

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

  Future _logout() async {
    _locationUpdateService.stopLocationUpdates();
    await widget.authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _updateDeliveryWithCamera(int pedidoId, String novoStatus) async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

      if (photo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operação cancelada. A foto não foi tirada.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await Future.delayed(Duration(milliseconds: 100));

      if (novoStatus == 'ENTREGUE') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        final success = await widget.apiService.confirmarEntrega(
            pedidoId,
            widget.authService.currentUser!.id
        );

        if (mounted) Navigator.pop(context);

        if (success && mounted) {
          setState(() {
            _loadEntregasAtivas();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Entrega confirmada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao confirmar entrega. Por favor, tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      else if (novoStatus == 'EM_ROTA') {
        // Implementação para confirmação de coleta
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        print('Iniciando confirmação de coleta para pedido $pedidoId');
        final success = await widget.apiService.confirmarColetaComFoto(
          pedidoId,
          widget.authService.currentUser!.id,
          File(photo.path),
        );

        if (mounted) Navigator.pop(context);

        if (success && mounted) {
          setState(() {
            _loadEntregasAtivas();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coleta confirmada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          print('Coleta confirmada com sucesso para pedido $pedidoId');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha ao confirmar coleta. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
          print('Falha na confirmação de coleta para pedido $pedidoId');
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar operação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUpdateStatusDialog(int entregaId, String status) {
    switch (status) {
      case 'AGUARDANDO_COLETA':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Atualizar Status da Entrega'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.report_problem, color: Colors.orange),
                    title: const Text('Relatar Incidente'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportProblemDialog(entregaId);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_shipping, color: Colors.blue),
                    title: const Text('Coletar (com foto)'),
                    onTap: () {
                      Navigator.pop(context);
                      _updateDeliveryWithCamera(entregaId, 'EM_ROTA');
                    },
                  ),
                ],
              ),
            );
          },
        );
        break;
      case 'EM_ROTA':
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Atualizar Status da Entrega'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.report_problem, color: Colors.orange),
                    title: const Text('Relatar Incidente'),
                    onTap: () {
                      Navigator.pop(context);
                      _showReportProblemDialog(entregaId);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Entregar (com foto)'),
                    onTap: () {
                      Navigator.pop(context);
                      _updateDeliveryWithCamera(entregaId, 'ENTREGUE');
                    },
                  ),
                ],
              ),
            );
          },
        );
        break;
      default:
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
                    title: const Text('Em Rota (com foto)'),
                    onTap: () {
                      Navigator.pop(context);
                      _updateDeliveryWithCamera(entregaId, 'EM_ROTA');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Entregue (com foto)'),
                    onTap: () {
                      Navigator.pop(context);
                      _updateDeliveryWithCamera(entregaId, 'ENTREGUE');
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
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser!;
    final List<Widget> _widgetOptions = [
      _buildDashboard(user.id),
      // _buildEntregasHistorico(user.id),
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
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.history),
          //   label: 'Histórico',
          // ),
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

  Future<void> _updateStatusBasedOnActiveDeliveries() async {
    try {
      final entregas = await widget.apiService.getPedidosByMotorista(widget.authService.currentUser!.id);
      bool hasActiveDeliveries = entregas.any((pedido) =>
      pedido.status == 'EM_ROTA' || pedido.status == 'AGUARDANDO_COLETA');

      setState(() {
        if (!hasActiveDeliveries) {
          _currentStatus = 'DISPONIVEL';
        }
      });
    } catch (e) {
      print('Erro ao verificar pedidos ativos: $e');
    }
  }

  void _showStatusDialogForActiveDeliveries() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Atualizar Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text('Em Movimento'),
                onTap: () {
                  Navigator.pop(context);
                  _updateDriverStatus("EM_MOVIMENTO");
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_filled, color: Colors.orange),
                title: const Text('Parado'),
                onTap: () {
                  Navigator.pop(context);
                  _updateDriverStatus("PARADO");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _maybeShowStatusUpdateDialog() async {
    try {
      final entregas = await widget.apiService.getPedidosByMotorista(widget.authService.currentUser!.id);
      bool hasActiveDeliveries = entregas.any((pedido) =>
      pedido.status == 'EM_ROTA' || pedido.status == 'AGUARDANDO_COLETA');

      if (hasActiveDeliveries) {
        _showStatusDialogForActiveDeliveries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você está disponível. O status só pode ser alterado quando houver entregas ativas.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar entregas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatusIndicator() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_currentStatus) {
      case 'DISPONIVEL':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Disponível';
        break;
      case 'EM_MOVIMENTO':
        statusColor = Colors.blue;
        statusIcon = Icons.directions_car;
        statusText = 'Em Movimento';
        break;
      case 'PARADO':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_filled;
        statusText = 'Parado';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'Disponível';
    }

    return InkWell(
      onTap: () => _maybeShowStatusUpdateDialog(),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            'Status atual: $statusText',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '',
            style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(int motoristId) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadEntregasAtivas();
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${widget.authService.currentUser!.name}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildStatusIndicator(),
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

  String _currentStatus = 'DISPONIVEL';

  Widget _buildStatusButton() {
    Color buttonColor;
    IconData buttonIcon;

    switch (_currentStatus) {
      case 'DISPONIVEL':
        buttonColor = Colors.green;
        buttonIcon = Icons.check_circle;
        break;
      case 'EM_MOVIMENTO':
        buttonColor = Colors.blue;
        buttonIcon = Icons.directions_car;
        break;
      case 'PARADO':
        buttonColor = Colors.orange;
        buttonIcon = Icons.pause_circle_filled;
        break;
      default:
        buttonColor = Colors.grey;
        buttonIcon = Icons.help_outline;
    }

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

  String _formatStatus(String status) {
    switch (status) {
      case 'DISPONIVEL': return 'Disponível';
      case 'EM_MOVIMENTO': return 'Em Movimento';
      case 'PARADO': return 'Parado';
      default: return status;
    }
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
                  _updateDriverStatus("DISPONIVEL");
                },
              ),
              ListTile(
                leading: const Icon(Icons.directions_car, color: Colors.blue),
                title: const Text('Em Movimento'),
                onTap: () {
                  Navigator.pop(context);
                  _updateDriverStatus("EM_MOVIMENTO");
                },
              ),
              ListTile(
                leading: const Icon(Icons.pause_circle_filled, color: Colors.orange),
                title: const Text('Parado'),
                onTap: () {
                  Navigator.pop(context);
                  _updateDriverStatus("PARADO");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _updateDriverStatus(String statusVeiculo) async {
    final user = widget.authService.currentUser!;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get current location
      final position = await _getCurrentLocation();

      // Dismiss loading indicator
      if (mounted) Navigator.pop(context);

      final bool success = await widget.apiService.atualizarLocalizacaoMotorista(
        user.id,
        position.latitude,
        position.longitude,
        statusVeiculo,
      );

      if (success && mounted) {
        setState(() {
          _currentStatus = statusVeiculo;
        });

        _locationUpdateService.setLastSentStatus(statusVeiculo);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status atualizado para ${_formatStatus(statusVeiculo)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEntregaCard(Pedido entrega) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
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
                  if (entrega.status != 'ENTREGUE') // Só mostra o botão de rota se não estiver entregue
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderTrackingScreen(
                              pedidoId: entrega.id,
                              apiService: widget.apiService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Ver Rota'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  // Botão condicional baseado no status
                  if (entrega.status == 'EM_PROCESSAMENTO')
                    ElevatedButton.icon(
                      onPressed: () => _aceitarPedido(entrega.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Aceitar Pedido'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (entrega.status != 'ENTREGUE')
                    ElevatedButton.icon(
                      onPressed: () => _showUpdateStatusDialog(entrega.id, entrega.status),
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

  Future _aceitarPedido(int pedidoId) async {
    try {
      final position = await _getCurrentLocation();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final success = await widget.apiService.aceitarPedido(
          pedidoId,
          widget.authService.currentUser!.id,
          position.latitude,
          position.longitude
      );

      if (mounted) Navigator.pop(context);

      if (success && mounted) {
        setState(() {
          _loadEntregasAtivas();
        });

        // Update the order ID in the location service
        _locationUpdateService.updateOrderId(pedidoId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido aceito com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao aceitar pedido: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showReportProblemDialog(int entregaId) {
    final _problemaController = TextEditingController();
    String _selectedTipo = 'BLOQUEIO';
    double _raioImpacto = 1.0;
    int _duracaoHoras = 5;

    // Guarda referência ao contexto original
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Reportar Incidente'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Incidente',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTipo,
                  items: const [
                    DropdownMenuItem(value: 'ACIDENTE', child: Text('Acidente')),
                    DropdownMenuItem(value: 'BLOQUEIO', child: Text('Bloqueio na Via')),
                    DropdownMenuItem(value: 'VEICULO', child: Text('Problema no Veículo')),
                    DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _selectedTipo = value;
                    }
                  },
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Raio de Impacto (km)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: '1.0',
                        onChanged: (value) {
                          _raioImpacto = double.tryParse(value) ?? 1.0;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Duração (horas)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        initialValue: '5',
                        onChanged: (value) {
                          _duracaoHoras = int.tryParse(value) ?? 5;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Feche o diálogo principal
                Navigator.pop(dialogContext);

                // Capture os dados para uso posterior
                final selectedTipo = _selectedTipo;
                final descricao = _problemaController.text;
                final raioImpacto = _raioImpacto;
                final duracaoHoras = _duracaoHoras;

                // Use um método separado para processar a solicitação
                _processarReporteIncidente(
                    selectedTipo,
                    descricao,
                    raioImpacto,
                    duracaoHoras
                );
              },
              child: const Text('Reportar'),
            ),
          ],
        );
      },
    );
  }

// Método separado para processar o relatório sem depender do contexto do diálogo
  Future<void> _processarReporteIncidente(
      String tipo,
      String descricao,
      double raioImpactoKm,
      int duracaoHoras
      ) async {
    // Use o BuildContext principal da tela, não do diálogo que será descartado
    BuildContext? loadingContext;

    if (!mounted) return;

    // Exiba o indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        loadingContext = ctx;
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      // Obter a localização atual
      Position position = await Geolocator.getCurrentPosition();

      // Enviar relatório de incidente para a API
      final incidenteResponse = await widget.apiService.reportarIncidente(
        widget.authService.currentUser!.id,
        position.latitude,
        position.longitude,
        tipo,
        descricao,
        raioImpactoKm,
        duracaoHoras,
      );

      // Fechar o indicador de carregamento com segurança
      if (mounted && loadingContext != null) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      // Exibir resposta adequada
      if (incidenteResponse != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incidente reportado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Falha ao reportar incidente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fechar indicador de carregamento com segurança
      if (mounted && loadingContext != null) {
        Navigator.of(context).pop();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao reportar incidente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  // Widget _buildEntregasHistorico(int motoristId) {
  //   return const Center(
  //     child: Text('Histórico de Entregas'),
  //   );
  // }

  Widget _buildConfiguracoesMotorista() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configurações',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Aparência'),
          SwitchListTile(
            title: const Text('Tema Escuro'),
            subtitle: const Text('Ativar o tema escuro para o aplicativo'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          _buildSectionTitle('Notificações'),
          SwitchListTile(
            title: const Text('Notificações Push'),
            subtitle: const Text('Receber notificações push sobre suas entregas'),
            value: _pushNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _pushNotificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Notificações por Email'),
            subtitle: const Text('Receber atualizações por email'),
            value: _emailNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _emailNotificationsEnabled = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          _buildSectionTitle('Desempenho'),
          ListTile(
            leading: const Icon(Icons.bar_chart, color: Colors.blue),
            title: const Text('Minhas Estatísticas'),
            subtitle: const Text('Visualize seu desempenho e métricas'),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverStatisticsScreen(
                    apiService: widget.apiService,
                    authService: widget.authService,
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _buildSectionTitle('Sobre o App'),
          const ListTile(
            title: Text('Versão'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () {
              // Navegação para termos de uso
            },
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () {
              // Navegação para política de privacidade
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sair da Conta'),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }
}