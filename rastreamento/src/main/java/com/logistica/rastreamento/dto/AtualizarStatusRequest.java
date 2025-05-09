package com.logistica.rastreamento.dto;

import com.logistica.rastreamento.model.StatusPedido;

public record AtualizarStatusRequest(
        StatusPedido novoStatus
) {
}
