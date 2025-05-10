package com.logistica.notificacao.controller;

import com.logistica.notificacao.exception.OperacaoInvalidaException;
import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.service.NotificacaoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/notificacoes")
public class NotificacaoController {

    private final NotificacaoService notificacaoService;

    public NotificacaoController(NotificacaoService notificacaoService) {
        this.notificacaoService = notificacaoService;
    }

    @Operation(summary = "Buscar notificações por destinatário")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Notificações retornadas com sucesso"),
            @ApiResponse(responseCode = "400", description = "ID do destinatário inválido"),
            @ApiResponse(responseCode = "500", description = "Erro interno do servidor")
    })
    @GetMapping("/destinatario/{id}")
    public ResponseEntity<List<Notificacao>> buscarNotificacoes(@PathVariable Long id) {
        if (id <= 0) {
            throw new OperacaoInvalidaException("ID do destinatário inválido");
        }
        return ResponseEntity.ok(notificacaoService.buscarPorDestinatario(id));
    }

    @Operation(summary = "Contar notificações não lidas")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Contagem retornada com sucesso"),
            @ApiResponse(responseCode = "400", description = "ID do destinatário inválido"),
            @ApiResponse(responseCode = "500", description = "Erro interno do servidor")
    })
    @GetMapping("/destinatario/{id}/nao-lidas/contagem")
    public ResponseEntity<Map<String, Long>> contarNaoLidas(@PathVariable Long id) {
        if (id <= 0) {
            throw new OperacaoInvalidaException("ID do destinatário inválido");
        }
        long contagem = notificacaoService.contarNotificacoesNaoLidas(id);
        return ResponseEntity.ok(Map.of("quantidade", contagem));
    }

    @Operation(summary = "Marcar notificação como lida")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Notificação marcada como lida"),
            @ApiResponse(responseCode = "400", description = "ID da notificação inválido"),
            @ApiResponse(responseCode = "404", description = "Notificação não encontrada"),
            @ApiResponse(responseCode = "500", description = "Erro interno do servidor")
    })
    @PatchMapping("/{id}/marcar-lida")
    public ResponseEntity<Void> marcarComoLida(@PathVariable Long id) {
        if (id <= 0) {
            throw new OperacaoInvalidaException("ID da notificação inválido");
        }
        notificacaoService.marcarComoLida(id);
        return ResponseEntity.noContent().build();
    }
}
