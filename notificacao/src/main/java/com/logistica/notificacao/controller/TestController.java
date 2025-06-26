package com.logistica.notificacao.controller;

import com.logistica.notificacao.service.EmailService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/test")
public class TestController {

    private final EmailService emailService;

    public TestController(EmailService emailService) {
        this.emailService = emailService;
    }

    @PostMapping("/email")
    public ResponseEntity<Map<String, String>> testarEmail(
            @RequestParam String email,
            @RequestParam(defaultValue = "Teste SQS") String assunto,
            @RequestParam(defaultValue = "Teste de envio para fila SQS") String conteudo) {
        
        emailService.enviarEmail(email, assunto, conteudo);
        
        return ResponseEntity.ok(Map.of(
                "status", "success",
                "message", "Email enviado para fila SQS",
                "destinatario", email,
                "assunto", assunto,
                "queueUrl", "https://sqs.us-east-1.amazonaws.com/176343551411/email-notifications"
        ));
    }
}