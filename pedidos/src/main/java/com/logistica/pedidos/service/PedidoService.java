package com.logistica.pedidos.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.logistica.pedidos.dto.AtualizarStatusRequest;
import com.logistica.pedidos.dto.PedidoRequest;
import com.logistica.pedidos.dto.PedidoResponse;
import com.logistica.pedidos.model.StatusPedido;

import java.util.List;

public interface PedidoService {
    void removerPedido(Long id);

    PedidoResponse criarPedido(PedidoRequest request) throws JsonProcessingException;

    PedidoResponse aceitarPedido(Long pedidoId, Long motoristaId, Double motoristaLatitude, Double motoristaLongitude);

    PedidoResponse buscarPedidoPorId(Long id);

    List<PedidoResponse> buscarPedidosPorCliente(Long clienteId);

    List<PedidoResponse> buscarPedidosPorStatus(StatusPedido status);

    List<PedidoResponse> buscarPedidosPorMotorista(Long motoristaId);

    PedidoResponse atualizarStatusPedido(Long id, AtualizarStatusRequest request);

    void cancelarPedido(Long id);
}
