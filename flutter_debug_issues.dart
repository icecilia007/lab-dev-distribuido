// PROBLEMAS IDENTIFICADOS NO APP FLUTTER E SUAS CORREÇÕES

// ====================================================================
// PROBLEMA 1: EXTRAÇÃO DO TOKEN NO LOGIN
// ====================================================================

// No arquivo app/lib/services/api_service.dart, método login():

// PROBLEMA: O token está sendo extraído de diferentes headers
// SOLUÇÃO: Tentar todas as variações possíveis

Future<User> login(String email, String password) async {
  try {
    _authToken = null;

    print("Iniciando login para: $email");
    final response = await http.post(
      Uri.parse('$apiGatewayUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'senha': password,
      }),
    );

    print("Resposta do login - Status: ${response.statusCode}");
    
    // IMPRIMIR TODOS OS HEADERS PARA DEBUG
    response.headers.forEach((key, value) {
      print("Header: $key = $value");
    });

    if (response.statusCode == 200) {
      // TENTAR MÚLTIPLAS VARIAÇÕES DO HEADER
      final authHeader = response.headers['authorization'] ??
          response.headers['Authorization'] ??
          response.headers['x-amzn-remapped-authorization'] ??
          response.headers['x-amzn-remapped-Authorization'];

      print("Auth Header encontrado: $authHeader");

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        _authToken = authHeader.substring(7);
        print("Token extraído com sucesso: ${_authToken}");
        
        // VALIDAR O TOKEN LOCALMENTE PARA DEBUG
        _validateTokenLocally(_authToken!);
      } else {
        print("ERRO: Token não encontrado nos headers!");
        print("Headers disponíveis: ${response.headers.keys.toList()}");
        
        // TENTAR EXTRAIR DO BODY (alguns APIs retornam no corpo)
        final responseData = jsonDecode(response.body);
        if (responseData.containsKey('token')) {
          _authToken = responseData['token'];
          print("Token extraído do body: $_authToken");
        }
      }

      final userData = jsonDecode(response.body);
      return User.fromJson(userData);
    } else {
      throw Exception('Falha no login: ${response.body}');
    }
  } catch (e) {
    print("Exceção durante login: $e");
    throw Exception('Erro na requisição: $e');
  }
}

// ADICIONAR FUNÇÃO PARA VALIDAR TOKEN LOCALMENTE
void _validateTokenLocally(String token) {
  try {
    // Decodificar apenas a parte payload (não valida assinatura)
    final parts = token.split('.');
    if (parts.length == 3) {
      final payload = parts[1];
      final padded = payload + '=' * (4 - payload.length % 4);
      final decoded = utf8.decode(base64Decode(padded));
      print("Token payload: $decoded");
    }
  } catch (e) {
    print("Erro ao validar token localmente: $e");
  }
}

// ====================================================================
// PROBLEMA 2: HEADERS DE AUTORIZAÇÃO NAS REQUISIÇÕES
// ====================================================================

// PROBLEMA: Os headers podem não estar sendo enviados corretamente
// SOLUÇÃO: Garantir que o header Authorization seja sempre enviado

Map<String, String> get _authHeaders {
  final headers = {'Content-Type': 'application/json'};

  if (_authToken != null && _authToken!.isNotEmpty) {
    headers['Authorization'] = 'Bearer $_authToken';
    print("Enviando header Authorization: Bearer ${_authToken!.substring(0, 20)}...");
  } else {
    print("AVISO: Token não disponível para requisição!");
  }

  return headers;
}

// ====================================================================
// PROBLEMA 3: WEBSOCKET HEADERS
// ====================================================================

// No arquivo app/lib/services/notification_service.dart:

// PROBLEMA: WebSocket pode não estar enviando headers corretamente
// SOLUÇÃO: Garantir que o token seja enviado na query string E no header

Future<void> connectToWebSocket(String userId, String token) async {
  if (_isConnected) {
    await disconnectWebSocket();
  }
  
  print("Iniciando conexão WebSocket AWS para usuário: $userId");
  print("Token para WebSocket: ${token.substring(0, 20)}...");

  try {
    // ENVIAR TOKEN NA QUERY STRING (principal)
    final wsUrl = '$_awsWebSocketUrl?token=$token&userId=$userId';
    
    print('URL WebSocket: $wsUrl');

    _channel = IOWebSocketChannel.connect(
      Uri.parse(wsUrl),
      headers: {
        // TAMBÉM ENVIAR NO HEADER (backup)
        'Authorization': 'Bearer $token',
        'User-Agent': 'Flutter-App/1.0',
      },
    );

    // REST DO CÓDIGO...
  } catch (e) {
    print('Falha ao conectar ao WebSocket AWS: $e');
  }
}

