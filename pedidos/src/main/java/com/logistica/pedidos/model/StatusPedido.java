package com.logistica.pedidos.model;

public enum StatusPedido {
    CRIADO,              // Pedido acabou de ser registrado
    EM_PROCESSAMENTO,
    AGUARDANDO_COLETA,   // Usado quando motorista é atribuído
    EM_ROTA,             // Não está sendo atualizado automaticamente
    ENTREGUE,            // Atualizado apenas manualmente
    CANCELADO            // Usado apenas em cancelamento explícito
}