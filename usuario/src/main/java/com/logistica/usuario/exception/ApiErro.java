package com.logistica.usuario.exception;

import java.time.LocalDateTime;

public record ApiErro(String codigo, String mensagem, int status, LocalDateTime timestamp) {}

