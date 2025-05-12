package com.logistica.notificacao.controller;

import com.logistica.notificacao.model.PreferenciaNotificacao;
import com.logistica.notificacao.service.PreferenciaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notificacoes/preferencias")
public class PreferenciaNotificacaoController {


    private final PreferenciaService preferenciaService;

    public PreferenciaNotificacaoController(PreferenciaService preferenciaService) {
        this.preferenciaService = preferenciaService;
    }

    @PostMapping
    public ResponseEntity<PreferenciaNotificacao> salvarPreferencia(
            @RequestBody PreferenciaNotificacao preferencia) {
        return ResponseEntity.ok(preferenciaService.save(preferencia));
    }

    @GetMapping("/{usuarioId}")
    public ResponseEntity<PreferenciaNotificacao> buscarPreferencia(
            @PathVariable Long usuarioId) {
        return preferenciaService.findById(usuarioId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
