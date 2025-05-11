package com.logistica.rastreamento.filter;

import jakarta.servlet.*;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

@Component
public class GatewayAuthFilter implements Filter {

    @Value("${security.internal.header-name}")
    private String SECRET_HEADER_NAME;
    @Value("${security.internal.header-value}")
    private String SECRET_HEADER_VALUE;

    private static final List<String> SWAGGER_PATHS = Arrays.asList(
            "/swagger-ui/",
            "/api-docs",
            "/swagger-resources/",
            "/webjars/"
    );

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        String path = httpRequest.getRequestURI();

        if (isSwaggerPath(path)) {
            chain.doFilter(request, response);
            return;
        }

        String authHeader = httpRequest.getHeader(SECRET_HEADER_NAME);

        if (SECRET_HEADER_VALUE.equals(authHeader)) {
            chain.doFilter(request, response);
        } else {
            HttpServletResponse httpResponse = (HttpServletResponse) response;
            httpResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
            httpResponse.getWriter().write("Acesso não autorizado");
        }
    }
    private boolean isSwaggerPath(String path) {
        return SWAGGER_PATHS.stream().anyMatch(path::contains);
    }
}