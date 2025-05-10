package com.logistica.notificacao.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

import java.util.Map;

@ResponseStatus(HttpStatus.BAD_REQUEST)
public class ValidacaoException extends RuntimeException {
    private final Map<String, String> erros;

    public ValidacaoException(String message, Map<String, String> erros) {
        super(message);
        this.erros = erros;
    }

    public Map<String, String> getErros() {
        return erros;
    }
}
