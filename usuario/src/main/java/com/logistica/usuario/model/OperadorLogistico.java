package com.logistica.usuario.model;

import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.Setter;

@Entity
@DiscriminatorValue("OPERADOR")
@Getter
@Setter
public class OperadorLogistico extends Usuario {
}
