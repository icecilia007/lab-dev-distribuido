package com.logistica.pedidos.dto;

import lombok.Data;

import java.time.LocalDateTime;
@Data
public class MotoristaProximoDTO {
    private Long motoristaId;
    private Double latitude;
    private Double longitude;
    private Double distanciaKm;
    private LocalDateTime ultimaAtualizacao;
}

