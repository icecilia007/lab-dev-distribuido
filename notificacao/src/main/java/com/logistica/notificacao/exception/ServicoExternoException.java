package com.logistica.notificacao.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(HttpStatus.SERVICE_UNAVAILABLE)
public class ServicoExternoException extends RuntimeException {
    public ServicoExternoException(String message, Throwable cause) {
        super(message, cause);
    }
}
