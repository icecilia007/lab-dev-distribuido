// CORREÇÕES RÁPIDAS PARA TESTAR NO APP FLUTTER

// ====================================================================
// 1. CORREÇÃO RÁPIDA NO LOGIN (api_service.dart)
// ====================================================================

// SUBSTITUA o método login() por esta versão com mais debug:

Future<User> login(String email, String password) async {
  try {
    _authToken = null;

    print("=== INICIANDO LOGIN ===");
    print("Email: $email");
    
    final response = await http.post(
      Uri.parse('$apiGatewayUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'senha': password,
      }),
    );

    print("Status: ${response.statusCode}");
    
    // IMPRIMIR TODOS OS HEADERS
    print("=== HEADERS DA RESPOSTA ===");
    response.headers.forEach((key, value) {
      print("$key: $value");
    });

    if (response.statusCode == 200) {
      // TENTAR TODAS AS VARIAÇÕES DO HEADER
      final authHeader = response.headers['authorization'] ??
          response.headers['Authorization'] ??
          response.headers['x-amzn-remapped-authorization'];

      print("Header de auth encontrado: $authHeader");

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        _authToken = authHeader.substring(7);
        print("✅ TOKEN EXTRAÍDO: ${_authToken!.substring(0, 30)}...");
      } else {
        print("❌ ERRO: Token não encontrado!");
        print("Headers disponíveis: ${response.headers.keys.toList()}");
        
        // Tentar no corpo da resposta
        final responseData = jsonDecode(response.body);
        print("Corpo da resposta: $responseData");
      }

      final userData = jsonDecode(response.body);
      print("=== LOGIN CONCLUÍDO ===");
      return User.fromJson(userData);
    } else {
      print("❌ ERRO NO LOGIN: ${response.statusCode}");
      print("Resposta: ${response.body}");
      throw Exception('Falha no login: ${response.body}');
    }
  } catch (e) {
    print("❌ EXCEÇÃO NO LOGIN: $e");
    throw Exception('Erro na requisição: $e');
  }
}

// ====================================================================
// 2. CORREÇÃO NO _authHeaders (api_service.dart)
// ====================================================================

// SUBSTITUA o getter _authHeaders por esta versão:

Map<String, String> get _authHeaders {
  final headers = {'Content-Type': 'application/json'};

  print("=== PREPARANDO HEADERS ===");
  print("Token disponível: ${_authToken != null ? 'SIM' : 'NÃO'}");
  
  if (_authToken != null && _authToken!.isNotEmpty) {
    headers['Authorization'] = 'Bearer $_authToken';
    print("✅ Header Authorization adicionado: Bearer ${_authToken!.substring(0, 20)}...");
  } else {
    print("❌ AVISO: Token não disponível!");
  }

  print("Headers finais: ${headers.keys.toList()}");
  return headers;
}

// ====================================================================
// 3. CORREÇÃO NA BUSCA DE PEDIDOS (api_service.dart)
// ====================================================================

// SUBSTITUA o método getPedidosByCliente por esta versão:

Future<List<Pedido>> getPedidosByCliente(int clienteId, userType) async {
  print("=== BUSCANDO PEDIDOS ===");
  print("Cliente ID: $clienteId");
  print("Tipo de usuário: $userType");
  
  // VERIFICAR TOKEN ANTES DE FAZER REQUISIÇÃO
  if (_authToken == null || _authToken!.isEmpty) {
    print("❌ ERRO: Token não disponível!");
    throw Exception('Token não disponível. Faça login novamente.');
  }
  
  print("✅ Token disponível: ${_authToken!.substring(0, 20)}...");

  try {
    final url = '$apiGatewayUrl/api/pedidos/usuario-info/$userType/$clienteId';
    print("URL da requisição: $url");
    
    final headers = _authHeaders;
    print("Headers da requisição: $headers");

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );

    print("=== RESPOSTA DA API ===");
    print("Status: ${response.statusCode}");
    print("Headers da resposta: ${response.headers}");
    
    if (response.statusCode == 200) {
      print("✅ Sucesso! Processando dados...");
      
      if (response.body.isEmpty) {
        print("Lista vazia retornada");
        return [];
      }

      final List<dynamic> pedidosJson = jsonDecode(response.body);
      print("Encontrados ${pedidosJson.length} pedidos");
      
      return pedidosJson.map((json) => Pedido.fromJson(json)).toList();
      
    } else if (response.statusCode == 401) {
      print("❌ Token expirado ou inválido");
      print("Resposta: ${response.body}");
      throw Exception('Token expirado. Faça login novamente.');
    } else if (response.statusCode == 403) {
      print("❌ Acesso negado");
      print("Resposta: ${response.body}");
      throw Exception('Acesso negado. Verifique suas permissões.');
    } else {
      print("❌ Erro: ${response.statusCode}");
      print("Resposta: ${response.body}");
      throw Exception('Falha ao buscar pedidos: ${response.statusCode}');
    }
  } catch (e) {
    print("❌ EXCEÇÃO: $e");
    rethrow;
  }
}

