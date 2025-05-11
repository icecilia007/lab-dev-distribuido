package com.logistica.pedidos.service;

import com.logistica.pedidos.dto.MotoristaProximoDTO;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;


@Service
public class RastreamentoServiceClient {

    private final RestTemplate restTemplate;
    private final String rastreamentoServiceUrl;
    private final String secretHeaderName;
    private final String secretHeaderValue;

    public RastreamentoServiceClient(
            @Value("${services.rastreamento.url}") String rastreamentoServiceUrl,
            @Value("${security.internal.header-name:X-Internal-Auth}") String secretHeaderName,
            @Value("${security.internal.header-value}") String secretHeaderValue) {
        this.secretHeaderName = secretHeaderName;
        this.secretHeaderValue = secretHeaderValue;
        this.restTemplate = new RestTemplate();
        this.rastreamentoServiceUrl = rastreamentoServiceUrl;
    }

    public List<MotoristaProximoDTO> buscarMotoristasProximosOrigem(Double latitude, Double longitude) {
        String url = String.format("%s/api/rastreamento/motoristas/proximos?latitude=%s&longitude=%s&raioKm=5.0",
                rastreamentoServiceUrl, latitude, longitude);

        HttpHeaders headers = new HttpHeaders();
        headers.set(secretHeaderName, secretHeaderValue);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        return restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                new ParameterizedTypeReference<List<MotoristaProximoDTO>>() {}
        ).getBody();
    }
}
