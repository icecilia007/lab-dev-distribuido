package com.logistica.pedidos.config;

import com.fasterxml.jackson.core.JsonProcessingException;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.http.*;
import org.springframework.web.client.*;
import org.springframework.stereotype.*;
import com.fasterxml.jackson.databind.*;
import java.util.*;
import java.util.concurrent.*;

@Service
public class NominatimClient {

    private final RestTemplate restTemplate;
    private final Map<String, String> cacheEnderecos;
    private static final String NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse";

    public NominatimClient(RestTemplateBuilder restTemplateBuilder) {
        this.restTemplate = restTemplateBuilder.build();
        this.cacheEnderecos = new ConcurrentHashMap<>();

        this.restTemplate.setInterceptors(Collections.singletonList((request, body, execution) -> {
            request.getHeaders().set("User-Agent", "SeuApp/1.0 (contato@exemplo.com)");
            request.getHeaders().set(HttpHeaders.ACCEPT, MediaType.APPLICATION_JSON_VALUE);
            return execution.execute(request, body);
        }));
    }

    /**
     * Converte latitude/longitude em um endereço formatado.
     * @param latitude Latitude do local.
     * @param longitude Longitude do local.
     * @return Endereço no formato "Rua, Número - Cidade/UF" ou mensagem de fallback.
     */
    public String getEndereco(Double latitude, Double longitude) {
        String chaveCache = String.format("%s,%s", latitude, longitude);

        // Verifica cache antes de chamar a API
        if (cacheEnderecos.containsKey(chaveCache)) {
            return cacheEnderecos.get(chaveCache);
        }

        try {
            Map<String, String> params = new HashMap<>();
            params.put("format", "json");
            params.put("lat", latitude.toString());
            params.put("lon", longitude.toString());
            params.put("addressdetails", "1");
            params.put("zoom", "18"); // Nível de detalhe (rua/número)

            ResponseEntity<String> response = restTemplate.exchange(
                    NOMINATIM_URL + "?format={format}&lat={lat}&lon={lon}&addressdetails={addressdetails}&zoom={zoom}",
                    HttpMethod.GET,
                    null,
                    String.class,
                    params
            );

            if (response.getStatusCode() == HttpStatus.OK && response.getBody() != null) {
                String enderecoFormatado = parseEndereco(response.getBody());
                cacheEnderecos.put(chaveCache, enderecoFormatado); // Atualiza cache
                return enderecoFormatado;
            }

        } catch (HttpClientErrorException e) {
            System.err.println("Erro na requisição Nominatim: " + e.getMessage());
        } catch (RestClientException e) {
            System.err.println("Falha ao acessar Nominatim: " + e.getMessage());
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }

        return "Endereço não encontrado";
    }

    /**
     * Extrai e formata o endereço do JSON retornado pelo Nominatim.
     */
    private String parseEndereco(String jsonResponse) throws JsonProcessingException {
        ObjectMapper mapper = new ObjectMapper();
        JsonNode root = mapper.readTree(jsonResponse);
        JsonNode address = root.path("address");

        String rua = address.path("road").asText("Rua desconhecida");
        String numero = address.path("house_number").asText("S/N");
        String cidade = address.path("city").asText(address.path("town").asText("Cidade desconhecida"));
        String estado = address.path("state").asText("UF desconhecida");

        return String.format("%s, %s - %s/%s", rua, numero, cidade, estado);
    }
}