package com.logistica.rastreamento.message;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.rastreamento.dto.LocalizacaoDTO;
import com.logistica.rastreamento.model.Incidente;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static com.logistica.rastreamento.util.DistanciaUtils.calculateDistanceInKm;

@Component
public class IncidenteEventSender {

    private static final Logger logger = LoggerFactory.getLogger(IncidenteEventSender.class);
    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;
    @Value("${rabbitmq.exchange}")
    private String exchange;

    public IncidenteEventSender(RabbitTemplate rabbitTemplate, ObjectMapper objectMapper) {
        this.rabbitTemplate = rabbitTemplate;
        this.objectMapper = objectMapper;
    }

    public void enviarNotificacaoIncidenteReportado(Incidente incidente, List<LocalizacaoDTO> motoristasProximos) {
        logger.debug("Enviando notificação de incidente reportado: {}", incidente);

        try {
            // Notificação geral do incidente
            Map<String, Object> mensagem = new HashMap<>();
            mensagem.put("evento", "INCIDENTE_REPORTADO");
            mensagem.put("origem", "RASTREAMENTO_SERVICE");
            mensagem.put("timestamp", Instant.now().toString());

            Map<String, Object> dados = new HashMap<>();
            dados.put("incidenteId", incidente.getId());
            dados.put("motoristaId", incidente.getMotoristaId());
            dados.put("tipo", incidente.getTipo().name());
            dados.put("latitude", incidente.getLatitude());
            dados.put("longitude", incidente.getLongitude());
            dados.put("dataReporte", incidente.getDataReporte());
            dados.put("dataExpiracao", incidente.getDataExpiracao());
            dados.put("raioImpactoKm", incidente.getRaioImpactoKm());

            // IDs dos motoristas próximos
            dados.put("motoristasANotificar",
                    motoristasProximos.stream()
                            .map(LocalizacaoDTO::getMotoristaId)
                            .toList());

            mensagem.put("dados", dados);

            String routingKey = "incidentes.incidente.reportado." + incidente.getTipo().name().toLowerCase();
            String mensagemJson = objectMapper.writeValueAsString(mensagem);
            rabbitTemplate.convertAndSend(exchange, routingKey, mensagemJson);

            // Notificações individuais para cada motorista próximo
            for (LocalizacaoDTO motorista : motoristasProximos) {
                Map<String, Object> notificacaoIndividual = new HashMap<>();
                notificacaoIndividual.put("evento", "ALERTA_INCIDENTE");
                notificacaoIndividual.put("origem", "RASTREAMENTO_SERVICE");
                notificacaoIndividual.put("timestamp", Instant.now().toString());

                Map<String, Object> dadosIndividuais = new HashMap<>();
                dadosIndividuais.put("incidenteId", incidente.getId());
                dadosIndividuais.put("motoristaId", motorista.getMotoristaId());
                dadosIndividuais.put("tipo", incidente.getTipo().name());
                dadosIndividuais.put("latitude", incidente.getLatitude());
                dadosIndividuais.put("longitude", incidente.getLongitude());
                dadosIndividuais.put("distanciaKm", calculateDistanceInKm(
                        motorista.getLatitude(), motorista.getLongitude(),
                        incidente.getLatitude(), incidente.getLongitude()));

                notificacaoIndividual.put("dados", dadosIndividuais);

                String routingKeyMotorista = "incidentes.alerta.motorista." + motorista.getMotoristaId();
                rabbitTemplate.convertAndSend(exchange, routingKeyMotorista, notificacaoIndividual);
            }
        } catch (Exception e) {
            logger.error("Erro ao enviar notificação de incidente: {}", e.getMessage());
        }
    }
}
