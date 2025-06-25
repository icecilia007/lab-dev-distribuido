import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class DriverStatisticsScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;

  const DriverStatisticsScreen({
    Key? key,
    required this.apiService,
    required this.authService,
  }) : super(key: key);

  @override
  State<DriverStatisticsScreen> createState() => _DriverStatisticsScreenState();
}

class _DriverStatisticsScreenState extends State<DriverStatisticsScreen> {
  bool _isLoading = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _statistics;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    if (widget.authService.currentUser == null) {
      setState(() {
        _errorMessage = 'Usuário não autenticado';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final driverId = widget.authService.currentUser!.id;
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final startDateStr = dateFormatter.format(_startDate);
      final endDateStr = dateFormatter.format(_endDate);

      final statistics = await widget.apiService.getDriverStatistics(
          driverId,
          startDateStr,
          endDateStr
      );

      setState(() {
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar estatísticas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) {
          _endDate = _startDate;
        }
      });
      _fetchStatistics();
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _fetchStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas do Motorista'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildStatisticsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchStatistics,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    if (_statistics == null) {
      return const Center(
        child: Text('Nenhuma estatística disponível'),
      );
    }

    final dateFormatter = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seleção de período
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Período',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectStartDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data Inicial',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(dateFormatter.format(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: _selectEndDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Data Final',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(dateFormatter.format(_endDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Estatísticas principais
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'Distância Total',
                    '${(_statistics!['distanciaTotalKm'] / 1000).toStringAsFixed(2)} km',
                    Icons.timeline,
                  ),
                  _buildStatItem(
                    'Tempo em Movimento',
                    '${_statistics!['tempoEmMovimentoMinutos']} minutos',
                    Icons.timer,
                  ),
                  _buildStatItem(
                    'Velocidade Média',
                    '${(_statistics!['velocidadeMediaKmH'] / 1000).toStringAsFixed(2)} km/h',
                    Icons.speed,
                  ),
                  _buildStatItem(
                    'Pedidos Atendidos',
                    '${_statistics!['pedidosAtendidos']}',
                    Icons.delivery_dining,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Distribuição de Status
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribuição de Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusDistribution(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Pedidos Atendidos
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pedidos Atendidos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOrdersList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution() {
    final statusCounts = _statistics!['contagemPorStatus'] as Map<String, dynamic>;
    final total = _statistics!['totalRegistros'] as int;

    return Column(
      children: [
        Container(
          height: 40,
          child: Row(
            children: [
              _buildStatusBar('Em Movimento', statusCounts['EM_MOVIMENTO'] ?? 0, total, Colors.blue),
              _buildStatusBar('Disponível', statusCounts['DISPONIVEL'] ?? 0, total, Colors.green),
              _buildStatusBar('Parado', statusCounts['PARADO'] ?? 0, total, Colors.orange),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusLegend('Em Movimento', Colors.blue),
            _buildStatusLegend('Disponível', Colors.green),
            _buildStatusLegend('Parado', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    double percentage = total > 0 ? count / total : 0;
    return Expanded(
      flex: count > 0 ? count : 1,
      child: Container(
        color: count > 0 ? color : Colors.grey.withOpacity(0.3),
        child: Center(
          child: Text(
            count > 0 ? '${(percentage * 100).toInt()}%' : '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Widget _buildOrdersList() {
    final orders = _statistics!['listaPedidosAtendidos'] as List<dynamic>;

    return orders.isEmpty
        ? const Center(child: Text('Nenhum pedido atendido neste período'))
        : Column(
      children: orders
          .where((orderId) => orderId != null)
          .map<Widget>((orderId) => ListTile(
        leading: const Icon(Icons.receipt, color: Colors.blue),
        title: Text('Pedido #$orderId'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegação para detalhes do pedido
        },
      ))
          .toList(),
    );
  }
}
