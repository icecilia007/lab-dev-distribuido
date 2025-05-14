package com.logistica.notificacao.service;

import com.logistica.notificacao.model.Notificacao;

public interface PushNotificationService {

    void enviarNotificacaoPush(Notificacao notificacao);
}

