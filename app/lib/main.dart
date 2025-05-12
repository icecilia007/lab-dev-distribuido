// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:app/models/notificacao.dart';
import 'package:app/services/notification_manager.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/new_order_screen.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/driver_home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService( apiGatewayUrl: 'http://10.0.2.2:8000',);
  final authService = AuthService(apiService);
  final notificationService = NotificationService();
  final notificationManager = NotificationManager(apiService);

  await notificationService.init();

  notificationService.setNotificationCallback((notification) {
    print('Notificação recebida e processada: $notification');
    try {
      if (notification['id'] != null) {
        final notificacao = Notificacao.fromJson(notification);
        notificationManager.adicionarNotificacao(notificacao);
      }
    } catch (e) {
      print('Erro ao processar notificação: $e');
    }
  });


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => notificationManager),
        Provider(create: (_) => notificationService),
        Provider(create: (_) => authService),
        Provider(create: (_) => apiService),
      ],
      child: LogisticaApp(
        apiService: apiService,
        authService: authService,
        notificationService: notificationService,
      ),
    ),
  );
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
  String? _userType;

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final result = await widget.authService.autoLogin();
    final success = result['success'];
    final userType = result['userType'];

    setState(() {
      _isLoggedIn = success;
      _isInitialized = true;
      _userType = userType;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isLoggedIn && widget.authService.currentUser != null) {
      _connectToWebSocket();
    }
  }

  Future<void> _connectToWebSocket() async {
    final user = widget.authService.currentUser;
    if (user != null && widget.authService.apiService.authToken != null) {
      await widget.notificationService.connectToWebSocket(
          user.id.toString(),
          widget.authService.apiService.authToken!
      );

      final notificationManager = Provider.of<NotificationManager>(context, listen: false);
      await notificationManager.carregarNotificacoes(user.id);
    }
  }

  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
    _connectToWebSocket();

    final userType = widget.authService.currentUser?.type;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userType == 'MOTORISTA') {
        navigatorKey.currentState?.pushReplacementNamed('/motorista');
      } else if (userType == 'CLIENTE') {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      } else {
        navigatorKey.currentState?.pushReplacementNamed('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building LogisticaApp - isLoggedIn: $_isLoggedIn");
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Logística',
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
        '/motorista': (context) => DriverHomeScreen(
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
          : _userType == 'MOTORISTA'
          ? DriverHomeScreen(
        authService: widget.authService,
        apiService: widget.apiService,
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
              'Logística',
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
