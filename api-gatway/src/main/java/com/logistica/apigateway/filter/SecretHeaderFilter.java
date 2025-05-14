package com.logistica.apigateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class SecretHeaderFilter implements GlobalFilter {

    @Value("${security.internal.header-name}")
    private String secretHeaderName;

    @Value("${security.internal.header-value}")
    private String secretHeaderValue;

    private static final Logger log = LoggerFactory.getLogger(SecretHeaderFilter.class);

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        log.info("SecretHeaderFilter - Adicionando header X-Internal-Auth para requisição: {}",exchange.getRequest().getPath());
        return chain.filter(
                exchange.mutate()
                        .request(
                                exchange.getRequest().mutate()
                                        .header(secretHeaderName, secretHeaderValue)
                                        .build()
                        )
                        .build()
        );
    }
}
