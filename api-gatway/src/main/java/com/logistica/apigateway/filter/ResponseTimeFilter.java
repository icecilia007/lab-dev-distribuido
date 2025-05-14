package com.logistica.apigateway.filter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

@Component
public class ResponseTimeFilter implements GlobalFilter, Ordered {

    private static final Logger logger = LoggerFactory.getLogger(ResponseTimeFilter.class);

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        // Registra o tempo de início da requisição
        long startTime = System.currentTimeMillis();

        // Adiciona um hook para executar após a requisição ser processada
        return chain.filter(exchange).then(Mono.fromRunnable(() -> {
            long endTime = System.currentTimeMillis();
            long duration = endTime - startTime;

            // Adiciona o header X-Response-Time na resposta
            exchange.getResponse().getHeaders().add("X-Response-Time", duration + "ms");

            // Opcionalmente, registra o tempo no log
            String path = exchange.getRequest().getURI().getPath();
            logger.info("Request to {} took {} ms", path, duration);
        }));
    }

    @Override
    public int getOrder() {
        // Define a prioridade do filtro (mais baixa = executa primeiro)
        return Ordered.LOWEST_PRECEDENCE;
    }
}