// ====================================================================
// PROBLEMA 4: TIMING DE REQUISIÇÕES
// ====================================================================

// PROBLEMA: Requisições podem estar sendo feitas antes do token estar disponível
// SOLUÇÃO: Aguardar o token estar pronto

Future<List<Pedido>> getPedidosByCliente(int clienteId, String userType) async {
  // VERIFICAR SE O TOKEN ESTÁ DISPONÍVEL
  if (_authToken == null || _authToken!.isEmpty) {
    print("ERRO: Token não disponível para buscar pedidos!");
    throw Exception('Token de autenticação não disponível. Faça login novamente.');
  }

  print("Buscando pedidos para cliente $clienteId, tipo: $userType");
  print("Usando token: ${_authToken!.substring(0, 20)}...");

  try {
    final response = await http.get(
      Uri.parse('$apiGatewayUrl/api/pedidos/usuario-info/$userType/$clienteId'),
      headers: _authHeaders,
    );

    print("Status da resposta: ${response.statusCode}");
    print("Headers da resposta: ${response.headers}");

    if (response.statusCode == 200) {
      // Código de sucesso...
    } else if (response.statusCode == 401) {
      print("Token expirado ou inválido!");
      throw Exception('Token expirado. Faça login novamente.');
    } else if (response.statusCode == 403) {
      print("Acesso negado - possível problema de autorização");
      print("Body da resposta: ${response.body}");
      throw Exception('Acesso negado. Verifique suas permissões.');
    } else {
      print("Erro inesperado: ${response.statusCode}");
      print("Body: ${response.body}");
      throw Exception('Falha ao buscar pedidos: ${response.statusCode}');
    }
  } catch (e) {
    print('Erro detalhado ao buscar pedidos: $e');
    rethrow;
  }
}

// ====================================================================
// PROBLEMA 5: SINCRONIZAÇÃO DO LOGIN COM WEBSOCKET
// ====================================================================

// PROBLEMA: WebSocket pode estar tentando conectar antes do login completar
// SOLUÇÃO: Aguardar login completo antes de conectar WebSocket

// No seu código principal (onde gerencia o estado de login):

Future<bool> _handleLogin(String email, String password) async {
  try {
    // 1. FAZER LOGIN
    final user = await _apiService.login(email, password);
    
    // 2. VERIFICAR SE O TOKEN FOI EXTRAÍDO
    final token = _apiService.authToken;
    if (token == null || token.isEmpty) {
      print("ERRO: Login bem-sucedido mas token não foi extraído!");
      return false;
    }
    
    print("Login bem-sucedido! Token disponível: ${token.substring(0, 20)}...");
    
    // 3. AGUARDAR UM POUCO ANTES DE CONECTAR WEBSOCKET
    await Future.delayed(Duration(milliseconds: 500));
    
    // 4. CONECTAR WEBSOCKET
    await _notificationService.connectToWebSocket(user.id.toString(), token);
    
    // 5. AGUARDAR UM POUCO ANTES DE FAZER OUTRAS REQUISIÇÕES
    await Future.delayed(Duration(milliseconds: 500));
    
    return true;
  } catch (e) {
    print("Erro no login: $e");
    return false;
  }
}

// ====================================================================
// RESUMO DOS PROBLEMAS MAIS PROVÁVEIS:
// ====================================================================

/*
1. ❌ Token não sendo extraído corretamente do header Authorization
2. ❌ Headers não sendo enviados nas requisições subsequentes  
3. ❌ WebSocket fechando por problema de autenticação
4. ❌ Timing: requisições sendo feitas antes do token estar pronto
5. ❌ Case sensitivity nos headers (Authorization vs authorization)

SOLUÇÕES PRIORITÁRIAS:
1. ✅ Debugar extração do token no login
2. ✅ Garantir que _authHeaders sempre inclua o token
3. ✅ Aguardar o login completar antes de outras operações
4. ✅ Adicionar logs detalhados em todas as operações
*/