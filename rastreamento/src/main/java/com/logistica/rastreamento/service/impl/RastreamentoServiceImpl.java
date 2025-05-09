package com.logistica.rastreamento.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.rastreamento.dto.*;
import com.logistica.rastreamento.exception.OperacaoInvalidaException;
import com.logistica.rastreamento.exception.RecursoNaoEncontradoException;
import com.logistica.rastreamento.message.MotoristaEventSender;
import com.logistica.rastreamento.model.Localizacao;
import com.logistica.rastreamento.model.StatusPedido;
import com.logistica.rastreamento.model.StatusVeiculo;
import com.logistica.rastreamento.repository.LocalizacaoRepository;
import com.logistica.rastreamento.service.LocalizacaoObserver;
import com.logistica.rastreamento.service.PedidoServiceClient;
import com.logistica.rastreamento.service.RastreamentoService;
import com.logistica.rastreamento.service.UsuarioServiceClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import static com.logistica.rastreamento.util.DistanciaUtils.calculateDistanceInKm;

@Service
public class RastreamentoServiceImpl implements RastreamentoService {

    private static final Logger logger = LoggerFactory.getLogger(RastreamentoServiceImpl.class);
    private final LocalizacaoRepository localizacaoRepository;
    private final PedidoServiceClient pedidoServiceClient;
    private final UsuarioServiceClient usuarioServiceClient;
    private final MotoristaEventSender motoristaEventSender;
    private final ObjectMapper objectMapper;
    private final Map<Long, List<LocalizacaoObserver>> observadores = new ConcurrentHashMap<>();

