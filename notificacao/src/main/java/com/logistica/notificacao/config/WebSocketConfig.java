package com.logistica.notificacao.config;

import com.logistica.notificacao.websocket.NotificacaoWebSocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    private final NotificacaoWebSocketHandler notificacaoWebSocketHandler;

    public WebSocketConfig(NotificacaoWebSocketHandler notificacaoWebSocketHandler) {
        this.notificacaoWebSocketHandler = notificacaoWebSocketHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(notificacaoWebSocketHandler, "/ws-notificacao")
                .setAllowedOrigins("*");
    }
}