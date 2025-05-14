package com.logistica.apigateway.config;

import com.logistica.apigateway.filter.InMemoryRateLimiter;
import com.logistica.apigateway.filter.SimpleCacheFilter;
import com.logistica.apigateway.filter.SecretHeaderFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class GatewayConfig {

    private final InMemoryRateLimiter rateLimiter;

    private final SimpleCacheFilter cacheFilter;


    @Value("${services.auth.url}")
    private String authServiceUrl;

    @Value("${services.usuario.url}")
    private String usuarioServiceUrl;

    @Value("${services.pedido.url}")
    private String pedidoServiceUrl;

    @Value("${services.rastreamento.url}")
    private String rastreamentoServiceUrl;

    @Value("${services.notificacao.url}")
    private String notificacaoServiceUrl;

    public GatewayConfig(InMemoryRateLimiter rateLimiter, SimpleCacheFilter cacheFilter) {
        this.rateLimiter = rateLimiter;
        this.cacheFilter = cacheFilter;
    }

    @Bean
    public RouteLocator customRouteLocator(RouteLocatorBuilder builder) {
        return builder.routes()
                .route("auth-service", r -> r
                        .path("/api/auth/**")
                        .filters(f -> f
                                .filter(rateLimiter)
                        )
                        .uri(authServiceUrl))
                // Serviço de Usuários
                .route("usuario-service", r -> r
                        .path("/api/usuarios/**")
                        .filters(f -> f
                                .filter(rateLimiter)
                                .filter(cacheFilter)
                        )
                        .uri(usuarioServiceUrl))

                // Serviço de Pedidos
                .route("pedido-service", r -> r
                        .path("/api/pedidos/**")
                        .filters(f -> f
                                .filter(rateLimiter)
                                .filter(cacheFilter)
                        )
                        .uri(pedidoServiceUrl))

                // Serviço de Rastreamento
                .route("rastreamento-service", r -> r
                        .path("/api/rastreamento/**")
                        .filters(f -> f
                                .filter(rateLimiter)
                                .filter(cacheFilter)
                        )
                        .uri(rastreamentoServiceUrl))

                // Serviço de Incidentes
                .route("incidente-service", r -> r
                        .path("/api/incidentes/**")
                        .filters(f -> f
                                .filter(rateLimiter)
                                .filter(cacheFilter)
                        )
                        .uri(rastreamentoServiceUrl))

                // Serviço de Notificações
                .route("notificacao-service", r -> r
                        .path("/api/notificacoes/**")
                        .filters(f -> f
                                .filter(rateLimiter)
                                .filter(cacheFilter)
                        )
                        .uri(notificacaoServiceUrl))
                .build();
    }
}
