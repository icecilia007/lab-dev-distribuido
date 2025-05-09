package com.logistica.pedidos.service.impl;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.pedidos.config.OSRMClient;
import com.logistica.pedidos.dto.*;
import com.logistica.pedidos.exception.OperacaoInvalidaException;
import com.logistica.pedidos.exception.RecursoNaoEncontradoException;
import com.logistica.pedidos.message.PedidoEventSender;
import com.logistica.pedidos.model.Pedido;
import com.logistica.pedidos.model.StatusPedido;
import com.logistica.pedidos.repository.PedidoRepository;
import com.logistica.pedidos.service.PedidoService;
import com.logistica.pedidos.service.RastreamentoServiceClient;
import com.logistica.pedidos.service.UsuarioServiceClient;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PedidoServiceImpl implements PedidoService {

    private final PedidoRepository pedidoRepository;
    private final UsuarioServiceClient usuarioServiceClient;
    private final OSRMClient osrmService;
    private final PedidoEventSender rabbitMQService;
    private final ObjectMapper objectMapper;
    private final RastreamentoServiceClient rastreamentoServiceClient;

    // Injeção de dependências por construtor
    public PedidoServiceImpl(
            PedidoRepository pedidoRepository,
            UsuarioServiceClient usuarioServiceClient,
            OSRMClient osrmService,
            PedidoEventSender rabbitMQService,
            ObjectMapper objectMapper, RastreamentoServiceClient rastreamentoServiceClient) {
        this.pedidoRepository = pedidoRepository;
        this.usuarioServiceClient = usuarioServiceClient;
        this.osrmService = osrmService;
        this.rabbitMQService = rabbitMQService;
        this.objectMapper = objectMapper;
        this.rastreamentoServiceClient = rastreamentoServiceClient;
    }

    /**
     * Cria um novo pedido no sistema
     */
    @Override
    public PedidoResponse criarPedido(PedidoRequest request) throws JsonProcessingException {
        try {
            usuarioServiceClient.buscarUsuarioPorTipoEId("clientes", request.clienteId());
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Cliente não encontrado ou serviço indisponível");
        }

        RotaResponse rotaResponse = osrmService.calcularRota(
                request.origemLatitude(), request.origemLongitude(),
                request.destinoLatitude(), request.destinoLongitude());

        Pedido pedido = new Pedido();
        pedido.setOrigemLatitude(request.origemLatitude());
        pedido.setOrigemLongitude(request.origemLongitude());
        pedido.setDestinoLatitude(request.destinoLatitude());
        pedido.setDestinoLongitude(request.destinoLongitude());
        pedido.setTipoMercadoria(request.tipoMercadoria());
        pedido.setClienteId(request.clienteId());
        pedido.setStatus(StatusPedido.EM_PROCESSAMENTO);
        pedido.setDataCriacao(LocalDateTime.now());
        pedido.setDataAtualizacao(LocalDateTime.now());

        pedido.setDataEntregaEstimada(LocalDateTime.now().plusMinutes(rotaResponse.tempoEstimadoMinutos()));
        pedido.setDistanciaKm(rotaResponse.distanciaKm());
        pedido.setTempoEstimadoMinutos(rotaResponse.tempoEstimadoMinutos());
        pedido.setRotaMotoristaJson(objectMapper.writeValueAsString(rotaResponse.rota()));

        Pedido pedidoSalvo = pedidoRepository.save(pedido);

        rabbitMQService.enviarNotificacaoPedidoCriado(pedido);

        List<MotoristaProximoDTO> motoristasProximos = buscarMotoristasProximosOrigem(
                pedidoSalvo.getOrigemLatitude(),
                pedidoSalvo.getOrigemLongitude()
        );

        if (!motoristasProximos.isEmpty()) {
            rabbitMQService.notificarMotoristasProximos(pedidoSalvo, motoristasProximos);
        } else {
            pedidoSalvo.setStatus(StatusPedido.CANCELADO);
            pedidoSalvo.setDataAtualizacao(LocalDateTime.now());
            pedidoRepository.save(pedidoSalvo);

            rabbitMQService.enviarNotificacaoPedidoCancelado(
                    pedidoSalvo,
                    "Não há motoristas disponíveis próximos à origem"
            );
        }

        return mapToPedidoResponse(pedidoSalvo);
    }

    private List<MotoristaProximoDTO> buscarMotoristasProximosOrigem(String latitude, String longitude) {
        try {
            Double lat = Double.valueOf(latitude);
            Double lon = Double.valueOf(longitude);
            return rastreamentoServiceClient.buscarMotoristasProximosOrigem(lat, lon);
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Motorista não encontrado");
        }
    }
    // TODO quando o motorista aceitar um pedido, enviar para localização a localização atual desse motorista para ter o a gravação.
    @Override
    public PedidoResponse aceitarPedido(Long pedidoId, Long motoristaId, Double motoristaLatitude, Double motoristaLongitude) {
        Pedido pedido = pedidoRepository.findById(pedidoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Pedido não encontrado"));

        if (pedido.getStatus() != StatusPedido.EM_PROCESSAMENTO) {
            throw new OperacaoInvalidaException("Pedido não está disponível para aceite");
        }

        try {
            usuarioServiceClient.buscarUsuarioPorTipoEId("motoristas", motoristaId);
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Motorista não encontrado");
        }

        RotaResponse rotaMotoristaResponse = osrmService.calcularRota(
                String.valueOf(motoristaLatitude),
                String.valueOf(motoristaLongitude),
                pedido.getOrigemLatitude(),
                pedido.getOrigemLongitude()
        );


        pedido.setMotoristaId(motoristaId);
        pedido.setStatus(StatusPedido.AGUARDANDO_COLETA);
        pedido.setDataAtualizacao(LocalDateTime.now());

        try {
            pedido.setRotaMotoristaJson(objectMapper.writeValueAsString(rotaMotoristaResponse.rota()));
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Erro ao processar rota do motorista", e);
        }

        Pedido pedidoAtualizado = pedidoRepository.save(pedido);

        rabbitMQService.enviarNotificacaoStatusAtualizado(pedidoAtualizado);

        return mapToPedidoResponse(pedidoAtualizado);
    }


    @Scheduled(fixedDelay = 60000) // Executa a cada minuto
    public void verificarPedidosSemAceite() {
        LocalDateTime limiteAceite = LocalDateTime.now().minusMinutes(15); // 15 minutos

        List<Pedido> pedidosSemAceite = pedidoRepository.findByStatusAndDataAtualizacaoBefore(
                StatusPedido.EM_PROCESSAMENTO, limiteAceite);

        for (Pedido pedido : pedidosSemAceite) {
            pedido.setStatus(StatusPedido.CANCELADO);
            pedido.setDataAtualizacao(LocalDateTime.now());
            pedidoRepository.save(pedido);

            rabbitMQService.enviarNotificacaoPedidoCancelado(
                    pedido,
                    "Pedido cancelado por falta de motoristas disponíveis"
            );
        }
    }

    /**
     * Busca um pedido por ID
     */
    @Override
    public PedidoResponse buscarPedidoPorId(Long id) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Pedido não encontrado"));
        Long motoristaId = pedido.getMotoristaId();
        Long clienteId = pedido.getClienteId();

        if(clienteId != null) Optional.ofNullable(usuarioServiceClient.buscarUsuarioPorTipoEId("clientes", clienteId))
                .orElseThrow(() -> new RecursoNaoEncontradoException("Cliente ID " + clienteId + " não encontrado"));



        if(motoristaId != null) Optional.ofNullable(usuarioServiceClient.buscarUsuarioPorTipoEId("motoristas", motoristaId))
                .orElseThrow(() -> new RecursoNaoEncontradoException("Motorista ID " + motoristaId + " não encontrado"));


        return mapToPedidoResponse(pedido);
    }

    /**
     * Lista todos os pedidos de um cliente
     */
    @Override
    public List<PedidoResponse> buscarPedidosPorCliente(Long clienteId) {
        try {
            usuarioServiceClient.buscarUsuarioPorTipoEId("clientes", clienteId);

        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Cliente não encontrado ou serviço indisponível");
        }

        List<Pedido> pedidos = pedidoRepository.findByClienteId(clienteId);
        return pedidos.stream()
                .map(this::mapToPedidoResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lista todos os pedidos por status
     */
    @Override
    public List<PedidoResponse> buscarPedidosPorStatus(StatusPedido status) {
        List<Pedido> pedidos = pedidoRepository.findByStatus(status);
        return pedidos.stream()
                .map(this::mapToPedidoResponse)
                .collect(Collectors.toList());
    }

    /**
     * Lista pedidos associados a um motorista
     */
    @Override
    public List<PedidoResponse> buscarPedidosPorMotorista(Long motoristaId) {
        try {
            usuarioServiceClient.buscarUsuarioPorTipoEId("motoristas", motoristaId);
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Motorista não encontrado ou serviço indisponível");
        }

        List<Pedido> pedidos = pedidoRepository.findByMotoristaId(motoristaId);
        return pedidos.stream()
                .map(this::mapToPedidoResponse)
                .collect(Collectors.toList());
    }

    /**
     * Atualiza o status de um pedido
     */
    @Override
    public PedidoResponse atualizarStatusPedido(Long id, AtualizarStatusRequest request) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Pedido não encontrado"));

        validarTransicaoStatus(pedido.getStatus(), request.novoStatus());

        StatusPedido statusAnterior = pedido.getStatus();
        pedido.setStatus(request.novoStatus());
        pedido.setDataAtualizacao(LocalDateTime.now());

        Pedido pedidoAtualizado = pedidoRepository.save(pedido);

        rabbitMQService.enviarNotificacaoStatusAtualizado(pedidoAtualizado);

        return mapToPedidoResponse(pedidoAtualizado);
    }

    /**
     * Cancela um pedido
     */
    @Override
    public void cancelarPedido(Long id) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Pedido não encontrado"));

        if (pedido.getStatus() == StatusPedido.ENTREGUE) {
            throw new OperacaoInvalidaException("Não é possível cancelar um pedido já entregue");
        }

        StatusPedido statusAnterior = pedido.getStatus();
        pedido.setStatus(StatusPedido.CANCELADO);
        pedido.setDataAtualizacao(LocalDateTime.now());

        Pedido pedidoAtualizado = pedidoRepository.save(pedido);

        rabbitMQService.enviarNotificacaoStatusAtualizado(pedido);
    }

    /**
     * Remove um pedido do sistema
     */
    @Override
    public void removerPedido(Long id) {
        Pedido pedido = pedidoRepository.findById(id)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Pedido não encontrado"));

        if (pedido.getStatus() != StatusPedido.CANCELADO) {
            throw new OperacaoInvalidaException("Apenas pedidos cancelados podem ser removidos");
        }

        pedidoRepository.delete(pedido);
    }

    /**
     * Valida as transições de estado permitidas
     */
    private void validarTransicaoStatus(StatusPedido statusAtual, StatusPedido novoStatus) {
        if (statusAtual == StatusPedido.ENTREGUE && novoStatus != StatusPedido.ENTREGUE) {
            throw new OperacaoInvalidaException("Não é possível alterar o status de um pedido já entregue");
        }

        if (statusAtual == StatusPedido.CANCELADO && novoStatus != StatusPedido.CANCELADO) {
            throw new OperacaoInvalidaException("Não é possível alterar o status de um pedido cancelado");
        }

        if ((statusAtual == StatusPedido.CRIADO || statusAtual == StatusPedido.EM_PROCESSAMENTO) &&
                novoStatus != StatusPedido.AGUARDANDO_COLETA &&
                novoStatus != StatusPedido.CANCELADO) {
            throw new OperacaoInvalidaException("Transição de status inválida");
        }

        if (statusAtual == StatusPedido.AGUARDANDO_COLETA &&
                novoStatus != StatusPedido.EM_ROTA &&
                novoStatus != StatusPedido.CANCELADO) {
            throw new OperacaoInvalidaException("Transição de status inválida");
        }

        if (statusAtual == StatusPedido.EM_ROTA &&
                novoStatus != StatusPedido.ENTREGUE &&
                novoStatus != StatusPedido.CANCELADO) {
            throw new OperacaoInvalidaException("Transição de status inválida");
        }
    }

    /**
     * Converte a entidade Pedido para o DTO PedidoResponse
     */
    private PedidoResponse mapToPedidoResponse(Pedido pedido) {
        JsonNode rotaJson = null;
        RotaResponse rotaResponse = null;


        if (pedido.getRotaMotoristaJson() != null && !pedido.getRotaMotoristaJson().isEmpty()) {
            try {
                rotaJson = objectMapper.readTree(pedido.getRotaMotoristaJson());

                rotaResponse = new RotaResponse(
                        pedido.getDistanciaKm(),
                        pedido.getTempoEstimadoMinutos(),
                        rotaJson
                );
            } catch (JsonProcessingException e) {
                e.printStackTrace();
            }
        }


        return new PedidoResponse(
                pedido.getId(),
                pedido.getOrigemLongitude(),
                pedido.getOrigemLatitude(),
                pedido.getDestinoLongitude(),
                pedido.getDestinoLatitude(),
                pedido.getTipoMercadoria(),
                pedido.getStatus(),
                pedido.getDataCriacao(),
                pedido.getDataAtualizacao(),
                pedido.getDataEntregaEstimada(),
                pedido.getDistanciaKm(),
                pedido.getTempoEstimadoMinutos(),
                pedido.getClienteId(),
                pedido.getMotoristaId(),
                rotaResponse
        );
    }
}
