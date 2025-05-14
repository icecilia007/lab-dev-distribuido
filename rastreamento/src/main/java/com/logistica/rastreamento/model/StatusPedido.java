package com.logistica.rastreamento.model;

public enum StatusPedido {
    AGUARDANDO_COLETA,   // Usado quando motorista é atribuído
    EM_ROTA,             // Não está sendo atualizado automaticamente
    ENTREGUE,            // Atualizado apenas manualmente
    CANCELADO            // Usado apenas em cancelamento explícito
}
