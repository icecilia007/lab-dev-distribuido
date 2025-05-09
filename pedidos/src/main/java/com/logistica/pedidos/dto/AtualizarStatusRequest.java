package com.logistica.pedidos.dto;

import com.logistica.pedidos.model.StatusPedido;

public record AtualizarStatusRequest(
        StatusPedido novoStatus
) {}
