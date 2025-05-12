package com.logistica.notificacao.service.impl;

import com.logistica.notificacao.model.PreferenciaNotificacao;
import com.logistica.notificacao.repository.PreferenciaNotificacaoRepository;
import com.logistica.notificacao.service.PreferenciaService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Slf4j
public class PreferenciaServiceImpl implements PreferenciaService {
    private final PreferenciaNotificacaoRepository repository;

    public PreferenciaServiceImpl(PreferenciaNotificacaoRepository repository) {
        this.repository = repository;
    }

    @Override
    public PreferenciaNotificacao save(PreferenciaNotificacao preferencia) {
        return repository.save(preferencia);
    }

    @Override
    public Optional<PreferenciaNotificacao> findById(Long usuarioId) {
        return repository.findById(usuarioId);
    }
}
