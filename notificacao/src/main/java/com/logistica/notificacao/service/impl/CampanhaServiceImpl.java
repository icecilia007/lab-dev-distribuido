package com.logistica.notificacao.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.notificacao.dto.*;
import com.logistica.notificacao.exception.ServicoExternoException;
import com.logistica.notificacao.exception.ValidacaoException;
import com.logistica.notificacao.exception.RecursoNaoEncontradoException;
import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.service.CampanhaService;
import com.logistica.notificacao.service.NotificacaoService;
import com.logistica.notificacao.service.UsuarioServiceClient;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.ResourceAccessException;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Slf4j
public class CampanhaServiceImpl implements CampanhaService {

    private final RestTemplate restTemplate;
    private final UsuarioServiceClient usuarioServiceClient;
    private final ObjectMapper objectMapper;

    @Value("${aws.trigger.url}")
    private String lambdaUrl;

    private final NotificacaoService notificacaoService;
    public CampanhaServiceImpl(UsuarioServiceClient usuarioServiceClient, NotificacaoService notificacaoService) {
        this.notificacaoService = notificacaoService;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
        this.usuarioServiceClient = usuarioServiceClient;
    }

    @Override
    public ResponseEntity<String> enviarCampanha(CampanhaBasicaRequest campanhaBasica) {
        try {
            validarCampanhaBasica(campanhaBasica);

            List<ClienteResponse> clientes = usuarioServiceClient.buscarTodosClientes();
            log.info("Total de clientes encontrados: {}", clientes.size());

            if (clientes.isEmpty()) {
                log.warn("Nenhum cliente encontrado para envio da campanha: {}", campanhaBasica.getNome());
                throw new RecursoNaoEncontradoException("Nenhum cliente cadastrado encontrado para envio da campanha");
            }

            List<GrupoRequest> grupos = agruparClientesPorCategoria(clientes);
            log.info("Total de grupos criados: {}", grupos.size());

            TriggerRequest triggerRequest = montarTriggerRequest(campanhaBasica, grupos);

            try {
                String jsonCompleto = objectMapper.writeValueAsString(triggerRequest);
                log.info("=== JSON QUE SERÁ ENVIADO PARA LAMBDA ===");
                log.info(jsonCompleto);
                log.info("=== FIM DO JSON ===");
            } catch (Exception e) {
                log.warn("Erro ao serializar TriggerRequest para JSON: {}", e.getMessage());
            }

            logDetalhesGrupos(grupos);

            ResponseEntity<String> lambdaResponse = chamarLambdaAWS(triggerRequest);

            if (lambdaResponse.getStatusCode().is2xxSuccessful()) {
                criarNotificacoesParaClientes(campanhaBasica, grupos);
            }

            return lambdaResponse;

        } catch (ValidacaoException | RecursoNaoEncontradoException e) {
            log.error("Erro de validação/recurso na campanha '{}': {}", campanhaBasica.getNome(), e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Erro de validação: " + e.getMessage());

        } catch (ServicoExternoException e) {
            log.error("Erro em serviço externo durante campanha '{}': {}", campanhaBasica.getNome(), e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Serviço temporariamente indisponível: " + e.getMessage());

        } catch (Exception e) {
            log.error("Erro inesperado no processamento da campanha '{}': {}", campanhaBasica.getNome(), e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro interno do servidor: " + e.getMessage());
        }
    }

    private void validarCampanhaBasica(CampanhaBasicaRequest campanhaBasica) {
        Map<String, String> erros = new HashMap<>();

        if (campanhaBasica.getNome() == null || campanhaBasica.getNome().trim().isEmpty()) {
            erros.put("nome", "Nome da campanha é obrigatório");
        }
        if (campanhaBasica.getAssunto() == null || campanhaBasica.getAssunto().trim().isEmpty()) {
            erros.put("assunto", "Assunto da campanha é obrigatório");
        }
        if (campanhaBasica.getConteudo() == null || campanhaBasica.getConteudo().trim().isEmpty()) {
            erros.put("conteudo", "Conteúdo da campanha é obrigatório");
        }

        if (!erros.isEmpty()) {
            log.warn("Validação falhou para campanha com erros: {}", erros);
            throw new ValidacaoException("Dados da campanha inválidos", erros);
        }

        log.debug("Validação da campanha '{}' concluída com sucesso", campanhaBasica.getNome());
    }

    private List<GrupoRequest> agruparClientesPorCategoria(List<ClienteResponse> clientes) {
        List<ClienteResponse> clientesValidos = clientes.stream()
                .filter(this::isClienteValido)
                .toList();

        if (clientesValidos.isEmpty()) {
            log.warn("Nenhum cliente válido encontrado após aplicar filtros");
            return new ArrayList<>();
        }

        List<GrupoRequest> grupos = new ArrayList<>();

        List<ClienteRequest> clientesPremium = clientesValidos.stream()
                .filter(cliente -> "premium".equalsIgnoreCase(determinarCategoria(cliente)))
                .map(this::converterParaClienteRequest)
                .collect(Collectors.toList());

        if (!clientesPremium.isEmpty()) {
            grupos.add(new GrupoRequest("premium", clientesPremium));
            log.info("Grupo 'premium' criado com {} clientes de todas as regiões", clientesPremium.size());
        }

        List<ClienteRequest> clientesOutrosSul = clientesValidos.stream()
                .filter(cliente -> "outros".equalsIgnoreCase(determinarCategoria(cliente)))
                .filter(cliente -> "sul".equalsIgnoreCase(cliente.getRegiao()))
                .map(this::converterParaClienteRequest)
                .collect(Collectors.toList());

        if (!clientesOutrosSul.isEmpty()) {
            grupos.add(new GrupoRequest("regiao_sul", clientesOutrosSul));
            log.info("Grupo 'outros_sul' criado com {} clientes da região sul", clientesOutrosSul.size());
        }

        List<ClienteRequest> clientesOutrosOutrasRegioes = clientesValidos.stream()
                .filter(cliente -> "outros".equalsIgnoreCase(determinarCategoria(cliente)))
                .filter(cliente -> !"sul".equalsIgnoreCase(cliente.getRegiao()))
                .map(this::converterParaClienteRequest)
                .collect(Collectors.toList());

        if (!clientesOutrosOutrasRegioes.isEmpty()) {
            grupos.add(new GrupoRequest("outros", clientesOutrosOutrasRegioes));
            log.info("Grupo 'outros_demais_regioes' criado com {} clientes de regiões exceto sul", clientesOutrosOutrasRegioes.size());
        }

        return grupos;
    }


    private boolean isClienteValido(ClienteResponse cliente) {
        if (cliente == null) {
            log.debug("Cliente null encontrado - será filtrado");
            return false;
        }

        if (cliente.getId() == null) {
            log.debug("Cliente com ID null encontrado - será filtrado");
            return false;
        }

        if (cliente.getEmail() == null || cliente.getEmail().trim().isEmpty()) {
            log.debug("Cliente ID {} sem email válido - será filtrado", cliente.getId());
            return false;
        }

        if (cliente.getRegiao() == null || cliente.getRegiao().trim().isEmpty()) {
            log.debug("Cliente ID {} sem região válida - será filtrado", cliente.getId());
            return false;
        }

        return true;
    }

    private String determinarCategoria(ClienteResponse cliente) {
        String categoria = cliente.getCategoria();
        return (categoria != null && !categoria.trim().isEmpty()) ? categoria : "outros";
    }

    private TriggerRequest montarTriggerRequest(CampanhaBasicaRequest campanhaBasica, List<GrupoRequest> grupos) {
        TriggerRequest triggerRequest = new TriggerRequest();
        triggerRequest.setNome(campanhaBasica.getNome());
        triggerRequest.setAssunto(campanhaBasica.getAssunto());
        triggerRequest.setConteudo(campanhaBasica.getConteudo());
        triggerRequest.setGrupos(grupos);

        return triggerRequest;
    }

    private void logDetalhesGrupos(List<GrupoRequest> grupos) {
        log.info("=== DETALHES DOS GRUPOS DA CAMPANHA ===");
        grupos.forEach(grupo -> {
            log.info("Grupo '{}' - {} clientes:", grupo.getTipo(), grupo.getClientes().size());
            grupo.getClientes().forEach(cliente ->
                    log.debug("  - Cliente {}: {} ({})", cliente.getId(), cliente.getNome(), cliente.getRegiao())
            );
        });
        log.info("=== FIM DOS DETALHES DOS GRUPOS ===");
    }

    private ClienteRequest converterParaClienteRequest(ClienteResponse cliente) {
        return new ClienteRequest(
                cliente.getId().toString(),
                cliente.getNome(),
                cliente.getEmail(),
                cliente.getRegiao()
        );
    }

    private ResponseEntity<String> chamarLambdaAWS(TriggerRequest triggerRequest) {
        try {

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<TriggerRequest> entity = new HttpEntity<>(triggerRequest, headers);

            log.info("Enviando requisição para Lambda: {}", lambdaUrl);
            ResponseEntity<String> response = restTemplate.exchange(
                    lambdaUrl,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            log.info("Resposta recebida da AWS Lambda - Status: {}", response.getStatusCode());
            log.debug("Corpo da resposta Lambda: {}", response.getBody());

            return response;
        } catch (RestClientException e) {
            log.error("Erro REST ao chamar Lambda: {}", e.getMessage(), e);
            throw e;
        } catch (Exception e) {
            log.error("Erro inesperado ao chamar Lambda: {}", e.getMessage(), e);
            throw new ServicoExternoException("Erro inesperado na comunicação com Lambda", e);
        }
    }

    private void criarNotificacoesParaClientes(CampanhaBasicaRequest campanhaBasica, List<GrupoRequest> grupos) {
        log.info("Criando notificações para clientes da campanha: {}", campanhaBasica.getNome());

        for (GrupoRequest grupo : grupos) {
            for (ClienteRequest cliente : grupo.getClientes()) {
                try {
                    Notificacao notificacao = new Notificacao();
                    notificacao.setTipoEvento("CAMPANHA_MARKETING");
                    notificacao.setOrigem("CAMPANHAS_SERVICE");
                    notificacao.setDestinatarioId(Long.valueOf(cliente.getId()));
                    notificacao.setTitulo(campanhaBasica.getAssunto());
                    notificacao.setMensagem(campanhaBasica.getConteudo());
                    notificacao.setDataCriacao(LocalDateTime.now());
                    notificacao.setStatus(Notificacao.StatusNotificacao.NAO_LIDA);

                    Map<String, Object> dadosEvento = new HashMap<>();
                    dadosEvento.put("nome", campanhaBasica.getNome());
                    dadosEvento.put("assunto", campanhaBasica.getAssunto());
                    dadosEvento.put("conteudo", campanhaBasica.getConteudo());
                    notificacao.setDadosEvento(dadosEvento);

                    notificacaoService.salvar(notificacao);

                } catch (Exception e) {
                    log.warn("Erro ao criar notificação para cliente {}: {}", cliente.getId(), e.getMessage());
                }
            }
        }

        log.info("Notificações criadas com sucesso para campanha: {}", campanhaBasica.getNome());
    }
}
