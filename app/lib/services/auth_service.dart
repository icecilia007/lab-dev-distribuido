import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService;
  User? _currentUser;

  AuthService(this._apiService);

  User? get currentUser => _currentUser;

  Future<bool> login(String email, String password) async {
    try {
      final user = await _apiService.login(email, password);
      _currentUser = user;

      // Salvar dados do usuário no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userId', user.id);
      await prefs.setString('userName', user.name);
      await prefs.setString('userEmail', user.email);
      await prefs.setString('userType', user.type);

      return true;
    } catch (e) {
      print('Erro de login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;

    // Limpar dados do usuário do SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('user');
  }

  Future<bool> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      return false;
    }

    // Reconstruir usuário a partir do SharedPreferences
    _currentUser = User(
      id: userId,
      name: prefs.getString('userName') ?? '',
      email: prefs.getString('userEmail') ?? '',
      type: prefs.getString('userType') ?? '',
    );

    return true;
  }

  bool get isAuthenticated => _currentUser != null;
}
