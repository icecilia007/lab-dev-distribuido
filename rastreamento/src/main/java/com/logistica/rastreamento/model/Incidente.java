package com.logistica.rastreamento.model;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Table(name = "incidentes")
@Data
public class Incidente {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private Long motoristaId;
    private Double latitude;
    private Double longitude;

    @Enumerated(EnumType.STRING)
    private TipoIncidente tipo;

    private LocalDateTime dataReporte;
    private LocalDateTime dataExpiracao;
    private Boolean ativo;

    // Raio de impacto em km - para determinar quais motoristas notificar
    private Double raioImpactoKm;
}
