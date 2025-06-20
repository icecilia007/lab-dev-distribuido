package com.logistica.apigateway.controller;

import com.logistica.apigateway.controller.dto.LoginRequest;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Date;
import java.util.Map;

@RestController
@CrossOrigin(origins = "*")
@RequestMapping("/api/auth")
public class AuthController {

    private final String jwtSecret;
    private final long jwtExpiration;
    private final WebClient webClient;
    private final String usuarioServiceUrl;

    public AuthController(
            WebClient.Builder webClientBuilder,
            @Value("${security.jwt.secret}") String jwtSecret,
            @Value("${security.jwt.expiration:86400}") long jwtExpiration,
            @Value("${security.internal.header-name}") String secretHeaderName,
            @Value("${security.internal.header-value}") String secretHeaderValue,
            @Value("${services.usuario.url:http://localhost:8080}") String usuarioServiceUrl) {

        this.jwtSecret = jwtSecret;
        this.jwtExpiration = jwtExpiration;
        this.usuarioServiceUrl = usuarioServiceUrl;
        this.webClient = webClientBuilder
                .defaultHeader(secretHeaderName, secretHeaderValue)
                .build();
    }

    @PostMapping("/login")
    public Mono<ResponseEntity<?>> login(@RequestBody Mono<LoginRequest> loginRequest) {
        return loginRequest.flatMap(request ->
                webClient.post()
                        .uri(usuarioServiceUrl + "/api/usuarios/login")
                        .bodyValue(request)
                        .retrieve()
                        .bodyToMono(Map.class)
                        .map(userData -> {
                            String token = generateToken(userData);
                            return ResponseEntity.ok()
                                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                                    .body(userData);
                        })
                        .onErrorResume(e -> {
                            e.printStackTrace();
                            return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
                        })
        );
    }

    @PostMapping("/registro/cliente")
    public Mono<ResponseEntity<?>> registrarCliente(@RequestBody Mono<Map<String, Object>> clienteRequest) {
        return clienteRequest.flatMap(request -> webClient.post()
                .uri(usuarioServiceUrl + "/api/usuarios/clientes")
                .bodyValue(request)
                .retrieve()
                .bodyToMono(Map.class)
                .map(userData -> {
                    String token = generateToken(userData);
                    return ResponseEntity.status(HttpStatus.CREATED)
                            .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                            .body(userData);
                })
                .onErrorResume(e -> {
                    e.printStackTrace();
                    return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
                })
        );
    }

    @PostMapping("/registro/motorista")
    public Mono<ResponseEntity<?>> registrarMotorista(@RequestBody Mono<Map<String, Object>> motoristaRequest) {
        return motoristaRequest.flatMap(request -> {
            return webClient.post()
                    .uri(usuarioServiceUrl + "/api/usuarios/motoristas")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .map(userData -> {
                        String token = generateToken(userData);
                        return ResponseEntity.status(HttpStatus.CREATED)
                                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                                .body(userData);
                    }).onErrorResume(e -> {
                        e.printStackTrace();
                        return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
                    });
        });
    }

    @PostMapping("/registro/operador")
    public Mono<ResponseEntity<?>> registrarOperador(@RequestBody Mono<Map<String, Object>> operadorRequest) {
        return operadorRequest.flatMap(request -> {
            return webClient.post()
                    .uri(usuarioServiceUrl + "/api/usuarios/operadores")
                    .bodyValue(request)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .map(userData -> {
                        String token = generateToken(userData);
                        return ResponseEntity.status(HttpStatus.CREATED)
                                .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                                .body(userData);
                    }).onErrorResume(e -> {
                        e.printStackTrace();
                        return Mono.just(ResponseEntity.status(HttpStatus.UNAUTHORIZED).build());
                    });
        });
    }

    private String generateToken(Map<String, Object> userData) {
        long now = System.currentTimeMillis();

        return Jwts.builder()
                .setSubject(userData.get("email").toString())
                .claim("userId", userData.get("id").toString())
                .claim("roles", Arrays.asList(userData.get("tipo").toString()))
                .setIssuedAt(new Date(now))
                .setExpiration(new Date(now + jwtExpiration * 1000))
                .signWith(Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8)))
                .compact();
    }
}
