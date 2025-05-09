package com.logistica.rastreamento.service;

import com.logistica.rastreamento.dto.IncidenteRequest;
import com.logistica.rastreamento.dto.IncidenteResponse;

import java.util.List;

public interface IncidenteService {
    IncidenteResponse reportarIncidente(IncidenteRequest request);

    List<IncidenteResponse> listarIncidentesAtivos();

    List<IncidenteResponse> buscarIncidentesProximos(Double latitude, Double longitude, Double raioKm);

    IncidenteResponse buscarIncidentePorId(Long id);

    void desativarIncidente(Long id);
}
