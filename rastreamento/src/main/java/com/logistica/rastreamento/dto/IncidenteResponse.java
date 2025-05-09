package com.logistica.rastreamento.dto;


import com.logistica.rastreamento.model.TipoIncidente;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class IncidenteResponse {
    private Long id;
    private Long motoristaId;
    private Double longitude;
    private Double latitude;
    private TipoIncidente tipo;
    private LocalDateTime dataReporte;
    private LocalDateTime dataExpiracao;
    private Boolean ativo;
    private Double raioImpactoKm;
}