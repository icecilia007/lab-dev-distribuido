package com.logistica.rastreamento.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class LocalizacaoDTO {
    private Long id;
    private Long pedidoId;
    private Long motoristaId;
    private Double longitude;
    private Double latitude;
    private LocalDateTime timestamp;
    private String statusVeiculo;
    private Double distanciaDestinoKm;
    private Integer tempoEstimadoMinutos;
}
