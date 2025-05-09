package com.logistica.pedidos.controller;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.logistica.pedidos.dto.AtualizarStatusRequest;
import com.logistica.pedidos.dto.PedidoRequest;
import com.logistica.pedidos.dto.PedidoResponse;
import com.logistica.pedidos.model.StatusPedido;
import com.logistica.pedidos.service.PedidoService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/pedidos")
@CrossOrigin(origins = "*")
public class PedidoController {

    private final PedidoService pedidoService;

    public PedidoController(PedidoService pedidoService) {
        this.pedidoService = pedidoService;
    }

    @Operation(summary = "Criar novo pedido",
            description = "Cria um novo pedido com cálculo automático de rota otimizada")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "201", description = "Pedido criado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Dados inválidos fornecidos"),
            @ApiResponse(responseCode = "404", description = "Cliente não encontrado")
    })
    @PostMapping
    public ResponseEntity<PedidoResponse> criarPedido(@RequestBody PedidoRequest request) throws JsonProcessingException {
        PedidoResponse pedido = pedidoService.criarPedido(request);
        return new ResponseEntity<>(pedido, HttpStatus.CREATED);
    }

    @Operation(summary = "Buscar pedido por ID")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Pedido encontrado com sucesso"),
            @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @GetMapping("/{id}")
    public ResponseEntity<PedidoResponse> buscarPedidoPorId(@PathVariable Long id) {
        PedidoResponse pedido = pedidoService.buscarPedidoPorId(id);
        return ResponseEntity.ok(pedido);
    }

    @Operation(summary = "Listar pedidos por cliente")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lista de pedidos retornada com sucesso"),
            @ApiResponse(responseCode = "404", description = "Cliente não encontrado")
    })
    @GetMapping("/cliente/{clienteId}")
    public ResponseEntity<List<PedidoResponse>> buscarPedidosPorCliente(@PathVariable Long clienteId) {
        List<PedidoResponse> pedidos = pedidoService.buscarPedidosPorCliente(clienteId);
        return ResponseEntity.ok(pedidos);
    }

    @Operation(summary = "Listar pedidos por status")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lista de pedidos retornada com sucesso")
    })
    @GetMapping("/status/{status}")
    public ResponseEntity<List<PedidoResponse>> buscarPedidosPorStatus(@PathVariable StatusPedido status) {
        List<PedidoResponse> pedidos = pedidoService.buscarPedidosPorStatus(status);
        return ResponseEntity.ok(pedidos);
    }

    @Operation(summary = "Listar pedidos por motorista")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Lista de pedidos retornada com sucesso"),
            @ApiResponse(responseCode = "404", description = "Motorista não encontrado")
    })
    @GetMapping("/motorista/{motoristaId}")
    public ResponseEntity<List<PedidoResponse>> buscarPedidosPorMotorista(@PathVariable Long motoristaId) {
        List<PedidoResponse> pedidos = pedidoService.buscarPedidosPorMotorista(motoristaId);
        return ResponseEntity.ok(pedidos);
    }

    @Operation(summary = "Atualizar status do pedido")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Status atualizado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Transição de status inválida"),
            @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @PatchMapping("/{id}/status")
    public ResponseEntity<PedidoResponse> atualizarStatusPedido(
            @PathVariable Long id,
            @RequestBody AtualizarStatusRequest request) {
        PedidoResponse pedido = pedidoService.atualizarStatusPedido(id, request);
        return ResponseEntity.ok(pedido);
    }

    @Operation(summary = "Cancelar pedido")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Pedido cancelado com sucesso"),
            @ApiResponse(responseCode = "400", description = "Não é possível cancelar um pedido já entregue"),
            @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @PatchMapping("/{id}/cancelar")
    public ResponseEntity<Void> cancelarPedido(@PathVariable Long id) {
        pedidoService.cancelarPedido(id);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Remover pedido")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "204", description = "Pedido removido com sucesso"),
            @ApiResponse(responseCode = "400", description = "Apenas pedidos cancelados podem ser removidos"),
            @ApiResponse(responseCode = "404", description = "Pedido não encontrado")
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> removerPedido(@PathVariable Long id) {
        pedidoService.removerPedido(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{pedidoId}/aceitar")
    public ResponseEntity<PedidoResponse> aceitarPedido(
            @PathVariable Long pedidoId,
            @RequestParam Long motoristaId,
            @RequestParam Double latitude,
            @RequestParam Double longitude) {

        PedidoResponse pedido = pedidoService.aceitarPedido(
                pedidoId, motoristaId, latitude, longitude);
        return ResponseEntity.ok(pedido);
    }
}
