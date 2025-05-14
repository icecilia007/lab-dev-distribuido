package com.logistica.rastreamento.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "localizacoes")
@Getter
@Setter
public class Localizacao {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long pedidoId;
    private Long motoristaId;
    private Double latitude;
    private Double longitude;
    private LocalDateTime timestamp;

    @Enumerated(EnumType.STRING)
    private StatusVeiculo statusVeiculo;

    // Getters e Setters
}

