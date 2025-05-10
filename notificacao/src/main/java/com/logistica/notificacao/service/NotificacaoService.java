package com.logistica.notificacao.service;


import com.logistica.notificacao.model.Notificacao;

import java.util.List;

public interface NotificacaoService {

    Notificacao salvar(Notificacao notificacao);

    List<Notificacao> buscarPorDestinatario(Long destinatarioId);

    void marcarComoLida(Long notificacaoId);

    long contarNotificacoesNaoLidas(Long destinatarioId);
}
