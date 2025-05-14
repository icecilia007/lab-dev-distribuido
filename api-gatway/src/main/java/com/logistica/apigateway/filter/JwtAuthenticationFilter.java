package com.logistica.apigateway.filter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.ReactiveSecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Component
public class JwtAuthenticationFilter implements GlobalFilter, Ordered {

    private static final Logger log = LoggerFactory.getLogger(JwtAuthenticationFilter.class);
    private static final String BEARER_PREFIX = "Bearer ";
    private static final String AUTH_HEADER = "Authorization";

    private final String jwtSecret;
    private final List<String> publicPaths;

    public JwtAuthenticationFilter(
            @Value("${security.jwt.secret}") String jwtSecret, List<String> publicPaths) {
        this.jwtSecret = jwtSecret;
        this.publicPaths = publicPaths;
        log.info("JwtAuthenticationFilter inicializado com {} caminhos públicos",
                publicPaths != null ? publicPaths.size() : 0);
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        ServerHttpRequest request = exchange.getRequest();
        String path = request.getPath().toString();

        log.debug("JwtAuthFilter - Processando requisição para: {}", path);

        // Verificar se o caminho é público
        if (isPublicPath(path)) {
            log.debug("JwtAuthFilter - Caminho público: {}, permitindo acesso", path);
            return chain.filter(exchange);
        }

        // Verificar se o header de autorização existe
        if (!request.getHeaders().containsKey(AUTH_HEADER)) {
            log.error("JwtAuthFilter - Header Authorization ausente para: {}", path);
            return onError(exchange, "Authorization header ausente", HttpStatus.UNAUTHORIZED);
        }

        // Extrair e verificar o token JWT
        String token = extractToken(request);
        if (token == null) {
            log.error("JwtAuthFilter - Token não encontrado no header Authorization");
            return onError(exchange, "Token JWT inválido ou ausente", HttpStatus.UNAUTHORIZED);
        }

        try {
            log.debug("JwtAuthFilter - Validando token JWT");

            // Validar o token
            Claims claims = extractClaims(token);

            // Adicionar informações do usuário ao request
            ServerHttpRequest mutatedRequest = mutateRequestWithUserInfo(request, claims);

            // Criar Authentication e adicionar ao contexto
            List<GrantedAuthority> authorities = extractAuthorities(claims);
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(claims.getSubject(), null, authorities);

            return chain.filter(exchange.mutate().request(mutatedRequest).build())
                    .contextWrite(ReactiveSecurityContextHolder.withAuthentication(authentication));

        } catch (Exception e) {
            log.error("JwtAuthFilter - Erro ao validar token: {}", e.getMessage());
            return onError(exchange, "Token inválido", HttpStatus.UNAUTHORIZED);
        }
    }

    private boolean isPublicPath(String path) {
        if (publicPaths == null) return false;

        for (String publicPath : publicPaths) {
            // Verificar correspondência exata
            if (path.equals(publicPath)) {
                return true;
            }

            // Verificar padrões com curinga
            if (publicPath.endsWith("/**")) {
                String basePath = publicPath.substring(0, publicPath.length() - 2);
                if (path.startsWith(basePath)) {
                    return true;
                }
            }

            // Verificar outros padrões (retrocompatibilidade)
            if (publicPath.endsWith("/") && path.startsWith(publicPath)) {
                return true;
            }
        }

        return false;
    }

    private String extractToken(ServerHttpRequest request) {
        List<String> authHeaders = request.getHeaders().get(AUTH_HEADER);
        if (authHeaders != null && !authHeaders.isEmpty()) {
            String authHeader = authHeaders.get(0);
            if (authHeader.startsWith(BEARER_PREFIX)) {
                return authHeader.substring(BEARER_PREFIX.length());
            }
        }
        return null;
    }

    private Claims extractClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8)))
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    private List<GrantedAuthority> extractAuthorities(Claims claims) {
        List<String> roles = claims.get("roles", List.class);
        if (roles != null) {
            return roles.stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .collect(Collectors.toList());
        }
        return new ArrayList<>();
    }

    private ServerHttpRequest mutateRequestWithUserInfo(ServerHttpRequest request, Claims claims) {
        String username = claims.getSubject();
        String userId = claims.get("userId", String.class);
        List<String> roles = claims.get("roles", List.class);

        return request.mutate()
                .header("X-Auth-User-Id", userId)
                .header("X-Auth-Username", username)
                .header("X-Auth-Roles", roles != null ? String.join(",", roles) : "")
                .build();
    }

    private Mono<Void> onError(ServerWebExchange exchange, String message, HttpStatus status) {
        ServerHttpResponse response = exchange.getResponse();
        response.setStatusCode(status);
        response.getHeaders().add(HttpHeaders.CONTENT_TYPE, "application/json");

        String errorJson = String.format("{\"error\":\"%s\"}", message);
        byte[] bytes = errorJson.getBytes(StandardCharsets.UTF_8);

        return response.writeWith(Mono.just(response.bufferFactory().wrap(bytes)));
    }

    @Override
    public int getOrder() {
        return -100; // Alta prioridade para executar antes dos filtros de segurança
    }
}