    public RastreamentoServiceImpl(LocalizacaoRepository localizacaoRepository,
                                   PedidoServiceClient pedidoServiceClient, UsuarioServiceClient usuarioServiceClient, MotoristaEventSender motoristaEventSender, ObjectMapper objectMapper) {
        this.localizacaoRepository = localizacaoRepository;
        this.pedidoServiceClient = pedidoServiceClient;
        this.usuarioServiceClient = usuarioServiceClient;
        this.motoristaEventSender = motoristaEventSender;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean atualizarLocalizacao(AtualizacaoLocalizacaoDTO dto) {
        try {
            //atualizar localização motorista primeiro acesso
            if (dto.getPedidoId() == null) {
                Localizacao localizacao = new Localizacao();
                localizacao.setMotoristaId(dto.getMotoristaId());
                localizacao.setPedidoId(null);
                localizacao.setLatitude(dto.getLatitude());
                localizacao.setLongitude(dto.getLongitude());
                localizacao.setTimestamp(LocalDateTime.now());

                // Quando não há pedido, o veículo está disponível
                localizacao.setStatusVeiculo(StatusVeiculo.DISPONIVEL);

                localizacaoRepository.save(localizacao);
                motoristaEventSender.enviarNotificacaoStatusMotorista(dto.getMotoristaId(), StatusVeiculo.DISPONIVEL);

                return true;
            }
            // Buscar pedido atual
            var pedido = objectMapper.convertValue(pedidoServiceClient.buscarPedidoPorId(dto.getPedidoId()), PedidoDTO.class);

            // Salvar localização
            Localizacao localizacao = new Localizacao();
            localizacao.setPedidoId(dto.getPedidoId());
            localizacao.setMotoristaId(dto.getMotoristaId());
            localizacao.setLatitude(dto.getLatitude());
            localizacao.setLongitude(dto.getLongitude());
            localizacao.setTimestamp(LocalDateTime.now());

            // Determinar status do veículo baseado na localização
            StatusVeiculo novoStatusVeiculo = determinarStatusVeiculo(
                    localizacao,
                    StatusPedido.valueOf(pedido.getStatus())
            );

            // Salvar novo status
            localizacao.setStatusVeiculo(novoStatusVeiculo);
            localizacaoRepository.save(localizacao);

            // Notificar service de usuarios
            motoristaEventSender.enviarNotificacaoStatusMotorista(dto.getMotoristaId(), novoStatusVeiculo);

            // Notificar observadores
            if (observadores.containsKey(dto.getPedidoId())) {
                LocalizacaoDTO novaLocalizacao = converterParaDTO(localizacao);

                List<LocalizacaoObserver> observadoresANotificar = new ArrayList<>(observadores.get(dto.getPedidoId()));
                for (LocalizacaoObserver observer : observadoresANotificar) {
                    try {
                        observer.onNovaLocalizacao(novaLocalizacao);
                    } catch (Exception e) {
                        logger.error("Erro ao notificar observador: {}", e.getMessage());
                    }
                }

            }

            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }


    private StatusVeiculo determinarStatusVeiculo(Localizacao localizacaoAtual, StatusPedido statusPedido) {
        // Se não há pedido ativo (status ENTREGUE ou CANCELADO), motorista está disponível
        if (statusPedido == StatusPedido.ENTREGUE || statusPedido == StatusPedido.CANCELADO) {
            return StatusVeiculo.DISPONIVEL;
        }

        // Verificar se está parado com base na distância percorrida
        boolean estaParado = verificarSeEstaParado(localizacaoAtual);
        if (estaParado) {
            return StatusVeiculo.PARADO;
        }

        // Se existe pedido ativo e não está parado, está em movimento
        return StatusVeiculo.EM_MOVIMENTO;
    }

    @Override
    public List<MotoristaProximoDTO> buscarMotoristasProximos(Double latitude, Double longitude, Double raioKm) {
        // Obter localizações próximas com veículos disponíveis
        var resultados = localizacaoRepository.encontrarMotoristasProximos(latitude, longitude, raioKm);
        logger.info("Resultados encontrados: {}", resultados);

        // Filtrar apenas motoristas com status DISPONIVEL no serviço de usuários
        return resultados.stream()
                .map(resultado -> {
                    try {
                        // Mapeando os campos individuais do array baseado no formato que você identificou
                        Long motoristaId = (Long) resultado[0];
                        Double lat = (Double) resultado[1];
                        Double lon = (Double) resultado[2];
                        Timestamp timestamp = (Timestamp) resultado[3];
                        Double distancia = (Double) resultado[4];

                        // Verificar status do motorista
                        Object motoristaObj = usuarioServiceClient.buscarUsuarioPorTipoEId("motoristas", motoristaId);

                        // Convertemos para Map para acessar campos
                        Map<String, Object> motorista;
                        if (motoristaObj instanceof Map) {
                            motorista = (Map<String, Object>) motoristaObj;
                        } else {
                            motorista = objectMapper.convertValue(motoristaObj, Map.class);
                        }

                        String statusMotorista = (String) motorista.get("status");
                        if (!"DISPONIVEL".equals(statusMotorista)) {
                            return null; // Ignorar se motorista não estiver disponível
                        }

                        // Criar DTO apenas para motoristas disponíveis
                        MotoristaProximoDTO dto = new MotoristaProximoDTO();
                        dto.setMotoristaId(motoristaId);
                        dto.setLatitude(lat);
                        dto.setLongitude(lon);
                        dto.setDistanciaKm(distancia);
                        dto.setUltimaAtualizacao(timestamp.toLocalDateTime());
                        return dto;
                    } catch (Exception e) {
                        logger.error("Erro ao processar motorista: {}", e.getMessage(), e);
                        return null;
                    }
                })
                .filter(Objects::nonNull)
                .collect(Collectors.toList());
    }


    @Override
    public boolean confirmarColetaPedido(Long pedidoId, Long motoristaId) {
        try {
            // Buscar pedido e verificar status atual
            var pedido = objectMapper.convertValue(pedidoServiceClient.buscarPedidoPorId(pedidoId), PedidoDTO.class);

            if (!StatusPedido.valueOf(pedido.getStatus()).equals(StatusPedido.AGUARDANDO_COLETA)) {
                throw new OperacaoInvalidaException("Pedido não está aguardando coleta");
            }

            // Verificar se motorista está atribuído ao pedido
            if (!pedido.getMotoristaId().equals(motoristaId)) {
                throw new OperacaoInvalidaException("Motorista não está atribuído a este pedido");
            }

            // Buscar última localização do motorista
            Localizacao ultimaLocalizacao = localizacaoRepository
                    .findTopByMotoristaIdOrderByTimestampDesc(motoristaId)
                    .orElseThrow(() -> new RecursoNaoEncontradoException("Localização não encontrada"));

            // Calcular distância até o ponto de origem
            double distanciaOrigem = calculateDistanceInKm(
                    ultimaLocalizacao.getLatitude(), ultimaLocalizacao.getLongitude(),
                    pedido.getOrigemLatitude(), pedido.getOrigemLongitude()
            );

            // Verificar se está próximo o suficiente (menos de 1 km)
            if (distanciaOrigem > 1.0) {
                throw new OperacaoInvalidaException("Motorista deve estar próximo ao ponto de coleta");
            }

            // Atualizar status do pedido para EM_ROTA
            pedidoServiceClient.atualizarStatusPedido(
                    pedidoId,
                    new AtualizarStatusRequest(StatusPedido.EM_ROTA)
            );

            // Atualizar status do veículo para EM_MOVIMENTO
            ultimaLocalizacao.setStatusVeiculo(StatusVeiculo.EM_MOVIMENTO);
            localizacaoRepository.save(ultimaLocalizacao);

            motoristaEventSender.enviarNotificacaoStatusMotorista(motoristaId, StatusVeiculo.EM_MOVIMENTO);

            return true;
        } catch (Exception e) {
            logger.error("Erro ao confirmar coleta: {}", e.getMessage());
            return false;
        }
    }

    @Override
    public boolean confirmarEntregaPedido(Long pedidoId, Long motoristaId) {
        try {
            // Buscar pedido atual
            var pedido = objectMapper.convertValue(pedidoServiceClient.buscarPedidoPorId(pedidoId), PedidoDTO.class);

            if (!StatusPedido.valueOf(pedido.getStatus()).equals(StatusPedido.EM_ROTA)) {
                throw new OperacaoInvalidaException("Pedido não está em rota");
            }

            // Buscar última localização do motorista
            Localizacao ultimaLocalizacao = localizacaoRepository
                    .findTopByMotoristaIdOrderByTimestampDesc(motoristaId)
                    .orElseThrow(() -> new RecursoNaoEncontradoException("Localização não encontrada"));

            // Calcular distância até o ponto de destino
            double distanciaDestino = calculateDistanceInKm(
                    ultimaLocalizacao.getLatitude(), ultimaLocalizacao.getLongitude(),
                    pedido.getDestinoLatitude(), pedido.getDestinoLongitude()
            );

            // Verificar se está próximo o suficiente (menos de 1 km)
            if (distanciaDestino > 1.0) {
                throw new OperacaoInvalidaException("Motorista deve estar próximo ao ponto de entrega");
            }

            // Atualizar status do pedido para ENTREGUE
            pedidoServiceClient.atualizarStatusPedido(
                    pedidoId,
                    new AtualizarStatusRequest(StatusPedido.ENTREGUE)
            );

            // Atualizar status do veículo para DISPONÍVEL
            ultimaLocalizacao.setStatusVeiculo(StatusVeiculo.DISPONIVEL);
            localizacaoRepository.save(ultimaLocalizacao);

            motoristaEventSender.enviarNotificacaoStatusMotorista(motoristaId, StatusVeiculo.DISPONIVEL);

            return true;
        } catch (Exception e) {
            logger.error("Erro ao confirmar entrega: {}", e.getMessage());
            return false;
        }
    }

    private boolean verificarSeEstaParado(Localizacao localizacaoAtual) {
        // Buscar última localização registrada
        Optional<Localizacao> ultimaLocalizacaoOpt = localizacaoRepository
                .findTopByMotoristaIdOrderByTimestampDesc(localizacaoAtual.getMotoristaId());

        if (!ultimaLocalizacaoOpt.isPresent()) {
            return false; // Primeira localização, considerar em movimento
        }

        Localizacao ultimaLocalizacao = ultimaLocalizacaoOpt.get();

        // Calcular distância entre localizações
        double distancia = calculateDistanceInKm(
                localizacaoAtual.getLatitude(), localizacaoAtual.getLongitude(),
                ultimaLocalizacao.getLatitude(), ultimaLocalizacao.getLongitude()
        );

        // Calcular tempo entre as leituras
        long segundosEntreLeituras = Duration.between(
                ultimaLocalizacao.getTimestamp(),
                localizacaoAtual.getTimestamp()
        ).getSeconds();

        // Se moveu menos de 10 metros em 2 minutos, está parado
        return distancia < 0.01 && segundosEntreLeituras > 120;
    }

    @Override
    public LocalizacaoDTO consultarLocalizacaoAtual(Long pedidoId) {
        Localizacao localizacao = localizacaoRepository.findTopByPedidoIdOrderByTimestampDesc(pedidoId)
                .orElseThrow(() -> new RecursoNaoEncontradoException("Não há registros de localização para o pedido: " + pedidoId));

        return converterParaDTO(localizacao);
    }

    @Override
    public List<LocalizacaoDTO> buscarEntregasProximas(Double latitude, Double longitude, Double raioKm) {
        List<Localizacao> localizacoes = localizacaoRepository.encontrarEntregasProximas(latitude, longitude, raioKm);

        return localizacoes.stream()
                .map(this::converterParaDTO)
                .collect(Collectors.toList());
    }

    @Override
    public void registrarObservador(Long pedidoId, LocalizacaoObserver observer) {
        observadores.computeIfAbsent(pedidoId, k -> new ArrayList<>()).add(observer);
    }

    @Override
    public void removerObservador(Long pedidoId, LocalizacaoObserver observer) {
        if (observadores.containsKey(pedidoId)) {
            observadores.get(pedidoId).remove(observer);
        }
    }

    @Override
    public List<LocalizacaoDTO> buscarHistoricoLocalizacoes(Long pedidoId) {
        // Verificar se o pedido existe
        try {
            pedidoServiceClient.buscarPedidoPorId(pedidoId);
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Pedido não encontrado ou serviço indisponível");
        }

        List<Localizacao> localizacoes = localizacaoRepository.findByPedidoIdOrderByTimestampDesc(pedidoId);

        return localizacoes.stream()
                .map(this::converterParaDTO)
                .collect(Collectors.toList());
    }

    @Override
    public Map<String, Object> calcularEstatisticasMotorista(Long motoristaId, LocalDate dataInicio, LocalDate dataFim) {
        // Verificar se o motorista existe
        try {
            usuarioServiceClient.buscarUsuarioPorTipoEId("motoristas", motoristaId);
        } catch (Exception e) {
            throw new RecursoNaoEncontradoException("Motorista não encontrado ou serviço indisponível");
        }

        // Converter datas para LocalDateTime para pesquisa completa do dia
        LocalDateTime inicio = dataInicio.atStartOfDay();
        LocalDateTime fim = dataFim.atTime(23, 59, 59);

        // Buscar todas as localizações do motorista no período
        List<Localizacao> localizacoes = localizacaoRepository.findByMotoristaIdAndTimestampBetweenOrderByTimestamp(
                motoristaId, inicio, fim);

        // Caso não existam registros no período
        if (localizacoes.isEmpty()) {
            Map<String, Object> estatisticasVazias = new HashMap<>();
            estatisticasVazias.put("mensagem", "Não há registros de localização para este motorista no período especificado");
            estatisticasVazias.put("totalRegistros", 0);
            return estatisticasVazias;
        }

        // Calcular estatísticas
        Map<String, Object> estatisticas = new HashMap<>();

        // 1. Total de registros
        int totalRegistros = localizacoes.size();
        estatisticas.put("totalRegistros", totalRegistros);

        // 2. Distância total percorrida
        double distanciaTotal = calcularDistanciaTotal(localizacoes);
        estatisticas.put("distanciaTotalKm", Math.round(distanciaTotal * 10) / 10.0);

        // 3. Tempo total em movimento
        long tempoEmMovimentoMinutos = calcularTempoEmMovimento(localizacoes);
        estatisticas.put("tempoEmMovimentoMinutos", tempoEmMovimentoMinutos);

        // 4. Velocidade média em km/h (apenas quando em movimento)
        double velocidadeMedia = tempoEmMovimentoMinutos > 0
                ? (distanciaTotal / tempoEmMovimentoMinutos) * 60
                : 0;
        estatisticas.put("velocidadeMediaKmH", Math.round(velocidadeMedia * 10) / 10.0);

        // 5. Contagem por status do veículo
        Map<StatusVeiculo, Long> contagemPorStatus = localizacoes.stream()
                .collect(Collectors.groupingBy(Localizacao::getStatusVeiculo, Collectors.counting()));
        estatisticas.put("contagemPorStatus", contagemPorStatus);

        // 6. Pedidos únicos atendidos no período
        Set<Long> pedidosUnicos = localizacoes.stream()
                .map(Localizacao::getPedidoId)
                .collect(Collectors.toSet());
        estatisticas.put("pedidosAtendidos", pedidosUnicos.size());
        estatisticas.put("listaPedidosAtendidos", pedidosUnicos);

        return estatisticas;
    }

    // Método auxiliar para calcular a distância total entre pontos consecutivos
    private double calcularDistanciaTotal(List<Localizacao> localizacoes) {
        double distanciaTotal = 0.0;

        for (int i = 0; i < localizacoes.size() - 1; i++) {
            Localizacao pontoA = localizacoes.get(i);
            Localizacao pontoB = localizacoes.get(i + 1);

            // Calcula distância usando Haversine
            double latA = pontoA.getLatitude();
            double lonA = pontoA.getLongitude();
            double latB = pontoB.getLatitude();
            double lonB = pontoB.getLongitude();

            // Raio médio da Terra em km
            final double R = 6371.0;

            // Conversão para radianos
            double latDistance = Math.toRadians(latB - latA);
            double lonDistance = Math.toRadians(lonB - lonA);

            // Fórmula de Haversine
            double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                    + Math.cos(Math.toRadians(latA)) * Math.cos(Math.toRadians(latB))
                    * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);

            double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

            // Adicionar ao total
            distanciaTotal += R * c;
        }

        return distanciaTotal;
    }

    // Método auxiliar para calcular tempo em movimento (em minutos)
    private long calcularTempoEmMovimento(List<Localizacao> localizacoes) {
        long tempoTotalMinutos = 0;

        // Filtrar apenas localizações com status EM_MOVIMENTO
        List<Localizacao> emMovimento = localizacoes.stream()
                .filter(loc -> loc.getStatusVeiculo() == StatusVeiculo.EM_MOVIMENTO)
                .sorted(Comparator.comparing(Localizacao::getTimestamp))
                .collect(Collectors.toList());

        // Caso não haja registros em movimento
        if (emMovimento.isEmpty()) {
            return 0;
        }

        // Para um cálculo mais preciso, precisaríamos agrupar períodos contínuos
        for (int i = 0; i < emMovimento.size() - 1; i++) {
            LocalDateTime inicio = emMovimento.get(i).getTimestamp();
            LocalDateTime fim = emMovimento.get(i + 1).getTimestamp();

            // Adicionar diferença em minutos
            tempoTotalMinutos += Duration.between(inicio, fim).toMinutes();
        }

        return tempoTotalMinutos;
    }

    private LocalizacaoDTO converterParaDTO(Localizacao localizacao) {
        LocalizacaoDTO dto = new LocalizacaoDTO();
        dto.setPedidoId(localizacao.getPedidoId());
        dto.setMotoristaId(localizacao.getMotoristaId());
        dto.setLatitude(localizacao.getLatitude());
        dto.setLongitude(localizacao.getLongitude());
        dto.setTimestamp(localizacao.getTimestamp());
        dto.setStatusVeiculo(localizacao.getStatusVeiculo().name());

        // Calcular distância e tempo restante (poderia ser obtido de um serviço externo)
        dto.setDistanciaDestinoKm(calcularDistanciaDestino(localizacao));
        dto.setTempoEstimadoMinutos(calcularTempoRestante(localizacao));

        return dto;
    }

    // TODO colocar diferença entre quando está para rota de origem x rota de destino
    private double calcularDistanciaDestino(Localizacao localizacao) {
        // Obtém detalhes do pedido do microsserviço de pedidos
        Long pedidoId = localizacao.getPedidoId();
        if (pedidoId == null) return 0.0;
        var pedido = objectMapper.convertValue(pedidoServiceClient.buscarPedidoPorId(localizacao.getPedidoId()), PedidoDTO.class);

        // Localização atual do motorista
        double latAtual = localizacao.getLatitude();
        double lonAtual = localizacao.getLongitude();

        // Determinar o ponto alvo com base no status do pedido
        double latAlvo, lonAlvo;

        if (StatusPedido.valueOf(pedido.getStatus()) == StatusPedido.AGUARDANDO_COLETA) {
            // Se está aguardando coleta, calcular distância até o ponto de coleta (origem)
            latAlvo = pedido.getOrigemLatitude();
            lonAlvo = pedido.getOrigemLongitude();
        } else {
            // Se já coletou (EM_ROTA), calcular distância até o destino final
            latAlvo = pedido.getDestinoLatitude();
            lonAlvo = pedido.getDestinoLongitude();
        }
        return calculateDistanceInKm(latAlvo, lonAlvo, latAtual, lonAtual);
    }

    private int calcularTempoRestante(Localizacao localizacao) {
        // Obtém detalhes do pedido do microsserviço de pedidos
        Long pedidoId = localizacao.getPedidoId();
        if (pedidoId == null) return 0;
        var pedido = objectMapper.convertValue(pedidoServiceClient.buscarPedidoPorId(localizacao.getPedidoId()), PedidoDTO.class);

        // Status atual do pedido
        StatusPedido statusPedido = StatusPedido.valueOf(pedido.getStatus());

        // Calcula distância até o ponto alvo (origem ou destino)
        double distanciaRestante = calcularDistanciaDestino(localizacao);

        // Se não houver mais distância, tempo é zero
        if (distanciaRestante <= 0.1) {
            return 0;
        }

        // Calcular tempo restante com base no status
        if (statusPedido == StatusPedido.AGUARDANDO_COLETA) {
            // Para fase de coleta, calcular distância até o ponto de coleta (origem)
            double latAtual = localizacao.getLatitude();
            double lonAtual = localizacao.getLongitude();
            double latColeta = pedido.getOrigemLatitude();
            double lonColeta = pedido.getOrigemLongitude();

            // Calcular distância usando Haversine
            double distanciaAteColeta = calculateDistanceInKm(latAtual, lonAtual, latColeta, lonColeta);

            // Se não houver mais distância, tempo é zero
            if (distanciaAteColeta <= 0.1) {
                return 0;
            }

            // Calcular tempo estimado usando velocidade média urbana (30 km/h = 0.5 km/min)
            double velocidadeMedia = 0.5; // km/min
            return (int) Math.ceil(distanciaAteColeta / velocidadeMedia);
        } else {
            // Para pedidos em rota, usar distância e tempo do pedido original
            int tempoTotalEstimado = pedido.getTempoEstimadoMinutos();
            double distanciaTotal = pedido.getDistanciaKm();

            // Velocidade média do trajeto origem → destino
            double velocidadeMedia = distanciaTotal / tempoTotalEstimado;

            // Tempo restante até o destino
            return (int) Math.ceil(distanciaRestante / velocidadeMedia);
        }
    }
}
