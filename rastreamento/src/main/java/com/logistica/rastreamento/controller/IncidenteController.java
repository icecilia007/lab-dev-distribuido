package com.logistica.rastreamento.controller;

import com.logistica.rastreamento.dto.IncidenteRequest;
import com.logistica.rastreamento.dto.IncidenteResponse;
import com.logistica.rastreamento.service.IncidenteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/incidentes")
@CrossOrigin(origins = "*")
@Tag(name = "Incidentes", description = "API para gerenciamento de incidentes nas rotas")
public class IncidenteController {

    private final IncidenteService incidenteService;

    public IncidenteController(IncidenteService incidenteService) {
        this.incidenteService = incidenteService;
    }

    @Operation(summary = "Reportar incidente",
            description = "Permite que motoristas reportem incidentes na rota (bloqueios, obras, acidentes)")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Incidente reportado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos fornecidos"),
            @ApiResponse(responseCode = "404", description = "Motorista não encontrado")
    })
    @PostMapping
    public ResponseEntity<IncidenteResponse> reportarIncidente(@RequestBody IncidenteRequest request) {
        IncidenteResponse incidente = incidenteService.reportarIncidente(request);
        return new ResponseEntity<>(incidente, HttpStatus.CREATED);
    }

    @Operation(summary = "Listar incidentes ativos",
            description = "Retorna todos os incidentes ativos no sistema")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lista de incidentes retornada com sucesso")
    })
    @GetMapping
    public ResponseEntity<List<IncidenteResponse>> listarIncidentesAtivos() {
        List<IncidenteResponse> incidentes = incidenteService.listarIncidentesAtivos();
        return ResponseEntity.ok(incidentes);
    }

    @Operation(summary = "Buscar incidentes próximos",
            description = "Retorna todos os incidentes próximos a uma coordenada geográfica")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lista de incidentes retornada com sucesso")
    })
    @GetMapping("/proximos")
    public ResponseEntity<List<IncidenteResponse>> buscarIncidentesProximos(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "5.0") Double raioKm) {

        List<IncidenteResponse> incidentes = incidenteService.buscarIncidentesProximos(
                latitude, longitude, raioKm);
        return ResponseEntity.ok(incidentes);
    }

    @Operation(summary = "Buscar incidente por ID",
            description = "Retorna os detalhes de um incidente específico")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Incidente encontrado com sucesso"),
            @ApiResponse(responseCode = "404", description = "Incidente não encontrado")
    })
    @GetMapping("/{id}")
    public ResponseEntity<IncidenteResponse> buscarIncidentePorId(@PathVariable Long id) {
        IncidenteResponse incidente = incidenteService.buscarIncidentePorId(id);
        return ResponseEntity.ok(incidente);
    }

    @Operation(summary = "Desativar incidente",
            description = "Marca um incidente como inativo/resolvido")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Incidente desativado com sucesso"),
            @ApiResponse(responseCode = "404", description = "Incidente não encontrado")
    })
    @PatchMapping("/{id}/desativar")
    public ResponseEntity<Void> desativarIncidente(@PathVariable Long id) {
        incidenteService.desativarIncidente(id);
        return ResponseEntity.noContent().build();
    }
}
