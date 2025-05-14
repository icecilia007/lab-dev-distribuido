package com.logistica.rastreamento.service;

import com.logistica.rastreamento.dto.AtualizarStatusRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;


@Service
public class PedidoServiceClient {

    private final RestTemplate restTemplate;
    private final String pedidoServiceUrl;
    private final String secretHeaderName;
    private final String secretHeaderValue;

    public PedidoServiceClient(@Value("${services.pedido.url}") String pedidoServiceUrl,
                               @Value("${security.internal.header-name:X-Internal-Auth}") String secretHeaderName,
                               @Value("${security.internal.header-value}") String secretHeaderValue) {
        HttpComponentsClientHttpRequestFactory requestFactory = new HttpComponentsClientHttpRequestFactory();
        this.restTemplate = new RestTemplate(requestFactory);
        this.secretHeaderName = secretHeaderName;
        this.secretHeaderValue = secretHeaderValue;
        this.pedidoServiceUrl = pedidoServiceUrl;
    }


    public Object buscarPedidoPorId(Long id) {
        HttpHeaders headers = new HttpHeaders();
        headers.set(secretHeaderName, secretHeaderValue);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        return restTemplate.exchange(
                pedidoServiceUrl + "/api/pedidos/{id}",
                HttpMethod.GET,
                entity,
                Object.class,
                id
        ).getBody();
    }

    public void atualizarStatusPedido(Long id, AtualizarStatusRequest request) {
        HttpHeaders headers = new HttpHeaders();
        headers.set(secretHeaderName, secretHeaderValue);
        HttpEntity<AtualizarStatusRequest> entity = new HttpEntity<>(request, headers);

        restTemplate.exchange(
                pedidoServiceUrl + "/api/pedidos/{id}/status",
                HttpMethod.PATCH,
                entity,
                Void.class,
                id
        );
    }
}
