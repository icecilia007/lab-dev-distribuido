package com.logistica.notificacao.controller;


import com.logistica.notificacao.dto.CampanhaBasicaRequest;
import com.logistica.notificacao.service.CampanhaService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class CampanhaController {


    private final CampanhaService campanhaService;

    public CampanhaController(CampanhaService campanhaService) {
        this.campanhaService = campanhaService;
    }

    @PostMapping("/trigger")
    public ResponseEntity<String> enviarCampanha(@Valid @RequestBody CampanhaBasicaRequest campanhaBasica) {
        ResponseEntity<String> response = campanhaService.enviarCampanha(campanhaBasica);
        return ResponseEntity.ok(response.getBody());

    }

    @GetMapping("/trigger/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Serviço de campanhas operacional");
    }
}
