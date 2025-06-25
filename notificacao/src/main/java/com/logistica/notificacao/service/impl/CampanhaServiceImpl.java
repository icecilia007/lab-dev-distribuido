package com.logistica.notificacao.service.impl;

import com.logistica.notificacao.dto.*;
import com.logistica.notificacao.service.CampanhaService;
import com.logistica.notificacao.service.UsuarioServiceClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;

import java.util.*;
import java.util.stream.Collectors;

@Service
public class CampanhaServiceImpl implements CampanhaService {


    private final RestTemplate restTemplate;
    private final UsuarioServiceClient usuarioServiceClient;

    @Value("${aws.trigger.url}")
    private String lambdaUrl;

    public CampanhaServiceImpl(UsuarioServiceClient usuarioServiceClient) {
        this.restTemplate = new RestTemplate();
        this.usuarioServiceClient = usuarioServiceClient;
    }

    public ResponseEntity<String> enviarCampanha(CampanhaBasicaRequest campanhaBasica) {

        System.out.println("Iniciando processamento da campanha: " + campanhaBasica.getNome());

        try {
            List<ClienteResponse> clientes = usuarioServiceClient.buscarTodosClientes();
            System.out.println("Total de clientes encontrados: " + clientes.size());

            List<GrupoRequest> grupos = agruparClientesPorCategoria(clientes);
            System.out.println("Total de grupos criados: " + grupos.size());

            TriggerRequest triggerRequest = new TriggerRequest();
            triggerRequest.setNome(campanhaBasica.getNome());
            triggerRequest.setAssunto(campanhaBasica.getAssunto());
            triggerRequest.setConteudo(campanhaBasica.getConteudo());
            triggerRequest.setGrupos(grupos);

            System.out.println("Payload completo montado para envio à AWS Lambda");
            grupos.forEach(grupo ->
                    System.out.println("Grupo '" + grupo.getTipo() + "' com " + grupo.getClientes().size() + " clientes")
            );

            return chamarLambdaAWS(triggerRequest);

        } catch (Exception e) {
            System.err.println("Erro geral no processamento da campanha: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro ao processar campanha: " + e.getMessage());
        }
    }

    private List<GrupoRequest> agruparClientesPorCategoria(List<ClienteResponse> clientes) {
        List<ClienteResponse> clientesValidos = clientes.stream()
                .filter(cliente -> cliente.getRegiao() != null && !cliente.getRegiao().trim().isEmpty())
                .collect(Collectors.toList());

        System.out.println("Clientes com região válida: " + clientesValidos.size());

        Map<String, List<ClienteRequest>> clientesPorCategoria = clientesValidos.stream()
                .collect(Collectors.groupingBy(
                        cliente -> {
                            String categoria = cliente.getCategoria();
                            return (categoria != null && !categoria.trim().isEmpty()) ? categoria : "outros";
                        },
                        Collectors.mapping(this::converterParaClienteRequest, Collectors.toList())
                ));

        clientesPorCategoria.forEach((categoria, listaClientes) ->
                System.out.println("Categoria '" + categoria + "': " + listaClientes.size() + " clientes")
        );

        return clientesPorCategoria.entrySet().stream()
                .map(entry -> new GrupoRequest(entry.getKey(), entry.getValue()))
                .collect(Collectors.toList());
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
            System.out.println("Enviando campanha para AWS Lambda: " + lambdaUrl);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("User-Agent", "Sistema-Logistica-Campanhas/1.0");

            HttpEntity<TriggerRequest> entity = new HttpEntity<>(triggerRequest, headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    lambdaUrl,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            System.out.println("Resposta da AWS Lambda - Status: " + response.getStatusCode());
            System.out.println("Resposta da AWS Lambda - Body: " + response.getBody());

            return response;

        } catch (RestClientException e) {
            System.err.println("Erro de comunicação com AWS Lambda: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("Erro ao comunicar com AWS Lambda: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("Erro inesperado ao chamar AWS Lambda: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Erro interno ao enviar campanha: " + e.getMessage());
        }
    }
}
