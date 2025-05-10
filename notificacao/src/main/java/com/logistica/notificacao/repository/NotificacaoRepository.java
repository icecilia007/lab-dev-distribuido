package com.logistica.notificacao.repository;

import com.logistica.notificacao.model.Notificacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificacaoRepository extends JpaRepository<Notificacao, Long> {
    List<Notificacao> findByDestinatarioIdOrderByDataCriacaoDesc(Long destinatarioId);

    long countByDestinatarioIdAndStatus(Long destinatarioId, Notificacao.StatusNotificacao statusNotificacao);
}