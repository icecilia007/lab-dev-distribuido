package com.logistica.notificacao.service.impl;

import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.model.PreferenciaNotificacao;
import com.logistica.notificacao.model.TipoNotificacao;
import com.logistica.notificacao.repository.NotificacaoRepository;
import com.logistica.notificacao.repository.PreferenciaNotificacaoRepository;
import com.logistica.notificacao.service.EmailService;
import com.logistica.notificacao.service.NotificacaoService;
import com.logistica.notificacao.service.PushNotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;


@Service
@Slf4j
public class NotificacaoServiceImpl implements NotificacaoService {

    private final NotificacaoRepository notificacaoRepository;
    private final PreferenciaNotificacaoRepository preferenciaRepository;
    private final EmailService emailService;
    private final PushNotificationService pushService;


    public NotificacaoServiceImpl(NotificacaoRepository notificacaoRepository, PreferenciaNotificacaoRepository preferenciaRepository, EmailService emailService, PushNotificationService pushService) {
        this.notificacaoRepository = notificacaoRepository;
        this.preferenciaRepository = preferenciaRepository;
        this.emailService = emailService;
        this.pushService = pushService;
    }
    @Override
    public Notificacao salvar(Notificacao notificacao) {
        log.info("Salvando notificação para destinatário {}: {}",
                notificacao.getDestinatarioId(), notificacao.getTipoEvento());

        Notificacao notificacaoSalva = notificacaoRepository.save(notificacao);

        preferenciaRepository.findById(notificacao.getDestinatarioId())
                .ifPresent(preferencia -> {
                    if (preferencia.getTipoPreferido() == TipoNotificacao.EMAIL ||
                            preferencia.getTipoPreferido() == TipoNotificacao.AMBOS) {
                        emailService.enviarEmail(
                                preferencia.getEmail(),
                                notificacao.getTitulo(),
                                notificacao.getMensagem()
                        );
                    }

                    if (preferencia.getTipoPreferido() == TipoNotificacao.PUSH ||
                            preferencia.getTipoPreferido() == TipoNotificacao.AMBOS) {
                        pushService.enviarNotificacaoPush(notificacaoSalva);
                    }
                });

        return notificacaoSalva;
    }

    @Override
    public List<Notificacao> buscarPorDestinatario(Long destinatarioId) {
        return notificacaoRepository.findByDestinatarioIdOrderByDataCriacaoDesc(destinatarioId);
    }

    @Override
    public void marcarComoLida(Long notificacaoId) {
        notificacaoRepository.findById(notificacaoId).ifPresent(n -> {
            n.setStatus(Notificacao.StatusNotificacao.LIDA);
            n.setDataLeitura(LocalDateTime.now());
            notificacaoRepository.save(n);
        });
    }

    @Override
    public long contarNotificacoesNaoLidas(Long destinatarioId) {
        return notificacaoRepository.countByDestinatarioIdAndStatus(
                destinatarioId, Notificacao.StatusNotificacao.NAO_LIDA);
    }
}