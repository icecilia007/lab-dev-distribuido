package com.logistica.rastreamento.controller;

import com.logistica.rastreamento.dto.AtualizacaoLocalizacaoDTO;
import com.logistica.rastreamento.dto.LocalizacaoDTO;
import com.logistica.rastreamento.dto.MotoristaProximoDTO;
import com.logistica.rastreamento.service.RastreamentoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/rastreamento")
@CrossOrigin(origins = "*")
public class RastreamentoController {

    private final RastreamentoService rastreamentoService;

    public RastreamentoController(RastreamentoService rastreamentoService) {
        this.rastreamentoService = rastreamentoService;
    }

    @Operation(summary = "Atualizar localização de entrega",
            description = "Permite que motoristas enviem atualizações de localização")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Localização atualizada com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados de localização inválidos"),
            @ApiResponse(responseCode = "404", description = "Pedido ou motorista não encontrado")
    })
    @PostMapping("/localizacao")
    public ResponseEntity<Boolean> atualizarLocalizacao(@RequestBody AtualizacaoLocalizacaoDTO dto) {
        boolean sucesso = rastreamentoService.atualizarLocalizacao(dto);
        return ResponseEntity.ok(sucesso);
    }

    @Operation(summary = "Consultar localização atual",
            description = "Retorna a localização atual de um pedido específico")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Localização retornada com sucesso"),
            @ApiResponse(responseCode = "404", description = "Pedido não encontrado ou sem dados de localização")
    })
    @GetMapping("/pedido/{pedidoId}")
    public ResponseEntity<LocalizacaoDTO> consultarLocalizacaoPedido(@PathVariable Long pedidoId) {
        LocalizacaoDTO localizacao = rastreamentoService.consultarLocalizacaoAtual(pedidoId);
        return ResponseEntity.ok(localizacao);
    }

    @Operation(summary = "Buscar entregas próximas",
            description = "Encontra entregas ativas próximas a uma coordenada geográfica")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lista de entregas retornada com sucesso")
    })
    @GetMapping("/proximas")
    public ResponseEntity<List<LocalizacaoDTO>> buscarEntregasProximas(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "5.0") Double raioKm) {

        List<LocalizacaoDTO> entregas = rastreamentoService.buscarEntregasProximas(latitude, longitude, raioKm);
        return ResponseEntity.ok(entregas);
    }

    @Operation(summary = "Histórico de localizações",
            description = "Retorna o histórico de localizações de um pedido")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Histórico retornado com sucesso"),
            @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @GetMapping("/historico/{pedidoId}")
    public ResponseEntity<List<LocalizacaoDTO>> consultarHistoricoLocalizacao(@PathVariable Long pedidoId) {
        List<LocalizacaoDTO> historico = rastreamentoService.buscarHistoricoLocalizacoes(pedidoId);
        return ResponseEntity.ok(historico);
    }

    @Operation(summary = "Estatísticas de rastreamento",
            description = "Retorna estatísticas de um veículo em determinado período")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Estatísticas retornadas com sucesso"),
            @ApiResponse(responseCode = "404", description = "Motorista não encontrado")
    })
    @GetMapping("/estatisticas/motorista/{motoristaId}")
    public ResponseEntity<Map<String, Object>> consultarEstatisticasMotorista(
            @PathVariable Long motoristaId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataInicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dataFim) {

        Map<String, Object> estatisticas = rastreamentoService.calcularEstatisticasMotorista(
                motoristaId, dataInicio, dataFim);

        return ResponseEntity.ok(estatisticas);
    }

    @PostMapping("/pedido/{pedidoId}/coleta")
    public ResponseEntity<Boolean> confirmarColetaPedido(
            @PathVariable Long pedidoId,
            @RequestParam Long motoristaId) {
        boolean sucesso = rastreamentoService.confirmarColetaPedido(pedidoId, motoristaId);
        return ResponseEntity.ok(sucesso);
    }

    @PostMapping("/pedido/{pedidoId}/entrega")
    public ResponseEntity<Boolean> confirmarEntregaPedido(
            @PathVariable Long pedidoId,
            @RequestParam Long motoristaId) {
        boolean sucesso = rastreamentoService.confirmarEntregaPedido(pedidoId, motoristaId);
        return ResponseEntity.ok(sucesso);
    }

    @GetMapping("/motoristas/proximos")
    public ResponseEntity<List<MotoristaProximoDTO>> buscarMotoristasProximos(
            @RequestParam Double latitude,
            @RequestParam Double longitude,
            @RequestParam(defaultValue = "5.0") Double raioKm) {

        List<MotoristaProximoDTO> motoristas = rastreamentoService.buscarMotoristasProximos(
                latitude, longitude, raioKm);
        return ResponseEntity.ok(motoristas);
    }
}

