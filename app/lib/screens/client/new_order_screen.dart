import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

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
  final _cupomController = TextEditingController();

  LatLng _origem = const LatLng(0, 0);
  LatLng _destino = const LatLng(0, 0);
  bool _isLoading = false;
  bool _origemSelecionada = false;
  bool _destinoSelecionado = false;
  bool _useCurrentLocationAsOrigin = false;
  bool _cupomValidado = false;
  bool _validandoCupom = false;

  double _descontoCupom = 0.0;
  String _mensagemCupom = '';
  String _codigoCupomValidado = '';

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
    _cupomController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviços de localização desabilitados. Por favor, habilite-os.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de localização permanentemente negada. Abra as configurações para alterar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      if (!mounted) return;

      setState(() {
        if (_useCurrentLocationAsOrigin) {
          _origem = LatLng(position.latitude, position.longitude);
          _origemSelecionada = true;
          _updateMarkers();
        }
      });

      _mapController.move(
          LatLng(position.latitude, position.longitude),
          15
      );
    } catch (e) {
      if (mounted) {
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

  Future<void> _validarCupom() async {
    if (_cupomController.text.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _mensagemCupom = 'Digite um código de cupom';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _validandoCupom = true;
        _mensagemCupom = '';
      });
    }

    try {
      final resultado = await widget.apiService.validarCupom(_cupomController.text.trim());

      if (!mounted) return;

      if (resultado != null) {
        if (resultado.containsKey('error')) {
          setState(() {
            _cupomValidado = false;
            _descontoCupom = 0.0;
            _codigoCupomValidado = '';
            _mensagemCupom = resultado['error'];
          });
        } else {
          final desconto = resultado['desconto'] as double;
          final status = resultado['status'] as String;
          final usosRestantes = resultado['usos_restantes'] as int;

          // MODIFICAÇÃO: Adicionar verificação para desconto == 0.0
          if (status == 'indisponivel' || usosRestantes == 0 || desconto == 0.0) {
            setState(() {
              _cupomValidado = false;
              _descontoCupom = 0.0;
              _codigoCupomValidado = '';
              _mensagemCupom = 'Cupom indisponível';
            });
          } else {
            final percentualDesconto = (desconto * 100).toInt();
            setState(() {
              _cupomValidado = true;
              _descontoCupom = desconto;
              _codigoCupomValidado = _cupomController.text.trim();
              _mensagemCupom = 'Você ganhou cupom de $percentualDesconto%';
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cupomValidado = false;
          _descontoCupom = 0.0;
          _codigoCupomValidado = '';
          _mensagemCupom = 'Erro ao validar cupom';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _validandoCupom = false;
        });
      }
    }
  }


  void _limparCupom() {
    setState(() {
      _cupomController.clear();
      _cupomValidado = false;
      _descontoCupom = 0.0;
      _codigoCupomValidado = '';
      _mensagemCupom = '';
    });
  }

  void _resetForm() {
    setState(() {
      _origemSelecionada = false;
      _destinoSelecionado = false;
      _mercadoriaController.clear();
      _cupomController.clear();
      _cupomValidado = false;
      _descontoCupom = 0.0;
      _codigoCupomValidado = '';
      _mensagemCupom = '';
      _markers = [];
      _useCurrentLocationAsOrigin = false;
    });
  }

  Future<void> _criarPedido() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_origemSelecionada || !_destinoSelecionado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecione os pontos de origem e destino no mapa'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await widget.apiService.criarPedido(
        _origem.latitude.toString(),
        _origem.longitude.toString(),
        _destino.latitude.toString(),
        _destino.longitude.toString(),
        _mercadoriaController.text,
        widget.authService.currentUser!.id,
      );

      if (!mounted) return;

      String mensagemSucesso = 'Pedido criado com sucesso!';
      if (_cupomValidado) {
        final percentualDesconto = (_descontoCupom * 100).toInt();
        mensagemSucesso += ' Desconto de $percentualDesconto% será aplicado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagemSucesso),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                      initialCenter: const LatLng(-23.550520, -46.633308),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cupomController,
                            decoration: InputDecoration(
                              labelText: 'Código do Cupom (opcional)',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.local_offer),
                              suffixIcon: _cupomController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _limparCupom,
                              )
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (value) {
                              setState(() {});
                              if (_cupomValidado && value != _codigoCupomValidado) {
                                _limparCupom();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _validandoCupom ? null : _validarCupom,
                          child: _validandoCupom
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text('Validar'),
                        ),
                      ],
                    ),
                    if (_mensagemCupom.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _cupomValidado ? Colors.green.shade50 : Colors.red.shade50,
                          border: Border.all(
                            color: _cupomValidado ? Colors.green : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _cupomValidado ? Icons.check_circle : Icons.error,
                              color: _cupomValidado ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _mensagemCupom,
                                style: TextStyle(
                                  color: _cupomValidado ? Colors.green.shade700 : Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
