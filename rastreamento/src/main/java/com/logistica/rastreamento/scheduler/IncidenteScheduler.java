package com.logistica.rastreamento.scheduler;

import com.logistica.rastreamento.model.Incidente;
import com.logistica.rastreamento.repository.IncidenteRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class IncidenteScheduler {

    private static final Logger logger = LoggerFactory.getLogger(IncidenteScheduler.class);
    private final IncidenteRepository incidenteRepository;

    public IncidenteScheduler(IncidenteRepository incidenteRepository) {
        this.incidenteRepository = incidenteRepository;
    }

    @Scheduled(cron = "0 0/30 * * * *")
    public void desativarIncidentesExpirados() {
        LocalDateTime agora = LocalDateTime.now();
        int incidentesDesativados = incidenteRepository.desativarIncidentesExpirados(agora);

        if (incidentesDesativados > 0) {
            logger.info("Desativados {} incidentes expirados", incidentesDesativados);
        }
    }
}
