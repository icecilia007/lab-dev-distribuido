package com.logistica.pedidos.message;


import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.pedidos.config.NominatimClient;
import com.logistica.pedidos.dto.MotoristaProximoDTO;
import com.logistica.pedidos.model.Pedido;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Component
public class PedidoEventSender {

    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    @Value("${rabbitmq.exchange}")
    private String exchange;

    private static final Logger logger = LoggerFactory.getLogger(PedidoEventSender.class);
    private final NominatimClient nominatimClient;

    public PedidoEventSender(RabbitTemplate rabbitTemplate, ObjectMapper objectMapper, NominatimClient nominatimClient) {
        this.rabbitTemplate = rabbitTemplate;
        this.objectMapper = objectMapper;
        this.nominatimClient = nominatimClient;
    }

    public void enviarNotificacaoStatusAtualizado(Pedido pedido) {
        logger.debug("Enviando evento status atualizado: {}", pedido);
        try {
            Map<String, Object> mensagem = new HashMap<>();
            mensagem.put("evento", "STATUS_ATUALIZADO");
            mensagem.put("origem", "PEDIDOS_SERVICE");
            mensagem.put("timestamp", Instant.now().toString());

            Map<String, Object> dados = new HashMap<>();
            dados.put("pedidoId", pedido.getId());
            dados.put("novoStatus", pedido.getStatus());
            dados.put("dataAtualizacao", pedido.getDataAtualizacao());
            dados.put("clienteId", pedido.getClienteId());

            Long idMotorista = pedido.getMotoristaId();
            if (idMotorista != null) {
                dados.put("motoristaId", idMotorista);
            }

            mensagem.put("dados", dados);

            String routingKey = "pedidos.status." + pedido.getStatus();

            rabbitTemplate.convertAndSend(exchange, routingKey, mensagem);
        } catch (Exception e) {
            logger.error("Erro ao enviar notificação de status: {}", e.getMessage());
        }
    }

    public void enviarNotificacaoPedidoCriado(Pedido pedido) {
        logger.debug("Enviando evento pedido criado: {}", pedido);
        try {
            Map<String, Object> mensagem = new HashMap<>();
            mensagem.put("evento", "PEDIDO_CRIADO");
            mensagem.put("origem", "PEDIDOS_SERVICE");
            mensagem.put("timestamp", Instant.now().toString());

            Map<String, Object> dados = new HashMap<>();
            dados.put("pedidoId", pedido.getId());
            dados.put("clienteId", pedido.getClienteId());
            dados.put("destinoLongitude", pedido.getDestinoLongitude());
            dados.put("destinoLatitude", pedido.getDestinoLatitude());
            dados.put("origemLongitude", pedido.getOrigemLongitude());
            dados.put("origemLatitude", pedido.getOrigemLatitude());
            dados.put("tempoEstimadoMinutos", pedido.getTempoEstimadoMinutos());
            dados.put("dataCriacao", pedido.getDataCriacao());

            mensagem.put("dados", dados);

            String routingKey = "pedidos.pedido.criado";
            rabbitTemplate.convertAndSend(exchange, routingKey, mensagem);
        } catch (Exception e) {
            logger.error("Erro ao enviar notificação de pedido criado: {}", e.getMessage());
        }
    }

    /**
     * Envia notificação para motoristas próximos sobre um novo pedido disponível
     */
    public void notificarMotoristasProximos(Pedido pedido, List<MotoristaProximoDTO> motoristasProximos) {
        logger.debug("Notificando {} motoristas próximos sobre o pedido {}",
                motoristasProximos.size(), pedido.getId());

        try {
            Map<String, Object> mensagem = new HashMap<>();
            mensagem.put("evento", "PEDIDO_DISPONIVEL");
            mensagem.put("origem", "PEDIDOS_SERVICE");
            mensagem.put("timestamp", Instant.now().toString());

            Map<String, Object> dados = new HashMap<>();
            String enderecoOrigem = nominatimClient.getEndereco(
                    Double.valueOf(pedido.getOrigemLatitude()),
                    Double.valueOf(pedido.getOrigemLongitude())
            );
            String enderecoDestino = nominatimClient.getEndereco(
                    Double.valueOf(pedido.getDestinoLatitude()),
                    Double.valueOf(pedido.getDestinoLongitude())
            );

            dados.put("pedidoId", pedido.getId());
            dados.put("clienteId", pedido.getClienteId());
            dados.put("tipoMercadoria", pedido.getTipoMercadoria());
            dados.put("origemEndereco", enderecoOrigem);
            dados.put("destinoEndereco", enderecoDestino);
            dados.put("distanciaKm", pedido.getDistanciaKm());
            dados.put("tempoEstimadoMinutos", pedido.getTempoEstimadoMinutos());

            List<Long> motoristasIds = motoristasProximos.stream()
                    .map(MotoristaProximoDTO::getMotoristaId)
                    .collect(Collectors.toList());
            dados.put("motoristasProximos", motoristasIds);

            mensagem.put("dados", dados);

            for (MotoristaProximoDTO motorista : motoristasProximos) {
                Map<String, Object> dadosIndividuais = new HashMap<>(dados);
                dadosIndividuais.put("distanciaMotorista", motorista.getDistanciaKm());

                Map<String, Object> notificacaoIndividual = new HashMap<>(mensagem);
                notificacaoIndividual.put("dados", dadosIndividuais);

                String routingKeyIndividual = "pedidos.disponivel.motorista." + motorista.getMotoristaId();
                rabbitTemplate.convertAndSend(exchange, routingKeyIndividual, notificacaoIndividual);
            }
        } catch (Exception e) {
            logger.error("Erro ao notificar motoristas próximos: {}", e.getMessage());
        }
    }

    /**
     * Envia notificação de pedido cancelado para o cliente
     */
    public void enviarNotificacaoPedidoCancelado(Pedido pedido, String motivo) {
        logger.debug("Enviando notificação de cancelamento para o pedido {}: {}",
                pedido.getId(), motivo);

        try {
            Map<String, Object> mensagem = new HashMap<>();
            mensagem.put("evento", "PEDIDO_CANCELADO");
            mensagem.put("origem", "PEDIDOS_SERVICE");
            mensagem.put("timestamp", Instant.now().toString());

            Map<String, Object> dados = new HashMap<>();
            dados.put("pedidoId", pedido.getId());
            dados.put("clienteId", pedido.getClienteId());
            dados.put("motivo", motivo);
            dados.put("dataCancelamento", pedido.getDataAtualizacao());

            mensagem.put("dados", dados);

            String routingKey = "pedidos.pedido.cancelado";
            rabbitTemplate.convertAndSend(exchange, routingKey, mensagem);
        } catch (Exception e) {
            logger.error("Erro ao enviar notificação de cancelamento: {}", e.getMessage());
        }
    }
}
