package com.logistica.notificacao.message;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.notificacao.exception.ServicoExternoException;
import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.service.NotificacaoService;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
@Slf4j
public class EventoConsumer {

    private static final Logger logger = LoggerFactory.getLogger(EventoConsumer.class);

    private final NotificacaoService notificacaoService;

    public EventoConsumer(NotificacaoService notificacaoService) {
        this.notificacaoService = notificacaoService;
    }

    @RabbitListener(queues = "notificacoes.geral", containerFactory = "rabbitListenerContainerFactory")
    public void processarEvento(Map<String, Object> mensagem) {
        try {
            logger.info("Recebido evento: {}", mensagem);

            String tipoEvento = (String) mensagem.get("evento");
            String origem = (String) mensagem.get("origem");
            Map<String, Object> dados = (Map<String, Object>) mensagem.get("dados");

            if (dados == null) {
                logger.warn("Evento recebido sem dados: {}", tipoEvento);
                return;
            }

            try {
                processarDestinatarios(tipoEvento, origem, dados, mensagem);
            } catch (Exception e) {
                throw new ServicoExternoException("Erro ao processar evento: " + tipoEvento, e);
            }

        } catch (Exception e) {
            logger.error("Erro ao processar evento: {}", e.getMessage(), e);
        }
    }

    private void processarDestinatarios(String tipoEvento, String origem, Map<String, Object> dados, Map<String, Object> mensagemCompleta) {
        processarId(dados, "clienteId", tipoEvento, origem, mensagemCompleta);
        processarId(dados, "motoristaId", tipoEvento, origem, mensagemCompleta);

        processarLista(dados, "motoristasProximos", tipoEvento, origem, mensagemCompleta);
        processarLista(dados, "motoristasANotificar", tipoEvento, origem, mensagemCompleta);
    }

    private void processarId(Map<String, Object> dados, String campoId, String tipoEvento, String origem, Map<String, Object> mensagemCompleta) {
        if (dados.containsKey(campoId) && dados.get(campoId) != null) {
            Long id = convertToLong(dados.get(campoId));
            if (id != null) {
                criarNotificacao(id, tipoEvento, origem, dados, mensagemCompleta);
            }
        }
    }

    private void processarLista(Map<String, Object> dados, String campoLista, String tipoEvento, String origem, Map<String, Object> mensagemCompleta) {
        if (dados.containsKey(campoLista) && dados.get(campoLista) instanceof List) {
            List<?> lista = (List<?>) dados.get(campoLista);
            for (Object item : lista) {
                Long id = convertToLong(item);
                if (id != null) {
                    criarNotificacao(id, tipoEvento, origem, dados, mensagemCompleta);
                }
            }
        }
    }

    private Long convertToLong(Object value) {
        if (value instanceof Integer) {
            return ((Integer) value).longValue();
        } else if (value instanceof Long) {
            return (Long) value;
        } else if (value instanceof String) {
            try {
                return Long.parseLong((String) value);
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    private void criarNotificacao(Long destinatarioId, String tipoEvento, String origem, Map<String, Object> dados, Map<String, Object> mensagemCompleta) {
        logger.info("Criando notificacao para destinatário: {}, evento: {}", destinatarioId, tipoEvento);
        try {
            Notificacao notificacao = new Notificacao();
            notificacao.setDestinatarioId(destinatarioId);
            notificacao.setTipoEvento(tipoEvento);
            notificacao.setOrigem(origem);

            try {
                notificacao.setDadosEvento(mensagemCompleta);
                notificacao.setDataCriacao(LocalDateTime.now());
            } catch (Exception e) {
                logger.warn("Erro ao serializar dados do evento: {}", e.getMessage());
            }

            Map<String, String> conteudo = gerarConteudoNotificacao(tipoEvento, dados);
            notificacao.setTitulo(conteudo.get("titulo"));
            notificacao.setMensagem(conteudo.get("mensagem"));

            notificacaoService.salvar(notificacao);
        } catch (Exception e) {
            logger.error("Erro ao criar notificação para destinatário {}: {}", destinatarioId, e.getMessage());
        }
    }

    private Map<String, String> gerarConteudoNotificacao(String tipoEvento, Map<String, Object> dados) {
        Map<String, String> conteudo = new HashMap<>();

        switch (tipoEvento) {
            case "PEDIDO_CRIADO":
                conteudo.put("titulo", "Novo pedido criado");
                conteudo.put("mensagem", "Seu pedido foi registrado com sucesso!");
                break;
            case "STATUS_ATUALIZADO":
                String status = dados.containsKey("novoStatus") ? dados.get("novoStatus").toString() : "atualizado";
                conteudo.put("titulo", "Status atualizado");
                conteudo.put("mensagem", "Seu pedido agora está " + status);
                break;
            case "PEDIDO_CANCELADO":
                String motivo = dados.containsKey("motivo") ? dados.get("motivo").toString() : "";
                conteudo.put("titulo", "Pedido cancelado");
                conteudo.put("mensagem", motivo.isEmpty() ? "Seu pedido foi cancelado" : "Seu pedido foi cancelado: " + motivo);
                break;
            case "PEDIDO_DISPONIVEL":
                String origem = dados.containsKey("origemEndereco") ? dados.get("origemEndereco").toString() : "local de coleta";
                conteudo.put("titulo", "Novo pedido disponível");
                conteudo.put("mensagem", "Há um novo pedido disponível para coleta em " + origem);
                break;
            case "INCIDENTE_REPORTADO":
            case "ALERTA_INCIDENTE":
                String tipo = dados.containsKey("tipo") ? dados.get("tipo").toString() : "incidente";
                conteudo.put("titulo", "Alerta: " + tipo);
                conteudo.put("mensagem", "Um incidente foi reportado na sua rota");
                break;
            case "STATUS_VEICULO_ALTERADO":
                String statusVeiculo = dados.containsKey("statusVeiculo") ? dados.get("statusVeiculo").toString() : "";
                conteudo.put("titulo", "Status atualizado");
                conteudo.put("mensagem", "O status do veículo foi atualizado para: " + statusVeiculo);
                break;
            default:
                conteudo.put("titulo", "Notificação do sistema");
                conteudo.put("mensagem", "Evento: " + tipoEvento);
        }

        return conteudo;
    }
}
