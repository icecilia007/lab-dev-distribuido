package com.logistica.apigateway.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/fallback")
public class FallbackController {

    @GetMapping("/usuario")
    public ResponseEntity<Map<String, Object>> usuarioFallback() {
        return createFallbackResponse("Serviço de Usuários indisponível");
    }

    @GetMapping("/pedido")
    public ResponseEntity<Map<String, Object>> pedidoFallback() {
        return createFallbackResponse("Serviço de Pedidos indisponível");
    }

    @GetMapping("/rastreamento")
    public ResponseEntity<Map<String, Object>> rastreamentoFallback() {
        return createFallbackResponse("Serviço de Rastreamento indisponível");
    }

    @GetMapping("/notificacao")
    public ResponseEntity<Map<String, Object>> notificacaoFallback() {
        return createFallbackResponse("Serviço de Notificações indisponível");
    }

    private ResponseEntity<Map<String, Object>> createFallbackResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("timestamp", LocalDateTime.now().toString());
        response.put("status", HttpStatus.SERVICE_UNAVAILABLE.value());
        response.put("mensagem", message);

        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(response);
    }
}
