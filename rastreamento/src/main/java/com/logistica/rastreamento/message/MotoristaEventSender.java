package com.logistica.rastreamento.message;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.rastreamento.dto.LocalizacaoDTO;
import com.logistica.rastreamento.model.Incidente;
import com.logistica.rastreamento.model.StatusVeiculo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class MotoristaEventSender {

    private static final Logger logger = LoggerFactory.getLogger(MotoristaEventSender.class);
    private final RabbitTemplate rabbitTemplate;
    @Value("${rabbitmq.exchange}")
    private String exchange;

    public MotoristaEventSender(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void enviarNotificacaoStatusMotorista(Long idMotorista, StatusVeiculo status) {
        logger.debug("Enviando notificação de status {} para motorista reportado: {}", status.name(), idMotorista);

        try {
            Map<String, Object> mensagem = new HashMap<>();
            mensagem.put("evento", "STATUS_VEICULO_ALTERADO");
            mensagem.put("origem", "RASTREAMENTO_SERVICE");
            mensagem.put("timestamp", Instant.now().toString());

            Map<String, Object> dados = new HashMap<>();
            dados.put("motoristaId", idMotorista);
            dados.put("statusVeiculo", status.name());
            mensagem.put("dados", dados);

            String routingKey = "motorista.status.atualizar";
            rabbitTemplate.convertAndSend(exchange, routingKey, mensagem);
        } catch (Exception e) {
            logger.error("Erro ao enviar notificação de status do motorista: {}", e.getMessage());
        }
    }
}
