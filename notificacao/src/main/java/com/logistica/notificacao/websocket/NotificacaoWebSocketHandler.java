package com.logistica.notificacao.websocket;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.logistica.notificacao.model.Notificacao;

import lombok.extern.slf4j.Slf4j;

@Component
@Slf4j
public class NotificacaoWebSocketHandler extends TextWebSocketHandler {

    private final Map<Long, WebSocketSession> userSessions = new ConcurrentHashMap<>();
    private final ObjectMapper objectMapper;

    public NotificacaoWebSocketHandler(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        Long userId = extractUserIdFromSession(session);
        if (userId != null) {
            userSessions.put(userId, session);
            log.info("WebSocket conectado para usuário ID: {}", userId);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) throws Exception {
        Long userId = extractUserIdFromSession(session);
        if (userId != null) {
            userSessions.remove(userId);
            log.info("WebSocket desconectado para usuário ID: {}", userId);
        }
    }

    private Long extractUserIdFromSession(WebSocketSession session) {
        String query = session.getUri().getQuery();
        if (query != null && query.contains("userId=")) {
            String[] params = query.split("&");
            for (String param : params) {
                if (param.startsWith("userId=")) {
                    try {
                        return Long.parseLong(param.substring(7));
                    } catch (NumberFormatException e) {
                        log.error("Erro ao converter userId para Long: {}", e.getMessage());
                    }
                }
            }
        }
        return null;
    }

    public void enviarNotificacao(Long userId, Notificacao notificacao) {
        WebSocketSession session = userSessions.get(userId);
        if (session != null && session.isOpen()) {
            try {
                String mensagem = objectMapper.writeValueAsString(notificacao);
                session.sendMessage(new TextMessage(mensagem));
                log.info("Notificação enviada por WebSocket para usuário ID: {}", userId);
            } catch (IOException e) {
                log.error("Erro ao enviar notificação por WebSocket: {}", e.getMessage());
            }
        } else {
            log.info("Usuário ID: {} não está conectado por WebSocket", userId);
        }
    }
}
