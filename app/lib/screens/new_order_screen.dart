// lib/screens/new_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class NewOrderScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;

  const NewOrderScreen({
    Key? key,
    required this.apiService,
    required this.authService,
  }) : super(key: key);

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mercadoriaController = TextEditingController();

  // Coordenadas de origem e destino
  LatLng _origem = const LatLng(0, 0);
  LatLng _destino = const LatLng(0, 0);

  bool _isLoading = false;
  bool _origemSelecionada = false;
  bool _destinoSelecionado = false;
  bool _useCurrentLocationAsOrigin = false;

  // Controlador para o mapa
  final MapController _mapController = MapController();
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _mercadoriaController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se os serviços de localização estão habilitados
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviços de localização desabilitados. Por favor, habilite-os.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Verificar permissão de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de localização negada'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização permanentemente negada. Abra as configurações para alterar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Se chegou aqui, temos permissão
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        if (_useCurrentLocationAsOrigin) {
          _origem = LatLng(position.latitude, position.longitude);
          _origemSelecionada = true;
          _updateMarkers();
        }
      });

      // Centralizar mapa na posição atual
      _mapController.move(
          LatLng(position.latitude, position.longitude),
          15
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (!_origemSelecionada) {
        _origem = point;
        _origemSelecionada = true;
      } else if (!_destinoSelecionado) {
        _destino = point;
        _destinoSelecionado = true;
      }
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    _markers = [];

    if (_origemSelecionada) {
      _markers.add(
        Marker(
          width: 40,
          height: 40,
          point: _origem,
          child: _buildMarkerIcon(Colors.green, 'O'),
        ),
      );
    }

    if (_destinoSelecionado) {
      _markers.add(
        Marker(
          width: 40,
          height: 40,
          point: _destino,
          child: _buildMarkerIcon(Colors.red, 'D'),
        ),
      );
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

  void _resetForm() {
    setState(() {
      _origemSelecionada = false;
      _destinoSelecionado = false;
      _mercadoriaController.clear();
      _markers = [];
      _useCurrentLocationAsOrigin = false;
    });
  }

  Future<void> _criarPedido() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_origemSelecionada || !_destinoSelecionado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione os pontos de origem e destino no mapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.apiService.criarPedido(
        _origem.latitude.toString(),
        _origem.longitude.toString(),
        _destino.latitude.toString(),
        _destino.longitude.toString(),
        _mercadoriaController.text,
        widget.authService.currentUser!.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pedido criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Pedido'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(-23.550520, -46.633308), // São Paulo como padrão
                      initialZoom: 12,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                        maxZoom: 19,
                      ),
                      MarkerLayer(markers: _markers),
                      // Adicionar botão de localização
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            'OpenStreetMap contributors',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          !_origemSelecionada
                              ? 'Toque no mapa para selecionar a origem'
                              : !_destinoSelecionado
                              ? 'Toque no mapa para selecionar o destino'
                              : 'Origem e destino selecionados',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_origemSelecionada)
                      CheckboxListTile(
                        title: const Text('Usar minha localização atual como origem'),
                        value: _useCurrentLocationAsOrigin,
                        onChanged: (value) {
                          setState(() {
                            _useCurrentLocationAsOrigin = value ?? false;
                            if (_useCurrentLocationAsOrigin) {
                              _getCurrentLocation();
                            }
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mercadoriaController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Mercadoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, informe o tipo de mercadoria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusInfo(
                            'Origem',
                            _origemSelecionada
                                ? 'Selecionada'
                                : 'Não selecionada',
                            _origemSelecionada
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatusInfo(
                            'Destino',
                            _destinoSelecionado
                                ? 'Selecionado'
                                : 'Não selecionado',
                            _destinoSelecionado
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resetForm,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Limpar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _criarPedido,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Criar Pedido'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(String title, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                status.contains('Não')
                    ? Icons.cancel_outlined
                    : Icons.check_circle_outline,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
                  style: TextStyle(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
