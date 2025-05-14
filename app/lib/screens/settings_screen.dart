
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final AuthService authService;
  final ApiService apiService;

  const SettingsScreen({
    Key? key,
    required this.onLogout,
    required this.authService,
    required this.apiService,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _pushNotificationsEnabled = false;
  bool _emailNotificationsEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

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

    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      if (widget.authService.currentUser == null) {
        _pushNotificationsEnabled = prefs.getBool('pushNotifications') ?? false;
        _emailNotificationsEnabled = prefs.getBool('emailNotifications') ?? false;
      }
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
          _buildSectionTitle('Sobre o App'),
          const ListTile(
            title: Text('Versão'),
            trailing: Text('1.0.0'),
          ),
          ListTile(
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () {
            },
          ),
          ListTile(
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () {
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onLogout,
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