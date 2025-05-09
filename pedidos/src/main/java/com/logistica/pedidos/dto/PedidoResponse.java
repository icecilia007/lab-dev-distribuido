package com.logistica.pedidos.dto;

import com.logistica.pedidos.model.StatusPedido;

import java.time.LocalDateTime;

public record PedidoResponse(
        Long id,
        String origemLongitude,
        String origemLatitude,
        String destinoLongitude,
        String destinoLatitude,
        String tipoMercadoria,
        StatusPedido status,
        LocalDateTime dataCriacao,
        LocalDateTime dataAtualizacao,
        LocalDateTime dataEntregaEstimada,
        Double distanciaKm,
        Integer tempoEstimadoMinutos,
        Long clienteId,
        Long motoristaId,
        RotaResponse rotaMotorista
) {}
