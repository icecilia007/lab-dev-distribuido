package com.logistica.rastreamento.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class PedidoDTO {
    private Long id;
    private Double origemLongitude;
    private Double origemLatitude;
    private Double destinoLongitude;
    private Double destinoLatitude;
    private Long motoristaId;
    private String status;
    private Integer tempoEstimadoMinutos;
    private Double distanciaKm;
}
