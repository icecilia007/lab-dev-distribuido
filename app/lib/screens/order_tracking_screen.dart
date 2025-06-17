import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';  // Importar flutter_map em vez de google_maps_flutter
import 'package:latlong2/latlong.dart';        // Importar latlong2 para coordenadas
import '../models/pedido.dart';
import '../models/localizacao.dart';
import '../services/api_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int pedidoId;
  final ApiService apiService;

  const OrderTrackingScreen({
    Key? key,
    required this.pedidoId,
    required this.apiService,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Pedido? _pedido;
  Localizacao? _localizacao;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _loadPedidoAndLocalizacao();

    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        _refreshTracking();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPedidoAndLocalizacao() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pedido = await widget.apiService.getPedidoById(widget.pedidoId);
      _pedido = pedido;

      try {
        final localizacao = await widget.apiService.getLocalizacaoPedido(widget.pedidoId);
        _localizacao = localizacao;

        _setupMapView();
      } catch (e) {
        print('Erro ao buscar localização: $e');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erro ao carregar dados do pedido: $e';
      });
    }
  }

  Future<void> _refreshTracking() async {
    if (_pedido == null) return;

    try {
      final localizacao = await widget.apiService.getLocalizacaoPedido(widget.pedidoId);

      setState(() {
        _localizacao = localizacao;
        _setupMapView();
      });
    } catch (e) {
      print('Erro ao atualizar localização: $e');
    }
  }

  void _setupMapView() {
    if (_pedido == null) return;

    _markers = [];

    // Marcador de origem
    _markers.add(
      Marker(
        width: 40,
        height: 40,
        point: LatLng(
          double.parse(_pedido!.origemLatitude),
          double.parse(_pedido!.origemLongitude),
        ),
        child: _buildMarkerIcon(Colors.green, 'O'),
      ),
    );

    // Marcador de destino
    _markers.add(
      Marker(
        width: 40,
        height: 40,
        point: LatLng(
          double.parse(_pedido!.destinoLatitude),
          double.parse(_pedido!.destinoLongitude),
        ),
        child: _buildMarkerIcon(Colors.red, 'D'),
      ),
    );

    if (_localizacao != null) {
      _markers.add(
        Marker(
          width: 50,
          height: 50,
          point: LatLng(_localizacao!.latitude, _localizacao!.longitude),
          child: _buildMarkerIcon(Colors.blue, 'V'),
        ),
      );
    }

    if (_pedido?.rotaMotorista?.rota != null) {
      try {
        final rotaData = _pedido!.rotaMotorista!.rota;
        if (rotaData is Map && rotaData.containsKey('coordinates')) {
          List<dynamic> coordinates = rotaData['coordinates'];
          List<LatLng> points = coordinates
              .map((coord) => LatLng(coord[1], coord[0]))
              .toList();

          _polylines = [
            Polyline(
              points: points,
              strokeWidth: 4.0,
              color: Colors.blue,
            )
          ];
        }
      } catch (e) {
        print('Erro ao processar rota: $e');
      }
    }
  }

  Widget _buildMarkerIcon(Color color, String letter) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _centerMap() {
    if (_pedido == null) return;

    // Definir limites que incluem origem e destino
    final bounds = LatLngBounds(
      LatLng(
        double.parse(_pedido!.origemLatitude),
        double.parse(_pedido!.origemLongitude),
      ),
      LatLng(
        double.parse(_pedido!.destinoLatitude),
        double.parse(_pedido!.destinoLongitude),
      ),
    );

    // Incluir a localização atual nos limites se disponível
    if (_localizacao != null) {
      bounds.extend(LatLng(_localizacao!.latitude, _localizacao!.longitude));
    }

    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rastreamento - Pedido #${widget.pedidoId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTracking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPedidoAndLocalizacao,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(
                  double.parse(_pedido!.origemLatitude),
                  double.parse(_pedido!.origemLongitude),
                ),
                initialZoom: 12,
                onMapReady: () {
                  _centerMap();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 19,
                ),
                MarkerLayer(markers: _markers),
                PolylineLayer(polylines: _polylines),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pedido #${_pedido!.id}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusChip(_pedido!.status),
                    ],
                  ),
                  const Divider(height: 24),
                  Text('Tipo: ${_pedido!.tipoMercadoria}'),
                  const SizedBox(height: 8),
                  Text('Data: ${_pedido!.formattedDate}'),
                  const SizedBox(height: 8),
                  Text(
                    'Distância total: ${_pedido!.distanciaKm.toStringAsFixed(1)} Km',
                  ),
                  if (_localizacao != null) ...[
                    const Divider(height: 24),
                    const Text(
                      'Localização atual',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Distância restante: ${_localizacao!.distanciaDestinoKm.toStringAsFixed(1)} Km',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tempo estimado: ${_localizacao!.tempoEstimadoMinutos} minutos',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atualizado em: ${_formatDateTime(_localizacao!.timestamp)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _pedido != null ? FloatingActionButton(
        onPressed: _centerMap,
        child: const Icon(Icons.center_focus_strong),
      ) : null,
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
