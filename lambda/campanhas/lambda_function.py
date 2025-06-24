import json
import boto3
import logging
import os
import uuid
from datetime import datetime, timezone
from typing import Dict, Any, List

# Configurar logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Inicializar clientes AWS
dynamodb = boto3.resource('dynamodb')
sns_client = boto3.client('sns')
sqs_client = boto3.client('sqs')

# Variáveis de ambiente
DYNAMODB_TABLE = os.environ.get('DYNAMODB_TABLE', 'campanhas-metricas')
SNS_TOPIC_PREMIUM = os.environ.get('SNS_TOPIC_PREMIUM')
SNS_TOPIC_REGIAO_SUL = os.environ.get('SNS_TOPIC_REGIAO_SUL')
SNS_TOPIC_GERAL = os.environ.get('SNS_TOPIC_GERAL')
SQS_EMAIL_QUEUE = os.environ.get('SQS_EMAIL_QUEUE')

table = dynamodb.Table(DYNAMODB_TABLE)

def lambda_handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Handler principal da Lambda para processar campanhas promocionais
    """
    try:
        logger.info(f"Evento recebido: {json.dumps(event)}")
        
        # Extrair informações da requisição
        http_method = event.get('httpMethod')
        path = event.get('path')
        
        if http_method == 'POST' and path == '/campanhas/trigger':
            return processar_campanha(event)
        
        # Rota não encontrada
        return criar_resposta(404, {'error': 'Rota não encontrada'})
        
    except Exception as e:
        logger.error(f"Erro no processamento: {str(e)}")
        return criar_resposta(500, {'error': 'Erro interno do servidor'})

def processar_campanha(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Processa uma campanha promocional
    """
    try:
        # Parse do body
        body = json.loads(event.get('body', '{}'))
        
        # Validar campos obrigatórios
        campos_obrigatorios = ['nome', 'assunto', 'conteudo', 'grupos']
        for campo in campos_obrigatorios:
            if campo not in body:
                return criar_resposta(400, {'error': f'Campo obrigatório ausente: {campo}'})
        
        campanha_id = str(uuid.uuid4())
        timestamp = datetime.now(timezone.utc).isoformat()
        
        # Dados da campanha
        campanha = {
            'campanha_id': campanha_id,
            'timestamp': timestamp,
            'nome': body['nome'],
            'assunto': body['assunto'],
            'conteudo': body['conteudo'],
            'grupos': body['grupos'],
            'status': 'iniciada',
            'emails_enviados': 0,
            'criado_em': timestamp
        }
        
        logger.info(f"Iniciando campanha: {campanha['nome']}")
        
        # Registrar início da campanha
        registrar_metrica_campanha(campanha)
        
        # Processar cada grupo de segmentação
        total_emails = 0
        grupos_processados = []
        
        for grupo in body['grupos']:
            resultado = processar_grupo_segmentacao(campanha_id, campanha, grupo)
            total_emails += resultado['emails_enviados']
            grupos_processados.append(resultado)
        
        # Atualizar métricas finais
        campanha_final = {
            **campanha,
            'status': 'concluida',
            'emails_enviados': total_emails,
            'grupos_processados': grupos_processados,
            'finalizado_em': datetime.now(timezone.utc).isoformat()
        }
        
        registrar_metrica_campanha(campanha_final)
        
        logger.info(f"Campanha finalizada: {total_emails} emails enviados")
        
        return criar_resposta(200, {
            'campanha_id': campanha_id,
            'status': 'concluida',
            'emails_enviados': total_emails,
            'grupos_processados': grupos_processados
        })
        
    except Exception as e:
        logger.error(f"Erro ao processar campanha: {str(e)}")
        return criar_resposta(500, {'error': 'Erro ao processar campanha'})

def processar_grupo_segmentacao(campanha_id: str, campanha: Dict, grupo: Dict) -> Dict:
    """
    Processa um grupo específico de segmentação
    """
    tipo_grupo = grupo.get('tipo', 'geral')
    clientes = grupo.get('clientes', [])
    
    logger.info(f"Processando grupo {tipo_grupo} com {len(clientes)} clientes")
    
    # Definir tópico SNS baseado no tipo
    topic_mapping = {
        'premium': SNS_TOPIC_PREMIUM,
        'regiao_sul': SNS_TOPIC_REGIAO_SUL,
        'geral': SNS_TOPIC_GERAL
    }
    
    topic_arn = topic_mapping.get(tipo_grupo, SNS_TOPIC_GERAL)
    
    emails_enviados = 0
    
    # Processar cada cliente do grupo
    for cliente in clientes:
        try:
            # Personalizar conteúdo para o cliente
            conteudo_personalizado = personalizar_conteudo(campanha, cliente, tipo_grupo)
            
            # Criar mensagem de email
            email_data = {
                'destinatario': cliente.get('email'),
                'assunto': campanha['assunto'],
                'conteudo': conteudo_personalizado,
                'campanha_id': campanha_id,
                'grupo': tipo_grupo,
                'cliente_id': cliente.get('id'),
                'timestamp': datetime.now().timestamp() * 1000
            }
            
            # Enviar diretamente para SQS (mais eficiente que SNS para este caso)
            enviar_email_sqs(email_data)
            emails_enviados += 1
            
        except Exception as e:
            logger.error(f"Erro ao processar cliente {cliente.get('id', 'unknown')}: {str(e)}")
    
    # Publicar métrica no SNS para monitoring
    publicar_metrica_sns(topic_arn, {
        'campanha_id': campanha_id,
        'grupo': tipo_grupo,
        'emails_enviados': emails_enviados,
        'timestamp': datetime.now(timezone.utc).isoformat()
    })
    
    return {
        'tipo': tipo_grupo,
        'clientes_alvo': len(clientes),
        'emails_enviados': emails_enviados,
        'topic_arn': topic_arn
    }

