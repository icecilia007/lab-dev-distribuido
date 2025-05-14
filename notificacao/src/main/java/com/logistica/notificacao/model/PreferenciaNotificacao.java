package com.logistica.notificacao.model;

import jakarta.persistence.Table;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Enumerated;
import jakarta.persistence.EnumType;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "preferencias_notificacao")
public class PreferenciaNotificacao {

    @Id
    private Long usuarioId;

    @Enumerated(EnumType.STRING)
    private TipoNotificacao tipoPreferido;

    private String email;
}
