package com.logistica.notificacao.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ClienteRequest {
    private String id;
    private String nome;
    private String email;
    private String regiao;
}
