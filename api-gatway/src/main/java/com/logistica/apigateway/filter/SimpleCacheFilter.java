package com.logistica.apigateway.filter;

import org.reactivestreams.Publisher;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.http.server.reactive.ServerHttpResponseDecorator;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.io.ByteArrayOutputStream;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SimpleCacheFilter implements GatewayFilter, Ordered {

    private final Map<String, CachedResponse> cache = new ConcurrentHashMap<>();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        if (!HttpMethod.GET.equals(exchange.getRequest().getMethod())) {
            return chain.filter(exchange);
        }

        String cacheKey = exchange.getRequest().getURI().toString();
        CachedResponse cachedResponse = cache.get(cacheKey);

        if (cachedResponse != null && !cachedResponse.isExpired()) {
            ServerHttpResponse response = exchange.getResponse();
            response.setStatusCode(cachedResponse.getStatusCode());
            response.getHeaders().putAll(cachedResponse.getHeaders());

            DataBuffer buffer = response.bufferFactory().wrap(cachedResponse.getBody());
            return response.writeWith(Mono.just(buffer));
        }

        ServerWebExchange mutatedExchange = exchange.mutate()
                .response(new CachingServerHttpResponseDecorator(exchange, cacheKey, cache))
                .build();

        return chain.filter(mutatedExchange);
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE + 10;
    }

    private static class CachedResponse {
        private final HttpStatus statusCode;
        private final HttpHeaders headers;
        private final byte[] body;
        private final long timestamp;
        private final long ttlInMillis = 60_000; // 1 minuto

        public CachedResponse(HttpStatus statusCode, HttpHeaders headers, byte[] body) {
            this.statusCode = statusCode;
            this.headers = new HttpHeaders();
            this.headers.putAll(headers);
            this.body = body;
            this.timestamp = System.currentTimeMillis();
        }

        public boolean isExpired() {
            return System.currentTimeMillis() > timestamp + ttlInMillis;
        }

        public HttpStatus getStatusCode() {
            return statusCode;
        }

        public HttpHeaders getHeaders() {
            return headers;
        }

        public byte[] getBody() {
            return body;
        }
    }

    private static class CachingServerHttpResponseDecorator extends ServerHttpResponseDecorator {

        private final ServerWebExchange exchange;
        private final String cacheKey;
        private final Map<String, CachedResponse> cache;
        private final ByteArrayOutputStream buffer = new ByteArrayOutputStream();

        public CachingServerHttpResponseDecorator(ServerWebExchange exchange, String cacheKey,
                                                  Map<String, CachedResponse> cache) {
            super(exchange.getResponse());
            this.exchange = exchange;
            this.cacheKey = cacheKey;
            this.cache = cache;
        }

        @Override
        public Mono<Void> writeWith(Publisher<? extends DataBuffer> body) {
            return super.writeWith(Flux.from(body)
                    .doOnNext(dataBuffer -> {
                        byte[] bytes = new byte[dataBuffer.readableByteCount()];
                        dataBuffer.read(bytes);
                        buffer.write(bytes, 0, bytes.length);
                    })
                    .doOnComplete(() -> {
                        CachedResponse cachedResponse = new CachedResponse(
                                (HttpStatus) getStatusCode(),
                                getHeaders(),
                                buffer.toByteArray()
                        );
                        cache.put(cacheKey, cachedResponse);
                    })
            );
        }

        @Override
        public Mono<Void> writeAndFlushWith(Publisher<? extends Publisher<? extends DataBuffer>> body) {
            return writeWith(Flux.from(body).flatMapSequential(p -> p));
        }
    }
}
