package com.logistica.notificacao.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;

@SpringBootTest
@TestPropertySource(properties = {
    "aws.sqs.email-queue-url=https://sqs.us-east-1.amazonaws.com/176343551411/email-notifications"
})
class EmailServiceIntegrationTest {

    @Test
    void testEnviarEmailReal() {
        SqsClient sqsClient = SqsClient.builder()
                .region(Region.US_EAST_1)
                .build();
        
        ObjectMapper objectMapper = new ObjectMapper();
        EmailService emailService = new EmailService(sqsClient, objectMapper);
        
        // Use reflection para definir a URL da fila
        try {
            java.lang.reflect.Field field = EmailService.class.getDeclaredField("emailQueueUrl");
            field.setAccessible(true);
            field.set(emailService, "https://sqs.us-east-1.amazonaws.com/176343551411/email-notifications");
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        // Teste real
        emailService.enviarEmail(
            "arihenriquedev@hotmail.com", 
            "Teste SQS Real", 
            "Esta é uma mensagem de teste enviada diretamente para a fila SQS"
        );
        
        System.out.println("✅ Teste executado - verifique a fila SQS!");
    }
}