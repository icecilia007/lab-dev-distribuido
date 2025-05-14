package com.logistica.rastreamento.service;

import com.logistica.rastreamento.dto.AtualizacaoLocalizacaoDTO;
import com.logistica.rastreamento.dto.LocalizacaoDTO;
import com.logistica.rastreamento.dto.MotoristaProximoDTO;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public interface RastreamentoService {
    boolean atualizarLocalizacao(AtualizacaoLocalizacaoDTO dto);

    List<MotoristaProximoDTO> buscarMotoristasProximos(Double latitude, Double longitude, Double raioKm);

    boolean confirmarColetaPedido(Long pedidoId, Long motoristaId);

    boolean confirmarEntregaPedido(Long pedidoId, Long motoristaId);

    LocalizacaoDTO consultarLocalizacaoAtual(Long pedidoId);

    List<LocalizacaoDTO> buscarEntregasProximas(Double latitude, Double longitude, Double raioKm);

    void registrarObservador(Long pedidoId, LocalizacaoObserver observer);

    void removerObservador(Long pedidoId, LocalizacaoObserver observer);

    List<LocalizacaoDTO> buscarHistoricoLocalizacoes(Long pedidoId);

    Map<String, Object> calcularEstatisticasMotorista(Long motoristaId, LocalDate dataInicio, LocalDate dataFim);
}
