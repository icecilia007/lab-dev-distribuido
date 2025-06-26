import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageResponse;

public class TestSqs {

    public static void main(String[] args) {
        // Create an SQS client
        SqsClient sqsClient = SqsClient.builder()
                .region(Region.US_EAST_1)
                .build();

        String queueUrl = "https://sqs.us-east-1.amazonaws.com/176343551411/email-notifications";

        // JSON message matching EmailService format
        String messageBody = "{\"destinatario\":\"arihenriquedev@hotmail.com\",\"assunto\":\"Teste SQS Java\",\"conteudo\":\"Mensagem de teste enviada diretamente via Java SQS\",\"timestamp\":" + System.currentTimeMillis() + "}";

        // Build the SendMessageRequest
        SendMessageRequest sendMsgRequest = SendMessageRequest.builder()
                .queueUrl(queueUrl)
                .messageBody(messageBody)
                .build();

        try {
            // Send the message
            SendMessageResponse sendMsgResponse = sqsClient.sendMessage(sendMsgRequest);
            System.out.println("✅ Mensagem enviada com sucesso!");
            System.out.println("Message ID: " + sendMsgResponse.messageId());
            System.out.println("Queue URL: " + queueUrl);
            System.out.println("Message Body: " + messageBody);
        } catch (Exception e) {
            System.err.println("❌ Erro ao enviar mensagem: " + e.getMessage());
            e.printStackTrace();
        } finally {
            sqsClient.close();
        }
    }
}