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
    @Value("${rabbitmq.exchange}")
    private String exchange;

    public IncidenteEventSender(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void enviarNotificacaoIncidenteReportado(Incidente incidente, List<LocalizacaoDTO> motoristasProximos) {
        logger.debug("Enviando notificação de incidente reportado: {}", incidente);

        try {
            var motoristasANotificacar = motoristasProximos.stream()
                    .filter(distinctByKey(LocalizacaoDTO::getMotoristaId))
                    .toList();
            for (LocalizacaoDTO motorista : motoristasANotificacar) {
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
    private static <T> java.util.function.Predicate<T> distinctByKey(java.util.function.Function<? super T, ?> keyExtractor) {
        java.util.Set<Object> seen = java.util.concurrent.ConcurrentHashMap.newKeySet();
        return t -> seen.add(keyExtractor.apply(t));
    }

}
