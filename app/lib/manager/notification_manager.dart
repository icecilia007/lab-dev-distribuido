import 'package:flutter/foundation.dart';
import 'package:app/models/notificacao.dart';
import '../services/api_service.dart';

class NotificationManager extends ChangeNotifier {
  final ApiService _apiService;
  final List<Notificacao> _notificacoes = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  NotificationManager(this._apiService);

  List<Notificacao> get notificacoes => _notificacoes;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  // Carregar notificações do servidor
  Future<void> carregarNotificacoes(int userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final listaNotificacoes = await _apiService.buscarNotificacoes(userId);
      _notificacoes.clear();
      _notificacoes.addAll(listaNotificacoes);
      _calcularNaoLidas();
    } catch (e) {
      print('Erro ao carregar notificações: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void adicionarNotificacao(Notificacao notificacao) {
    // Verificar se já existe
    final index = _notificacoes.indexWhere((n) => n.id == notificacao.id);
    if (index >= 0) {
      _notificacoes[index] = notificacao;
    } else {
      _notificacoes.add(notificacao);
    }
    _calcularNaoLidas();
    notifyListeners();
  }

  Future<void> marcarComoLida(Notificacao notificacao) async {
    final index = _notificacoes.indexWhere((n) => n.id == notificacao.id);
    if (index >= 0) {
      _notificacoes[index].lida = true;
      notifyListeners();

      await _apiService.marcarNotificacaoComoLida(notificacao.id);
      _calcularNaoLidas();
    }
  }

  void _calcularNaoLidas() {
    _unreadCount = _notificacoes.where((n) => !n.lida).length;
    notifyListeners();
  }
}
