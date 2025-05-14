package com.logistica.notificacao.service.impl;

import org.springframework.stereotype.Service;

import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.service.PushNotificationService;
import com.logistica.notificacao.websocket.NotificacaoWebSocketHandler;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class PushNotificationServiceImpl implements PushNotificationService {

    private final NotificacaoWebSocketHandler webSocketHandler;

    public PushNotificationServiceImpl(NotificacaoWebSocketHandler webSocketHandler) {
        this.webSocketHandler = webSocketHandler;
    }

    @Override
    public void enviarNotificacaoPush(Notificacao notificacao) {
        log.info("Enviando notificação push para usuário ID: {}", notificacao.toString());

        webSocketHandler.enviarNotificacao(notificacao.getDestinatarioId(), notificacao);
    }
}
