package com.logistica.apigateway.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {

    @Value("${security.internal.header-name}")
    private String secretHeaderName;

    @Value("${security.internal.header-value}")
    private String secretHeaderValue;

    @Bean
    public WebClient.Builder webClientBuilder() {
        return WebClient.builder()
                .defaultHeader(secretHeaderName, secretHeaderValue);
    }
}

