package com.logistica.usuario.dto;

public record UsuarioResponse(
        Long id, String nome, String email, String tipo
) {
}
