package com.logistica.rastreamento.service;

import com.logistica.rastreamento.dto.AtualizarStatusRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.client.HttpComponentsClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;


@Service
public class PedidoServiceClient {

    private final RestTemplate restTemplate;
    private final String pedidoServiceUrl;

    public PedidoServiceClient(@Value("${services.pedido.url}") String pedidoServiceUrl) {
        // Configure RestTemplate com suporte a PATCH
        HttpComponentsClientHttpRequestFactory requestFactory = new HttpComponentsClientHttpRequestFactory();
        this.restTemplate = new RestTemplate(requestFactory);
        this.pedidoServiceUrl = pedidoServiceUrl;
    }


    public Object buscarPedidoPorId(Long id) {
        return restTemplate.getForObject(pedidoServiceUrl + "/api/pedidos/{id}", Object.class, id);
    }

    public void atualizarStatusPedido(Long id, AtualizarStatusRequest atualizarStatusRequest) {
        restTemplate.patchForObject(
                pedidoServiceUrl + "/api/pedidos/{id}/status",
                atualizarStatusRequest,
                Object.class,
                id
        );
    }
}
