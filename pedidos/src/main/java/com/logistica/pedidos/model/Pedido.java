package com.logistica.pedidos.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.LocalDateTime;


@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@Entity
@Table(name = "pedidos")
public class Pedido {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Apenas coordenadas geográficas para origem
    private String origemLatitude;
    private String origemLongitude;

    // Apenas coordenadas geográficas para destino
    private String destinoLatitude;
    private String destinoLongitude;

    private String tipoMercadoria;

    @Enumerated(EnumType.STRING)
    private StatusPedido status;

    private LocalDateTime dataCriacao;
    private LocalDateTime dataAtualizacao;
    private LocalDateTime dataEntregaEstimada;

    private Double distanciaKm;
    private Integer tempoEstimadoMinutos;

    @Column(columnDefinition = "TEXT")
    private String rotaMotoristaJson;

    private Long clienteId;
    private Long motoristaId;


}