def personalizar_conteudo(campanha: Dict, cliente: Dict, tipo_grupo: str) -> str:
    """
    Personaliza o conteúdo do email baseado no cliente e grupo
    """
    conteudo_base = campanha['conteudo']
    nome_cliente = cliente.get('nome', 'Cliente')
    
    # Personalização baseada no grupo
    if tipo_grupo == 'premium':
        conteudo_personalizado = f"""Olá {nome_cliente}!
        
Como cliente Premium, você tem acesso exclusivo a esta promoção especial!

{conteudo_base}

🎯 Benefícios Exclusivos Premium:
- Desconto adicional de 5%
- Frete grátis em todos os pedidos
- Atendimento prioritário

Aproveite esta oferta limitada!"""
        
    elif tipo_grupo == 'regiao_sul':
        conteudo_personalizado = f"""Olá {nome_cliente}!
        
Promoção especial para nossa região Sul!

{conteudo_base}

🌟 Vantagens Regionais:
- Frete grátis para sua região
- Entrega expressa disponível
- Descontos em pedidos locais

Não perca esta oportunidade!"""
        
    else:  # geral
        conteudo_personalizado = f"""Olá {nome_cliente}!
        
{conteudo_base}

📦 Aproveite nossas ofertas especiais e economize em suas entregas!

Equipe de Logística"""
    
    return conteudo_personalizado

def enviar_email_sqs(email_data: Dict) -> None:
    """
    Envia dados de email para a fila SQS
    """
    try:
        message_body = json.dumps(email_data)
        
        response = sqs_client.send_message(
            QueueUrl=SQS_EMAIL_QUEUE,
            MessageBody=message_body
        )
        
        logger.info(f"Email enviado para SQS: {email_data['destinatario']}")
        
    except Exception as e:
        logger.error(f"Erro ao enviar email para SQS: {str(e)}")
        raise

def publicar_metrica_sns(topic_arn: str, metrica: Dict) -> None:
    """
    Publica métricas no tópico SNS
    """
    try:
        message = {
            'default': f"Campanha {metrica['campanha_id']} - Grupo {metrica['grupo']}: {metrica['emails_enviados']} emails enviados",
            'sqs': json.dumps(metrica)
        }
        
        sns_client.publish(
            TopicArn=topic_arn,
            Message=json.dumps(message),
            MessageStructure='json',
            Subject=f"Métrica Campanha - {metrica['grupo']}"
        )
        
        logger.info(f"Métrica publicada no SNS: {topic_arn}")
        
    except Exception as e:
        logger.error(f"Erro ao publicar no SNS: {str(e)}")

def registrar_metrica_campanha(campanha: Dict) -> None:
    """
    Registra métricas da campanha no DynamoDB
    """
    try:
        table.put_item(Item=campanha)
        logger.info(f"Métrica registrada: {campanha['campanha_id']} - {campanha['status']}")
        
    except Exception as e:
        logger.error(f"Erro ao registrar métrica: {str(e)}")

def criar_resposta(status_code: int, body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Cria resposta HTTP padronizada
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS'
        },
        'body': json.dumps(body, ensure_ascii=False)
    }

# Dados de exemplo para teste
def criar_campanha_exemplo():
    """
    Exemplo de payload para teste
    """
    return {
        "nome": "Promoção Black Friday 2024",
        "assunto": "🔥 Black Friday - Até 50% OFF em entregas!",
        "conteudo": "Não perca a maior promoção do ano! Descontos imperdíveis em todos os nossos serviços de logística. Aproveite frete grátis e entrega expressa com preços especiais.",
        "grupos": [
            {
                "tipo": "premium",
                "clientes": [
                    {
                        "id": "1",
                        "nome": "João Silva",
                        "email": "arihenriquedev@hotmail.com",
                        "regiao": "sudeste"
                    }
                ]
            },
            {
                "tipo": "regiao_sul",
                "clientes": [
                    {
                        "id": "2", 
                        "nome": "Maria Santos",
                        "email": "1457902@sga.pucminas.br",
                        "regiao": "sul"
                    }
                ]
            }
        ]
    }