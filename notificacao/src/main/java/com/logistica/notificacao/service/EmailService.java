package com.logistica.notificacao.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.HashMap;
import java.util.Map;

@Service
@Slf4j
public class EmailService {

    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;

    @Value("${aws.sqs.email-queue-url}")
    private String emailQueueUrl;

    public EmailService(SqsClient sqsClient, ObjectMapper objectMapper) {
        this.sqsClient = sqsClient;
        this.objectMapper = objectMapper;
    }

    public void enviarEmail(String destinatario, String assunto, String conteudo) {
        try {
            Map<String, Object> emailData = new HashMap<>();
            emailData.put("destinatario", destinatario);
            emailData.put("assunto", assunto);
            emailData.put("conteudo", conteudo);
            emailData.put("timestamp", System.currentTimeMillis());

            String messageBody = objectMapper.writeValueAsString(emailData);

            SendMessageRequest sendMsgRequest = SendMessageRequest.builder()
                    .queueUrl(emailQueueUrl)
                    .messageBody(messageBody)
                    .build();

            sqsClient.sendMessage(sendMsgRequest);
            log.info("Mensagem enviada para fila SQS para email: {}", destinatario);
        } catch (Exception e) {
            log.error("Erro ao enviar mensagem para fila SQS para email {}: {}", destinatario, e.getMessage());
        }
    }
}
