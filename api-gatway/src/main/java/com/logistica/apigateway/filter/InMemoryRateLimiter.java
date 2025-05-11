package com.logistica.apigateway.filter;

import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class InMemoryRateLimiter implements GatewayFilter, Ordered {

    private final Map<String, TokenBucket> buckets = new ConcurrentHashMap<>();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String ip = exchange.getRequest().getRemoteAddress().getAddress().getHostAddress();

        TokenBucket bucket = buckets.computeIfAbsent(ip, key -> new TokenBucket(100, 100, 60));

        if (!bucket.tryConsume(1)) {
            exchange.getResponse().setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
            return exchange.getResponse().setComplete();
        }

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }

    private static class TokenBucket {
        private final int capacity;
        private final double refillRate;
        private double tokens;
        private long lastRefill;

        public TokenBucket(int capacity, double tokensPerMinute, int refillPeriodInSeconds) {
            this.capacity = capacity;
            this.refillRate = tokensPerMinute / (60.0 / refillPeriodInSeconds);
            this.tokens = capacity;
            this.lastRefill = System.currentTimeMillis();
        }

        public synchronized boolean tryConsume(int toConsume) {
            refill();

            if (tokens < toConsume) {
                return false;
            }

            tokens -= toConsume;
            return true;
        }

        private void refill() {
            long now = System.currentTimeMillis();
            double secondsSinceLastRefill = (now - lastRefill) / 1000.0;
            double tokensToAdd = secondsSinceLastRefill * refillRate;

            if (tokensToAdd > 0) {
                tokens = Math.min(capacity, tokens + tokensToAdd);
                lastRefill = now;
            }
        }
    }
}
