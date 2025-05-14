package com.logistica.rastreamento.dto;

import com.logistica.rastreamento.model.TipoIncidente;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class IncidenteRequest {
    private Long motoristaId;
    private Double longitude;
    private Double latitude;
    private TipoIncidente tipo;
    private Double raioImpactoKm;
    // Duração em horas (após esse período, o incidente expira)
    private Integer duracaoHoras;
}

