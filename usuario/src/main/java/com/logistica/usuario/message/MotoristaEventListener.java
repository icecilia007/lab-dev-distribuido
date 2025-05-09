package com.logistica.usuario.message;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.usuario.model.Motorista;
import com.logistica.usuario.repository.MotoristaRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.Exchange;
import org.springframework.amqp.rabbit.annotation.Queue;
import org.springframework.amqp.rabbit.annotation.QueueBinding;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.util.Map;

@Component
public class MotoristaEventListener {

    private final MotoristaRepository motoristaRepository;
    private final ObjectMapper objectMapper;
    private static final Logger logger = LoggerFactory.getLogger(MotoristaEventListener.class);

    public MotoristaEventListener(MotoristaRepository motoristaRepository, ObjectMapper objectMapper) {
        this.motoristaRepository = motoristaRepository;
        this.objectMapper = objectMapper;
    }

    @RabbitListener(bindings = @QueueBinding(
            value = @Queue(value = "usuario.motorista.status"),
            exchange = @Exchange(value = "${rabbitmq.exchange}"),
            key = "motorista.status.atualizar"
    ))
    public void receberAtualizacaoStatusVeiculo(String mensagem) {
        try {
            Map<String, Object> evento = objectMapper.readValue(mensagem, Map.class);
            logger.info("Recebida atualização de status de veículo: {}", evento);

            String evento_tipo = (String) evento.get("evento");
            if ("STATUS_VEICULO_ALTERADO".equals(evento_tipo)) {
                Map<String, Object> dados = (Map<String, Object>) evento.get("dados");
                Long motoristaId = Long.valueOf(dados.get("motoristaId").toString());
                String statusVeiculo = (String) dados.get("statusVeiculo");

                // Mapear status do veículo para status do motorista
                String statusMotorista = mapearStatusVeiculoParaMotorista(statusVeiculo);
                atualizarStatusMotorista(motoristaId, statusMotorista);
            }
        } catch (JsonProcessingException e) {
            logger.error("Erro ao processar mensagem de atualização de status: {}", e.getMessage());
        }
    }

    private String mapearStatusVeiculoParaMotorista(String statusVeiculo) {
        switch (statusVeiculo) {
            case "DISPONIVEL":
                return "DISPONIVEL";
            case "EM_MOVIMENTO":
                return "EM_MOVIMENTO";
            case "PARADO":
                return "PARADO";
            default:
                return "INDISPONIVEL";
        }
    }

    private void atualizarStatusMotorista(Long motoristaId, String novoStatus) {
        Motorista motorista = motoristaRepository.findById(motoristaId)
                .orElse(null);

        if (motorista != null) {
            motorista.setStatus(novoStatus);
            motoristaRepository.save(motorista);
            logger.info("Status do motorista {} atualizado para: {}", motoristaId, novoStatus);
        } else {
            logger.warn("Motorista não encontrado: {}", motoristaId);
        }
    }
}
