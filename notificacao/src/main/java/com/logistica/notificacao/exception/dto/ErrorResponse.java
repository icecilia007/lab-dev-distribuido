package com.logistica.notificacao.exception.dto;

import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
public class ErrorResponse {
    private int status;
    private String titulo;
    private String detalhes;
    private String path;
    private LocalDateTime timestamp;

    public ErrorResponse(int status, String titulo, String detalhes, String path, LocalDateTime timestamp) {
        this.status = status;
        this.titulo = titulo;
        this.detalhes = detalhes;
        this.path = path;
        this.timestamp = timestamp;
    }

}
