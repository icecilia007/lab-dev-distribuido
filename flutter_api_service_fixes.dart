// ARQUIVO: app/lib/services/api_service.dart
//
// ALTERAÇÕES ESPECÍFICAS para corrigir problemas identificados

// ========================================
// 1. SUBSTITUIR O MÉTODO getPedidosByCliente
// ========================================

// REMOVER esta versão atual:
/*
Future<List<Pedido>> getPedidosByCliente(int clienteId, userType) async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult != ConnectivityResult.none;

    if (isConnected) {
      // ... código da API ...
    } else {
      print('Dispositivo offline. Buscando pedidos do banco local...');
      return await _databaseService.getPedidosByCliente(clienteId);
    }
}
*/

// SUBSTITUIR POR esta versão:
Future<List<Pedido>> getPedidosByCliente(int clienteId, userType) async {
  try {
    final response = await http.get(
      Uri.parse('$apiGatewayUrl/api/pedidos/usuario-info/$userType/$clienteId'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      print('Response headers: ${response.headers}');
      print('Response content type: ${response.headers['content-type']}');

      if (response.body.isEmpty) {
        print('API retornou uma lista vazia para pedidos');
        return [];
      }

      try {
        // Adicione log para ver o início do body
        print('Primeiros 100 caracteres: ${response.body.substring(0, min(100, response.body.length))}');

        List<dynamic> pedidosJson = jsonDecode(response.body);
        print('JSON decodificado com sucesso. Encontrados ${pedidosJson.length} pedidos');
        List<Pedido> pedidos = pedidosJson.map((json) => Pedido.fromJson(json)).toList();

        return pedidos;
      } catch (e) {
        print('Erro ao decodificar JSON: $e');
        throw Exception('Erro ao processar resposta: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token expirado. Faça login novamente.');
    } else if (response.statusCode == 403) {
      throw Exception('Acesso negado. Verifique suas permissões.');
    } else {
      throw Exception('Falha ao buscar pedidos: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Erro ao buscar da API: $e');
    rethrow; // Propaga o erro sem tentar banco local
  }
}

// ========================================
// 2. ATUALIZAR O MÉTODO buscarNotificacoes
// ========================================

// SUBSTITUIR o método atual por:
Future<List<Notificacao>> buscarNotificacoes(int userId) async {
  try {
    final response = await http.get(
      Uri.parse('$apiGatewayUrl/api/notificacoes/destinatario/$userId'),
      headers: _authHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Notificacao.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      print('Token expirado para notificações');
      throw Exception('Token expirado. Faça login novamente.');
    } else if (response.statusCode == 403) {
      print('Acesso negado para notificações');
      throw Exception('Acesso negado às notificações.');
    } else {
      print('Erro ao buscar notificações: ${response.statusCode} - ${response.body}');
      return [];
    }
  } catch (e) {
    print('Exceção ao buscar notificações: $e');
    return [];
  }
}

// ========================================
// 3. REMOVER REFERÊNCIAS AO DATABASE_SERVICE
// ========================================

// REMOVER estas linhas do topo do arquivo:
// import 'database_service.dart';
// final DatabaseService _databaseService = DatabaseService();

// REMOVER estas linhas do método getPedidosByCliente:
// for (var pedido in pedidos) {
//   if (pedido.status == 'ENTREGUE') {
//     await _databaseService.insertPedido(pedido);
//   }
// }

// E também remover:
// } catch (e) {
//   print('Erro ao buscar da API: $e. Tentando buscar do banco local...');
//   return await _databaseService.getPedidosByCliente(clienteId);
// }

// ========================================
// 4. MELHORAR TRATAMENTO DE HEADERS DE AUTENTICAÇÃO
// ========================================

// O método login está correto, mas para garantir que o token seja extraído corretamente,
// você pode adicionar logs extras:

Future<User> login(String email, String password) async {
  try {
    _authToken = null;

    print("Iniciando login para: $email");
    final baseUrl = apiGatewayUrl ?? 'https://aq72n5uzcb.execute-api.us-east-1.amazonaws.com/prod';
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'senha': password,
      }),
    );

    print("Resposta do login - Status: ${response.statusCode}");
    print("Headers: ${response.headers}");

    if (response.statusCode == 200) {
      // Tentar múltiplas variações do header
      final authHeader = response.headers['x-amzn-remapped-authorization'] ??
          response.headers['Authorization'] ??
          response.headers['authorization'];

      print("Auth Header encontrado: $authHeader");

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        _authToken = authHeader.substring(7);
        print("Token extraído com sucesso: ${_authToken!.substring(0, 20)}...");
      } else {
        print("ERRO: Token não encontrado nos headers!");
        print("Headers disponíveis: ${response.headers.keys.toList()}");
      }

      final userData = jsonDecode(response.body);
      print("Dados do usuário: $userData");
      return User.fromJson(userData);
    } else {
      throw Exception('Falha no login: ${response.body}');
    }
  } catch (e) {
    print("Exceção durante login: $e");
    throw Exception('Erro na requisição: $e');
  }
}

// ========================================
// RESUMO DAS MUDANÇAS NECESSÁRIAS:
// ========================================

/*
1. ✅ Remover import 'database_service.dart'
2. ✅ Remover final DatabaseService _databaseService = DatabaseService()
3. ✅ Substituir método getPedidosByCliente (remover conectividade + banco local)
4. ✅ Atualizar método buscarNotificacoes (melhor tratamento de erros)
5. ✅ Remover todas as referências a _databaseService
6. ✅ Adicionar logs extras no login para debug
7. ✅ Fazer todas as funções propagarem erros ao invés de usar fallback local
*/