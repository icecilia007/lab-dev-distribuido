package com.logistica.rastreamento.service;

import com.logistica.rastreamento.dto.LocalizacaoDTO;

/**
 * Interface para observadores de localização
 * Implementa o padrão Observer para notificações em tempo real
 */
public interface LocalizacaoObserver {
    void onNovaLocalizacao(LocalizacaoDTO localizacao);
}