// ====================================================================
// 4. CORREÇÃO NO WEBSOCKET (notification_service.dart)
// ====================================================================

// SUBSTITUA o método connectToWebSocket por esta versão:

Future<void> connectToWebSocket(String userId, String token) async {
  if (_isConnected) {
    await disconnectWebSocket();
  }
  
  print("=== CONECTANDO WEBSOCKET ===");
  print("Usuário ID: $userId");
  print("Token: ${token.substring(0, 30)}...");

  try {
    // URL com token na query string
    final wsUrl = '$_awsWebSocketUrl?token=$token&userId=$userId';
    print("URL WebSocket: $wsUrl");

    _channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'User-Agent': 'Flutter-App',
      },
    );

    _isConnected = true;

    _channel!.stream.listen(
      (message) {
        print("✅ Mensagem WebSocket recebida: $message");
        _handleIncomingMessage(message);
      },
      onError: (error) {
        print("❌ Erro WebSocket: $error");
        _isConnected = false;
        // Não reconectar automaticamente para debug
        // _scheduleReconnection(userId, token);
      },
      onDone: () {
        print("⚠️ WebSocket desconectado");
        _isConnected = false;
        // Não reconectar automaticamente para debug
        // _scheduleReconnection(userId, token);
      }
    );

    print("✅ WebSocket conectado com sucesso!");
  } catch (e) {
    print("❌ Erro ao conectar WebSocket: $e");
    _isConnected = false;
  }
}

// ====================================================================
// 5. SEQUÊNCIA DE LOGIN CORRETA
// ====================================================================

// No seu código principal, use esta sequência:

Future<void> _handleLoginSequence(String email, String password) async {
  try {
    print("=== INICIANDO SEQUÊNCIA DE LOGIN ===");
    
    // 1. Fazer login
    final user = await _apiService.login(email, password);
    print("✅ Login bem-sucedido!");
    
    // 2. Verificar se token foi extraído
    final token = _apiService.authToken;
    if (token == null || token.isEmpty) {
      print("❌ Token não foi extraído!");
      return;
    }
    
    print("✅ Token disponível");
    
    // 3. Aguardar um pouco
    await Future.delayed(Duration(milliseconds: 1000));
    
    // 4. Conectar WebSocket
    print("Conectando WebSocket...");
    await _notificationService.connectToWebSocket(user.id.toString(), token);
    
    // 5. Aguardar mais um pouco
    await Future.delayed(Duration(milliseconds: 1000));
    
    // 6. Buscar dados
    print("Buscando pedidos...");
    final pedidos = await _apiService.getPedidosByCliente(user.id, user.tipo.toLowerCase());
    print("✅ Pedidos carregados: ${pedidos.length}");
    
    print("=== LOGIN SEQUENCE COMPLETA ===");
    
  } catch (e) {
    print("❌ Erro na sequência de login: $e");
  }
}

// ====================================================================
// TESTE ESTAS CORREÇÕES:
// ====================================================================

/*
1. Substitua o método login() 
2. Substitua o getter _authHeaders
3. Substitua o método getPedidosByCliente
4. Substitua o método connectToWebSocket
5. Use a sequência de login correta

Isso deve resolver os problemas de:
- Token não sendo extraído
- Headers não sendo enviados
- WebSocket fechando
- Erro 403 nas APIs

Execute e veja os logs detalhados para identificar onde está o problema exato!
*/