package com.logistica.notificacao.message;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.notificacao.exception.ServicoExternoException;
import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.service.EmailService;
import com.logistica.notificacao.service.NotificacaoService;
import com.logistica.notificacao.service.UsuarioServiceClient;
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
    private final EmailService emailService;
    private final UsuarioServiceClient usuarioServiceClient;

    public EventoConsumer(NotificacaoService notificacaoService, EmailService emailService, UsuarioServiceClient usuarioServiceClient) {
        this.notificacaoService = notificacaoService;
        this.emailService = emailService;
        this.usuarioServiceClient = usuarioServiceClient;
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
        // Para eventos PEDIDO_DISPONIVEL, envie apenas para motoristas
        if (tipoEvento.equals("PEDIDO_DISPONIVEL")) {
            if (dados.containsKey("motoristasProximos")) {
                processarLista(dados, "motoristasProximos", tipoEvento, origem, mensagemCompleta);
            }
        } else {
            // Para outros eventos (como PEDIDO_CRIADO), processe normalmente
            processarId(dados, "clienteId", tipoEvento, origem, mensagemCompleta);
            processarId(dados, "motoristaId", tipoEvento, origem, mensagemCompleta);
        }
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
        logger.info("Dados do evento: {}", dados);
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

            logger.info("Chamando gerarConteudoNotificacao para tipo: {}", tipoEvento);
            Map<String, String> conteudo = gerarConteudoNotificacao(tipoEvento, dados);
            notificacao.setTitulo(conteudo.get("titulo"));
            notificacao.setMensagem(conteudo.get("mensagem"));
            logger.info("Conteudo gerado - titulo: {}, mensagem: {}", conteudo.get("titulo"), conteudo.get("mensagem"));

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
                
                // Se o status for ENTREGUE, enviar email
                logger.info("Status verificado: {} - Verificando se deve enviar email", status);
                if ("ENTREGUE".equals(status)) {
                    logger.info("Status é ENTREGUE, enviando email de entrega");
                    enviarEmailEntrega(dados);
                } else {
                    logger.info("Status não é ENTREGUE, não enviando email");
                }
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

    private void enviarEmailEntrega(Map<String, Object> dados) {
        try {
            // Buscar informações do cliente
            Long clienteId = convertToLong(dados.get("clienteId"));
            if (clienteId != null) {
                Map<String, Object> cliente = usuarioServiceClient.buscarUsuarioPorTipoEId("clientes", clienteId);
                if (cliente != null && cliente.containsKey("email")) {
                    String emailCliente = (String) cliente.get("email");
                    Long pedidoId = convertToLong(dados.get("pedidoId"));
                    
                    String assunto = "Pedido Entregue - ID #" + pedidoId;
                    String conteudo = String.format(
                        "Olá!\n\nSeu pedido #%d foi entregue com sucesso!\n\n" +
                        "Detalhes:\n" +
                        "- ID do Pedido: %d\n" +
                        "- Status: ENTREGUE\n" +
                        "- Data de entrega: %s\n\n" +
                        "Obrigado por utilizar nossos serviços!\n\n" +
                        "Equipe de Logística",
                        pedidoId, pedidoId, java.time.LocalDateTime.now().toString()
                    );
                    
                    emailService.enviarEmail(emailCliente, assunto, conteudo);
                    logger.info("Email de entrega enviado para cliente ID: {}, email: {}", clienteId, emailCliente);
                } else {
                    logger.warn("Email não encontrado para cliente ID: {}", clienteId);
                }
            }
        } catch (Exception e) {
            logger.error("Erro ao enviar email de entrega: {}", e.getMessage(), e);
        }
    }
}
