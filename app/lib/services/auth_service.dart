import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  User? _currentUser;

  AuthService(this._apiService);

  ApiService get apiService => _apiService;
  User? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    try {
      final user = await _apiService.login(email, password);
      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id);
      await prefs.setString('userName', user.name);
      await prefs.setString('userEmail', user.email);
      await prefs.setString('userType', user.type);

      // Salvar o token de autenticação
      if (_apiService.authToken != null) {
        await prefs.setString('authToken', _apiService.authToken!);
      }

      return true;
    } catch (e) {
      print('Erro de login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    print("Realizando logout e limpando token: ${_apiService.authToken}");
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userType');
    await prefs.remove('authToken');

    _apiService.authToken = null;
    print("Token após logout: ${_apiService.authToken}");
  }

  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final authToken = prefs.getString('authToken');

    if (userId == null || authToken == null) {
      return false;
    }

    _currentUser = User(
      id: userId,
      name: prefs.getString('userName') ?? '',
      email: prefs.getString('userEmail') ?? '',
      type: prefs.getString('userType') ?? '',
    );

    _apiService.authToken = authToken;

    return true;
  }

  bool get isAuthenticated => _currentUser != null && _apiService.authToken != null;
}
