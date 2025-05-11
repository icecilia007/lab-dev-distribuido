// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_order_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar serviços com a URL do API Gateway
  final apiService = ApiService(
    apiGatewayUrl: 'http://10.0.2.2:8000',
  );

  final authService = AuthService(apiService);
  final notificationService = NotificationService();

  await notificationService.init();

  runApp(LogisticaApp(
    apiService: apiService,
    authService: authService,
    notificationService: notificationService,
  ));
}

class LogisticaApp extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  final NotificationService notificationService;

  const LogisticaApp({
    Key? key,
    required this.apiService,
    required this.authService,
    required this.notificationService,
  }) : super(key: key);

  @override
  State<LogisticaApp> createState() => _LogisticaAppState();
}

class _LogisticaAppState extends State<LogisticaApp> {
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Tentar auto-login
    final success = await widget.authService.autoLogin();

    setState(() {
      _isLoggedIn = success;
      _isInitialized = true;
    });
  }

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
    // // Adicione esta linha para navegação explícita
    // Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    print("Building LogisticaApp - isLoggedIn: $_isLoggedIn");
    return MaterialApp(
      title: 'Logística App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      routes: {
        '/login': (context) => LoginScreen(
          authService: widget.authService,
          onLoginSuccess: _handleLoginSuccess,
        ),
        '/home': (context) => HomeScreen(
          authService: widget.authService,
          apiService: widget.apiService,
        ),
        '/novo-pedido': (context) => NewOrderScreen(
          apiService: widget.apiService,
          authService: widget.authService,
        ),
      },
      home: !_isInitialized
          ? const SplashScreen()
          : !_isLoggedIn
          ? LoginScreen(
        authService: widget.authService,
        onLoginSuccess: _handleLoginSuccess,
      )
          : HomeScreen(
        authService: widget.authService,
        apiService: widget.apiService,
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.local_shipping,
              size: 80,
              color: Colors.blue,
            ),
            SizedBox(height: 16),
            Text(
              'Logística App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
