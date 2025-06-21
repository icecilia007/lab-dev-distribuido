
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../models/pedido.dart';
import '../../services/api_service.dart';
import '../order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final int userId;
  final String userType;
  final ApiService apiService;

  const OrderHistoryScreen({
    Key? key,
    required this.userId,
    required this.apiService,
    required this.userType,
  }) : super(key: key);

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Pedido>> _pedidos;
  String _filterStatus = 'TODOS';
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadPedidos();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  void _loadPedidos() {
    _pedidos = widget.apiService.getPedidosByCliente(widget.userId,widget.userType);
  }

  @override
  Widget build(BuildContext context) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Histórico de Pedidos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_off, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_isOffline)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Mostrando apenas pedidos entregues armazenados localmente',
                      style: TextStyle(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildFilterChips(),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadPedidos();
              });
            },
            child: FutureBuilder<List<Pedido>>(
              future: _pedidos,
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
                              _loadPedidos();
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
                        Icon(
                          Icons.history,
                          color: Colors.grey,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Você ainda não possui pedidos',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                } else {
                  final filteredPedidos = _isOffline
                    ? snapshot.data!.where((pedido) => pedido.status == 'ENTREGUE').toList()
                    : _filterStatus == 'TODOS'
                        ? snapshot.data!
                        : snapshot.data!.where((pedido) => pedido.status == _filterStatus).toList();

                  if (filteredPedidos.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: Colors.grey,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum pedido encontrado com esse filtro',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPedidos.length,
                    itemBuilder: (context, index) {
                      final pedido = filteredPedidos[index];
                      return _buildOrderHistoryCard(pedido);
                    },
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    if (_isOffline) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              selected: true,
              label: const Text('Entregue'),
              onSelected: (_) {}, // Desabilitado
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue,
              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    // Caso contrário, mostrar todos os filtros
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('TODOS', 'Todos'),
          const SizedBox(width: 8),
          _buildFilterChip('AGUARDANDO_COLETA', 'Aguardando'),
          const SizedBox(width: 8),
          _buildFilterChip('EM_ROTA', 'Em Rota'),
          const SizedBox(width: 8),
          _buildFilterChip('ENTREGUE', 'Entregue'),
          const SizedBox(width: 8),
          _buildFilterChip('CANCELADO', 'Cancelado'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _filterStatus == status;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _filterStatus = status;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildOrderHistoryCard(Pedido pedido) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              if (pedido.status != 'CANCELADO' && pedido.status != 'ENTREGUE') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
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
                      child: const Text('Ver Rastreamento'),
                    ),
                  ],
                ),
              ],
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
}
