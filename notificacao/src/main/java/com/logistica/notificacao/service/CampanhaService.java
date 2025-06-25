package com.logistica.notificacao.service;

import com.logistica.notificacao.dto.CampanhaBasicaRequest;
import org.springframework.http.ResponseEntity;

public interface CampanhaService {
    ResponseEntity<String> enviarCampanha(CampanhaBasicaRequest campanhaBasica);
}
