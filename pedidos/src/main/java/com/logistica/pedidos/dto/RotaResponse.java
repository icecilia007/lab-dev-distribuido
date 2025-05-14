package com.logistica.pedidos.dto;

public record RotaResponse(
        Double distanciaKm,
        Integer tempoEstimadoMinutos,
        Object rota
) {}
