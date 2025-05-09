package com.logistica.pedidos.config;

import com.fasterxml.jackson.databind.JsonNode;
import com.logistica.pedidos.dto.RotaResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

/**
 * Cliente para interagir com a API do OSRM (Open Source Routing Machine).
 */
@Component
public class OSRMClient {

    private final RestTemplate restTemplate;
    private final String osrmBaseUrl;

    public OSRMClient(@Value("${services.osrm.base-url}") String osrmBaseUrl) {
        this.restTemplate = new RestTemplate();
        this.osrmBaseUrl = osrmBaseUrl;
    }

    public RotaResponse calcularRota(String origemLat,String origemLon, String destinoLat, String destinoLon) {
        String url = String.format("%s/route/v1/driving/%s,%s;%s,%s?overview=full&geometries=geojson",
                osrmBaseUrl, origemLon, origemLat, destinoLon, destinoLat);
        try {
            // Utilizando overview=full para obter a rota completa e geometries=geojson para a geometria em GeoJSON
            ResponseEntity<JsonNode> response = restTemplate.getForEntity(url, JsonNode.class);


            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                JsonNode rootNode = response.getBody();

                if (!rootNode.has("routes")) {
                    throw new RuntimeException("Erro ao calcular rota: resposta inválida do OSRM");
                }

                if (!"Ok".equals(rootNode.path("code").asText())) {
                    throw new RuntimeException("Erro ao calcular rota: código de resposta inválido");
                }

                JsonNode routeNode = rootNode.path("routes").path(0);
                double distanceKm = routeNode.path("distance").asDouble() / 1000;
                int durationMinutes = (int) (routeNode.path("duration").asDouble() / 60);

                JsonNode geometry = routeNode.path("geometry");

                return new RotaResponse(distanceKm, durationMinutes, geometry);
            } else {
                throw new RuntimeException("Erro ao calcular rota: erro ao consultar API de rotas");
            }
        } catch (Exception e) {
            throw new RuntimeException("Exceção ao consultar API: "+ e.getMessage());
        }
    }
}
