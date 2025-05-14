package com.logistica.usuario.model;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@DiscriminatorValue("MOTORISTA")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class Motorista extends Usuario {
    private String placa;
    private String modeloVeiculo;
    private Integer anoVeiculo;
    private Double consumoMedioPorKm;
    private String status;

}