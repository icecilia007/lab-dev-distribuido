package com.logistica.usuario.model;

import jakarta.persistence.Column;
import jakarta.persistence.DiscriminatorValue;
import jakarta.persistence.Entity;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.DynamicInsert;

@Entity
@DiscriminatorValue("CLIENTE")
@DynamicInsert
@Getter
@Setter
public class Cliente extends Usuario {
    @Column(columnDefinition = "varchar(255) default 'outros'")
    private String categoria;
}
