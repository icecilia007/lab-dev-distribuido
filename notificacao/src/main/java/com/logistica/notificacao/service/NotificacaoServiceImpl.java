package com.logistica.notificacao.service;

import com.logistica.notificacao.model.Notificacao;
import com.logistica.notificacao.repository.NotificacaoRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;


@Service
@Slf4j
public class NotificacaoServiceImpl implements NotificacaoService {

    private final NotificacaoRepository notificacaoRepository;


    public NotificacaoServiceImpl(NotificacaoRepository notificacaoRepository) {
        this.notificacaoRepository = notificacaoRepository;
    }
    // TODO implementar verificacao de preferencia de notificao do cliente e enviar baseado nisso
    @Override
    public Notificacao salvar(Notificacao notificacao) {
        log.info("Salvando notificação para destinatário {}: {}",
                notificacao.getDestinatarioId(), notificacao.getTipoEvento());
        return notificacaoRepository.save(notificacao);
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