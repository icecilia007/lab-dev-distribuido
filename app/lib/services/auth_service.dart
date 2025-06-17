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
      if (user.phone != null) {
        await prefs.setString('userPhone', user.phone!);
      }

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
    await prefs.remove('userPhone');
    await prefs.remove('authToken');

    _apiService.authToken = null;
    print("Token após logout: ${_apiService.authToken}");
  }

  Future<Map<String, dynamic>> \autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final authToken = prefs.getString('authToken');
    final userType = prefs.getString('userType');

    if (userId == null || authToken == null) {
      return {'success': false, 'userType': null};
    }

    _currentUser = User(
      id: userId,
      name: prefs.getString('userName') ?? '',
      email: prefs.getString('userEmail') ?? '',
      type: userType ?? '',
      phone: prefs.getString('userPhone'),
    );

    _apiService.authToken = authToken;
    return {'success': true, 'userType': userType};
  }

  bool get isAuthenticated => _currentUser != null && _apiService.authToken != null;
}
