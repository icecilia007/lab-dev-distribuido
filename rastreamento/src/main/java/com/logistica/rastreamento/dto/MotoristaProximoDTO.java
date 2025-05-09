package com.logistica.rastreamento.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class MotoristaProximoDTO {
    private Long motoristaId;
    private Double longitude;
    private Double latitude;
    private Double distanciaKm;
    private LocalDateTime ultimaAtualizacao;
}

