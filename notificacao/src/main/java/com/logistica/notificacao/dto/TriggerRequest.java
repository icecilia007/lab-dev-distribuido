package com.logistica.notificacao.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TriggerRequest {
    private String nome;
    private String assunto;
    private String conteudo;
    private List<GrupoRequest> grupos;
}
