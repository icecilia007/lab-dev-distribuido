package com.logistica.notificacao.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CampanhaBasicaRequest {
    private String nome;
    private String assunto;
    private String conteudo;
}