package com.logistica.rastreamento.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class EntregaProximaDTO {
    private Long pedidoId;
    private Double latitude;
    private Double longitude;
    private Double distanciaKm;
}
