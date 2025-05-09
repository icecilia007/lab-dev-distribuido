package com.logistica.rastreamento.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class AtualizacaoLocalizacaoDTO {
    private Long pedidoId;
    private Long motoristaId;
    private Double latitude;
    private Double longitude;
    private String statusVeiculo;
}
