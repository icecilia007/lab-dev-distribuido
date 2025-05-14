package com.logistica.pedidos.dto;

public record PedidoRequest(
        String origemLongitude,
        String origemLatitude,
        String destinoLongitude,
        String destinoLatitude,
        String tipoMercadoria,
        Long clienteId
) {}
