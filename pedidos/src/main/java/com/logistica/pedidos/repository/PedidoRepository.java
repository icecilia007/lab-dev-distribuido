package com.logistica.pedidos.repository;

import com.logistica.pedidos.model.Pedido;
import com.logistica.pedidos.model.StatusPedido;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface PedidoRepository extends JpaRepository<Pedido, Long> {
    List<Pedido> findByClienteId(Long clienteId);
    List<Pedido> findByStatus(StatusPedido status);
    List<Pedido> findByMotoristaId(Long motoristaId);

    List<Pedido> findByStatusAndDataAtualizacaoBefore(StatusPedido statusPedido, LocalDateTime limiteAceite);
}
