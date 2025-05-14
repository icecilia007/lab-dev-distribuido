package com.logistica.notificacao.service;

import com.logistica.notificacao.model.PreferenciaNotificacao;

import java.util.Optional;

public interface PreferenciaService {
    PreferenciaNotificacao save(PreferenciaNotificacao preferencia);

    Optional<PreferenciaNotificacao> findById(Long usuarioId);
}
