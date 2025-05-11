import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({
    Key? key,
    required this.apiService,
    required this.onRegisterSuccess,
  }) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();
  final _telefoneController = TextEditingController();

  final _placaController = TextEditingController();
  final _modeloVeiculoController = TextEditingController();
  final _anoVeiculoController = TextEditingController();
  final _consumoMedioController = TextEditingController();

  String _tipoUsuarioSelecionado = 'cliente';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmSenhaController.dispose();
    _telefoneController.dispose();
    _placaController.dispose();
    _modeloVeiculoController.dispose();
    _anoVeiculoController.dispose();
    _consumoMedioController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> userData = {
        'nome': _nomeController.text,
        'email': _emailController.text,
        'senha': _senhaController.text,
        'tipo': _tipoUsuarioSelecionado,
        'telefone': _telefoneController.text,
      };

      if (_tipoUsuarioSelecionado == 'motorista') {
        userData['placa'] = _placaController.text;
        userData['modeloVeiculo'] = _modeloVeiculoController.text;
        userData['anoVeiculo'] = int.tryParse(_anoVeiculoController.text) ?? 0;
        userData['consumoMedioPorKm'] = double.tryParse(_consumoMedioController.text) ?? 0.0;
        userData['status'] = 'DISPONIVEL'; // Status padrão
      }

      String endpoint;
      switch (_tipoUsuarioSelecionado) {
        case 'cliente':
          endpoint = '${widget.apiService.apiGatewayUrl}/api/usuarios/clientes';
          break;
        case 'motorista':
          endpoint = '${widget.apiService.apiGatewayUrl}/api/usuarios/motoristas';
          break;
        case 'operador':
          endpoint = '${widget.apiService.apiGatewayUrl}/api/usuarios/operadores';
          break;
        default:
          throw Exception('Tipo de usuário inválido');
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro realizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRegisterSuccess();
      } else {
        setState(() {
          _errorMessage = 'Falha ao registrar: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao registrar: $e';
      });
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
        title: const Text('Cadastro de Usuário'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const Text(
                  'Tipo de Usuário',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('Cliente'),
                  value: 'cliente',
                  groupValue: _tipoUsuarioSelecionado,
                  onChanged: (value) {
                    setState(() {
                      _tipoUsuarioSelecionado = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Motorista'),
                  value: 'motorista',
                  groupValue: _tipoUsuarioSelecionado,
                  onChanged: (value) {
                    setState(() {
                      _tipoUsuarioSelecionado = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text('Operador Logístico'),
                  value: 'operador',
                  groupValue: _tipoUsuarioSelecionado,
                  onChanged: (value) {
                    setState(() {
                      _tipoUsuarioSelecionado = value!;
                    });
                  },
                ),
                const Divider(height: 32),

                const Text(
                  'Dados Pessoais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu número de telefone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmSenhaController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Senha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme sua senha';
                    }
                    if (value != _senhaController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),

                if (_tipoUsuarioSelecionado == 'motorista') ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Dados do Veículo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _placaController,
                    decoration: const InputDecoration(
                      labelText: 'Placa do Veículo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a placa do veículo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _modeloVeiculoController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo do Veículo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o modelo do veículo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _anoVeiculoController,
                    decoration: const InputDecoration(
                      labelText: 'Ano do Veículo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o ano do veículo';
                      }
                      final year = int.tryParse(value);
                      if (year == null || year < 1900 || year > 2030) {
                        return 'Por favor, insira um ano válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _consumoMedioController,
                    decoration: const InputDecoration(
                      labelText: 'Consumo Médio (Km/L)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_gas_station),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o consumo médio';
                      }
                      final consumption = double.tryParse(value);
                      if (consumption == null || consumption <= 0) {
                        return 'Por favor, insira um valor válido';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CADASTRAR'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}