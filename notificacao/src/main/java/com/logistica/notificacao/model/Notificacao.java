package com.logistica.notificacao.model;

import io.hypersistence.utils.hibernate.type.json.JsonBinaryType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.Type;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "notificacoes")
@Getter
@Setter
public class Notificacao {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String tipoEvento;
    private String origem;

    private Long destinatarioId;

    private String titulo;
    private String mensagem;

    private LocalDateTime dataCriacao;
    private LocalDateTime dataLeitura;

    @Enumerated(EnumType.STRING)
    private StatusNotificacao status;

    @Type(JsonBinaryType.class)
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    private Map<String, Object> dadosEvento;

    public enum StatusNotificacao {
        NAO_LIDA, LIDA
    }

    public Map<String, Object> getDadosEvento() {
        return dadosEvento;
    }

    public void setDadosEvento(Map<String, Object> dadosEvento) {
        this.dadosEvento = dadosEvento;
    }
}
