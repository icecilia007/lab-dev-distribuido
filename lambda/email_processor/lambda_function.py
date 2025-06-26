import json
import boto3
import logging
import os
from typing import Dict, Any
from datetime import datetime


logger = logging.getLogger()
logger.setLevel(logging.INFO)

ses_client = boto3.client('ses')

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handler principal da Lambda para processar mensagens de email da fila SQS
    """
    logger.info(f"Processando {len(event['Records'])} mensagens")
    
    processed_count = 0
    failed_count = 0
    
    for record in event['Records']:
        try:
            body = record['body']
            logger.info(f"Mensagem recebida: {body}")

            try:
                message_body = json.loads(body)
            except json.JSONDecodeError as e:
                logger.warning(f"Erro no primeiro parse: {str(e)}")
                cleaned_body = body.replace('\\', '')
                message_body = json.loads(cleaned_body)

            success = process_email_message(message_body)
            
            if success:
                processed_count += 1
                logger.info(f"Email processado com sucesso: {message_body.get('destinatario')}")
            else:
                failed_count += 1
                logger.error(f"Falha ao processar email: {message_body.get('destinatario')}")
                
        except Exception as e:
            failed_count += 1
            logger.error(f"Erro ao processar registro: {str(e)}")
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'processed': processed_count,
            'failed': failed_count,
            'timestamp': datetime.utcnow().isoformat()
        })
    }

def process_email_message(message_data: Dict[str, Any]) -> bool:
    """
    Processa uma mensagem individual de email
    """
    try:
        if message_data.get('Type') == 'Notification':
            logger.info("Mensagem de métrica SNS ignorada - não é email para envio")
            return True
            
        destinatario = message_data.get('destinatario')
        assunto = message_data.get('assunto')
        conteudo = message_data.get('conteudo')
        
        if not all([destinatario, assunto, conteudo]):
            logger.error("Campos obrigatórios ausentes na mensagem")
            return False

        logger.info(f"Email autorizado para envio: {destinatario}")

        html_content = format_email_html(assunto, conteudo)

        return send_email_via_ses(destinatario, assunto, conteudo, html_content)
        
    except Exception as e:
        logger.error(f"Erro ao processar mensagem de email: {str(e)}")
        return False

def format_email_html(assunto: str, conteudo: str) -> str:
    """
    Formata o conteúdo do email em HTML limpo e anti-spam
    """
    conteudo_limpo = conteudo.strip()

    conteudo_html = conteudo_limpo.replace('\n', '<br>\n')
    
    html_template = f"""<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>{assunto}</title>
    <style type="text/css">
        body {{
            margin: 0;
            padding: 20px;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f8f9fa;
            line-height: 1.6;
        }}
        .email-container {{
            max-width: 600px;
            margin: 0 auto;
            background-color: #ffffff;
            border-radius: 8px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
        }}
        .header h1 {{
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }}
        .content {{
            padding: 30px 20px;
            color: #333333;
            font-size: 16px;
        }}
        .content p {{
            margin: 0 0 15px 0;
        }}
        .footer {{
            background-color: #f8f9fa;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #6c757d;
            border-top: 1px solid #e9ecef;
        }}
        .footer p {{
            margin: 5px 0;
        }}
        @media only screen and (max-width: 600px) {{
            .email-container {{
                margin: 10px;
                width: auto !important;
            }}
            .content {{
                padding: 20px 15px;
            }}
        }}
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>Sistema de Logística</h1>
        </div>
        <div class="content">
            {conteudo_html}
        </div>
        <div class="footer">
            <p>Esta é uma notificação automática do Sistema de Logística.</p>
            <p>Por favor, não responda a este email.</p>
            <p>© 2025 Sistema de Logística. Todos os direitos reservados.</p>
        </div>
    </div>
</body>
</html>"""
    return html_template

def send_email_via_ses(destinatario: str, assunto: str, conteudo_texto: str, conteudo_html: str) -> bool:
    """
    Envia email usando Amazon SES com headers anti-spam
    """
    try:
        sender_email = os.environ.get('SENDER_EMAIL')

        conteudo_texto_limpo = conteudo_texto.replace('\n\n', '\n').strip()
        
        response = ses_client.send_email(
            Source=f"Sistema de Logística <{sender_email}>",
            Destination={
                'ToAddresses': [destinatario]
            },
            Message={
                'Subject': {
                    'Data': f"[Sistema Logística] {assunto}",
                    'Charset': 'UTF-8'
                },
                'Body': {
                    'Text': {
                        'Data': f"Sistema de Logística\n\n{conteudo_texto_limpo}\n\n---\nEsta é uma notificação automática.\nPor favor, não responda a este email.",
                        'Charset': 'UTF-8'
                    },
                    'Html': {
                        'Data': conteudo_html,
                        'Charset': 'UTF-8'
                    }
                }
            },
            ConfigurationSetName='email-notifications-config',
            ReplyToAddresses=[sender_email],
            ReturnPath=sender_email
        )
        
        logger.info(f"Email enviado com sucesso. MessageId: {response['MessageId']}")
        return True
        
    except Exception as e:
        logger.error(f"Erro ao enviar email via SES: {str(e)}")
        # Log detalhado do erro para debugging
        logger.error(f"Detalhes do erro SES - Destinatário: {destinatario}, Sender: {sender_email}")
        return False