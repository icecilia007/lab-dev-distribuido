package com.logistica.notificacao.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class EmailServiceTest {

    @Mock
    private SqsClient sqsClient;

    @Mock
    private ObjectMapper objectMapper;

    @InjectMocks
    private EmailService emailService;

    private final String testQueueUrl = "https://sqs.us-east-1.amazonaws.com/176343551411/email-notifications";

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(emailService, "emailQueueUrl", testQueueUrl);
    }

    @Test
    void testEnviarEmail_Success() throws Exception {
        String destinatario = "test@example.com";
        String assunto = "Teste";
        String conteudo = "Conteúdo do teste";
        String expectedJson = "{\"destinatario\":\"arihenriquedev@hotmail.com\",\"assunto\":\"Teste\",\"conteudo\":\"Conteúdo do teste\",\"timestamp\":1234567890}";

        when(objectMapper.writeValueAsString(any(Map.class))).thenReturn(expectedJson);

        emailService.enviarEmail(destinatario, assunto, conteudo);

        ArgumentCaptor<SendMessageRequest> requestCaptor = ArgumentCaptor.forClass(SendMessageRequest.class);
        verify(sqsClient, times(1)).sendMessage(requestCaptor.capture());

        SendMessageRequest capturedRequest = requestCaptor.getValue();
        assertEquals(testQueueUrl, capturedRequest.queueUrl());
        assertEquals(expectedJson, capturedRequest.messageBody());

        verify(objectMapper, times(1)).writeValueAsString(any(Map.class));
    }

    @Test
    void testEnviarEmail_JsonProcessingException() throws Exception {
        String destinatario = "arihenriquedev@hotmail.com";
        String assunto = "Teste";
        String conteudo = "Conteúdo do teste";

        when(objectMapper.writeValueAsString(any(Map.class)))
                .thenThrow(new RuntimeException("JSON processing error"));

        assertDoesNotThrow(() -> emailService.enviarEmail(destinatario, assunto, conteudo));

        verify(sqsClient, never()).sendMessage(any(SendMessageRequest.class));
        verify(objectMapper, times(1)).writeValueAsString(any(Map.class));
    }

    @Test
    void testEnviarEmail_SqsException() throws Exception {
        String destinatario = "arihenriquedev@hotmail.com";
        String assunto = "Teste";
        String conteudo = "Conteúdo do teste";
        String expectedJson = "{\"test\":\"json\"}";

        when(objectMapper.writeValueAsString(any(Map.class))).thenReturn(expectedJson);
        when(sqsClient.sendMessage(any(SendMessageRequest.class)))
                .thenThrow(new RuntimeException("SQS error"));

        assertDoesNotThrow(() -> emailService.enviarEmail(destinatario, assunto, conteudo));

        verify(sqsClient, times(1)).sendMessage(any(SendMessageRequest.class));
        verify(objectMapper, times(1)).writeValueAsString(any(Map.class));
    }

    @Test
    void testEnviarEmail_VerifyMessageContent() throws Exception {
        String destinatario = "arihenriquedev@hotmail.com";
        String assunto = "Subject Test";
        String conteudo = "Message content";

        ArgumentCaptor<Map> mapCaptor = ArgumentCaptor.forClass(Map.class);
        when(objectMapper.writeValueAsString(mapCaptor.capture())).thenReturn("{}");

        emailService.enviarEmail(destinatario, assunto, conteudo);

        Map<String, Object> capturedMap = mapCaptor.getValue();
        assertEquals(destinatario, capturedMap.get("destinatario"));
        assertEquals(assunto, capturedMap.get("assunto"));
        assertEquals(conteudo, capturedMap.get("conteudo"));
        assertNotNull(capturedMap.get("timestamp"));
        assertTrue(capturedMap.get("timestamp") instanceof Long);
    }
}