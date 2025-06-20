package com.logistica.apigateway.config;

import com.logistica.apigateway.filter.JwtAuthenticationFilter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.web.reactive.EnableWebFluxSecurity;
import org.springframework.security.config.web.server.ServerHttpSecurity;
import org.springframework.security.web.server.SecurityWebFilterChain;
import org.springframework.security.web.server.context.NoOpServerSecurityContextRepository;
import org.springframework.web.server.ServerWebExchange;
import org.springframework.web.server.WebFilter;
import org.springframework.security.config.web.server.SecurityWebFiltersOrder;
import reactor.core.publisher.Mono;

import java.util.List;

@Configuration
@EnableWebFluxSecurity
public class SecurityConfig {
    private static final Logger log = LoggerFactory.getLogger(SecurityConfig.class);

    @Bean
    public List<String> publicPathsArray() {
        return List.of(
                "/api/auth/login",
                "/api/auth/registro/**",
                "/api/auth/registro",
                "/api/usuarios/clientes",
                "/api/usuarios/motoristas",
                "/api/usuarios/operadores",
                "/api/usuarios/login",
                "/actuator/",
                "/swagger-ui/",
                "/swagger-ui.html",
                "/api-docs/",
                "/api-docs",
                "/api-docs**",
                "/swagger-resources/**",
                "/webjars/**",
                "/favicon.ico",
                "/.well-known",
                "/.well-known/appspecific/com.chrome.devtools.json"
        );
    }

    @Bean
    public JwtAuthenticationFilter jwtAuthenticationFilter(
            @Value("${security.jwt.secret}") String jwtSecret) {
        return new JwtAuthenticationFilter(jwtSecret, publicPathsArray());
    }

    @Bean
    public SecurityWebFilterChain securityWebFilterChain(
            ServerHttpSecurity http,
            JwtAuthenticationFilter jwtAuthenticationFilter) {

        log.info("Configurando cadeia de filtros de segurança com JWT");

        WebFilter jwtFilter = (exchange, chain) -> {
            log.debug("Aplicando JwtAuthenticationFilter através do WebFilter");
            return jwtAuthenticationFilter.filter(exchange, new GatewayFilterChain() {
                @Override
                public Mono<Void> filter(ServerWebExchange exchange) {
                    return chain.filter(exchange);
                }
            });
        };

        return http
                .csrf(ServerHttpSecurity.CsrfSpec::disable)
                .addFilterAt(jwtFilter, SecurityWebFiltersOrder.AUTHENTICATION)
                .securityContextRepository(NoOpServerSecurityContextRepository.getInstance())
                .authorizeExchange(exchanges -> exchanges
                        .pathMatchers(publicPathsArray().toArray(String[]::new)).permitAll()
                        .anyExchange().authenticated()
                )
                .httpBasic(ServerHttpSecurity.HttpBasicSpec::disable)
                .formLogin(ServerHttpSecurity.FormLoginSpec::disable)
                .exceptionHandling(exceptionHandlingSpec ->
                        exceptionHandlingSpec.authenticationEntryPoint(
                                (exchange, ex) -> {
                                    log.error("Erro de autenticação: {}", ex.getMessage());
                                    exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
                                    return exchange.getResponse().writeWith(
                                            Mono.just(exchange.getResponse().bufferFactory()
                                                    .wrap("Não autorizado".getBytes()))
                                    );
                                }
                        )
                )
                .build();
    }
}
