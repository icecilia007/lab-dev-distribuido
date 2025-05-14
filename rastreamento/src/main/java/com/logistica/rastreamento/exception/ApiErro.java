package com.logistica.rastreamento.exception;

import java.time.LocalDateTime;

public record ApiErro(String codigo, String mensagem, int status, LocalDateTime timestamp) {
}


