package com.logistica.notificacao.dto;

import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class GrupoRequest {
    private String tipo;
    private List<ClienteRequest> clientes;
}