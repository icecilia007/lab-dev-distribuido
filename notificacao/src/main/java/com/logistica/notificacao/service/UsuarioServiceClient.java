package com.logistica.notificacao.service;

import com.logistica.notificacao.dto.ClienteResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;

@Component
public class UsuarioServiceClient {

    private final RestTemplate restTemplate;
    private final String usuarioServiceUrl;
    private final String secretHeaderName;
    private final String secretHeaderValue;

    public UsuarioServiceClient(
            @Value("${services.usuario.url}") String usuarioServiceUrl,
            @Value("${security.internal.header-name:X-Internal-Auth}") String secretHeaderName,
            @Value("${security.internal.header-value}") String secretHeaderValue) {
        this.restTemplate = new RestTemplate();
        this.usuarioServiceUrl = usuarioServiceUrl;
        this.secretHeaderName = secretHeaderName;
        this.secretHeaderValue = secretHeaderValue;
    }

    public List<ClienteResponse> buscarTodosClientes() {
        HttpHeaders headers = new HttpHeaders();
        headers.set(secretHeaderName, secretHeaderValue);
        headers.set("Content-Type", "application/json");
        HttpEntity<String> entity = new HttpEntity<>(headers);

        return restTemplate.exchange(
                usuarioServiceUrl + "/api/usuarios/clientes",
                HttpMethod.GET,
                entity,
                new ParameterizedTypeReference<List<ClienteResponse>>() {}
        ).getBody();
    }
}
