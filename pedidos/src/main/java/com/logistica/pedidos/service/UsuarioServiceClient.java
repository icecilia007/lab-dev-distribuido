package com.logistica.pedidos.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

@Component
public class UsuarioServiceClient {
    private final RestTemplate restTemplate;
    private final String usuarioServiceUrl;

    public UsuarioServiceClient(@Value("${services.usuario.url}") String usuarioServiceUrl) {
        this.restTemplate = new RestTemplate();
        this.usuarioServiceUrl = usuarioServiceUrl;
    }

    public Object buscarUsuarioPorTipoEId(String tipoUsuario, Long id) {
        return restTemplate.getForObject(
                usuarioServiceUrl + "/api/usuarios/{tipoUsuario}/{id}",
                Object.class,
                tipoUsuario,
                id
        );
    }
}

