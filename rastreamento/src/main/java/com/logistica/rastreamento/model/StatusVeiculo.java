package com.logistica.rastreamento.model;

public enum StatusVeiculo {
    DISPONIVEL,    // Quando não está atendendo pedido ou após finalizar entrega
    PARADO,        // Quando o veículo está parado durante um trajeto
    EM_MOVIMENTO   // Quando o veículo está em movimento atendendo um pedido
}
