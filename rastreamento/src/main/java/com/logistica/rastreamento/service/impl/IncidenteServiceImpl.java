package com.logistica.rastreamento.service.impl;

import com.logistica.rastreamento.dto.IncidenteRequest;
import com.logistica.rastreamento.dto.IncidenteResponse;
import com.logistica.rastreamento.dto.LocalizacaoDTO;
import com.logistica.rastreamento.exception.RecursoNaoEncontradoException;
import com.logistica.rastreamento.message.IncidenteEventSender;
import com.logistica.rastreamento.model.Incidente;
import com.logistica.rastreamento.repository.IncidenteRepository;
import com.logistica.rastreamento.service.IncidenteService;
import com.logistica.rastreamento.service.RastreamentoService;
import com.logistica.rastreamento.service.UsuarioServiceClient;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class IncidenteServiceImpl implements IncidenteService {
    // TODO CRIAR CRON JOB PARA DESATIVAR INCIDENTE EXPIRADO
    private final IncidenteRepository incidenteRepository;
    private final RastreamentoService rastreamentoService;
    private final IncidenteEventSender incidenteEventSender;
    private final UsuarioServiceClient usuarioServiceClient;

    public IncidenteServiceImpl(
            IncidenteRepository incidenteRepository,
            RastreamentoService rastreamentoService,
            IncidenteEventSender incidenteEventSender,
            UsuarioServiceClient usuarioServiceClient) {
        this.incidenteRepository = incidenteRepository;
        this.rastreamentoService = rastreamentoService;
        this.incidenteEventSender = incidenteEventSender;
        this.usuarioServiceClient = usuarioServiceClient;
    }

    @Override
    public IncidenteResponse reportarIncidente(IncidenteRequest request) {
        // Verificar se o motorista existe
        try {
            usuarioServiceClient.buscarUsuarioPorTipoEId("motoristas", request.getMotoristaId());
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Motorista não encontrado");
        }

        Incidente incidente = new Incidente();
        incidente.setMotoristaId(request.getMotoristaId());
        incidente.setLatitude(request.getLatitude());
        incidente.setLongitude(request.getLongitude());
        incidente.setTipo(request.getTipo());
        incidente.setDataReporte(LocalDateTime.now());

        // Define duração do incidente (padrão: 24 horas se não informado)
        int duracao = (request.getDuracaoHoras() != null && request.getDuracaoHoras() > 0)
                ? request.getDuracaoHoras() : 24;
        incidente.setDataExpiracao(LocalDateTime.now().plusHours(duracao));

        // Define raio de impacto (padrão: 5km se não informado)
        double raioImpacto = (request.getRaioImpactoKm() != null && request.getRaioImpactoKm() > 0)
                ? request.getRaioImpactoKm() : 5.0;
        incidente.setRaioImpactoKm(raioImpacto);

        incidente.setAtivo(true);

        Incidente incidenteSalvo = incidenteRepository.save(incidente);

        // Buscar motoristas próximos para notificar
        List<LocalizacaoDTO> motoristasProximos = rastreamentoService.buscarEntregasProximas(
                incidente.getLatitude(),
                incidente.getLongitude(),
                incidente.getRaioImpactoKm()
        );

        // Enviar notificações via RabbitMQ
        incidenteEventSender.enviarNotificacaoIncidenteReportado(incidenteSalvo, motoristasProximos);

        return mapToIncidenteResponse(incidenteSalvo);
    }

    @Override
    public List<IncidenteResponse> listarIncidentesAtivos() {
        List<Incidente> incidentes = incidenteRepository.findByAtivoTrueAndDataExpiracaoAfter(LocalDateTime.now());
        return incidentes.stream()
                .map(this::mapToIncidenteResponse)
                .collect(Collectors.toList());
    }

    @Override
    public List<IncidenteResponse> buscarIncidentesProximos(Double latitude, Double longitude, Double raioKm) {
        List<Incidente> incidentes = incidenteRepository.findIncidentesProximos(
                LocalDateTime.now(), latitude, longitude, raioKm);
        return incidentes.stream()
                .map(this::mapToIncidenteResponse)
                .collect(Collectors.toList());
    }

    @Override
    public IncidenteResponse buscarIncidentePorId(Long id) {
        Incidente incidente = incidenteRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Incidente não encontrado"));
        return mapToIncidenteResponse(incidente);
    }

    @Override
    public void desativarIncidente(Long id) {
        Incidente incidente = incidenteRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Incidente não encontrado"));
        incidente.setAtivo(false);
        incidenteRepository.save(incidente);
    }

    private IncidenteResponse mapToIncidenteResponse(Incidente incidente) {
        IncidenteResponse response = new IncidenteResponse();
        response.setId(incidente.getId());
        response.setMotoristaId(incidente.getMotoristaId());
        response.setLatitude(incidente.getLatitude());
        response.setLongitude(incidente.getLongitude());
        response.setTipo(incidente.getTipo());
        response.setDataReporte(incidente.getDataReporte());
        response.setDataExpiracao(incidente.getDataExpiracao());
        response.setAtivo(incidente.getAtivo());
        response.setRaioImpactoKm(incidente.getRaioImpactoKm());
        return response;
    }
}
