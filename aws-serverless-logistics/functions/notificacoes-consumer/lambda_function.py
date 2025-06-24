"""
Lambda de Notificações - Consumer de Eventos
Replica exatamente o comportamento do EventoConsumer Java
"""

import json
import boto3
import os
from datetime import datetime
from typing import Dict, List, Any, Optional

# AWS Services
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
lambda_client = boto3.client('lambda')

# Tables
notificacoes_table = dynamodb.Table(os.environ.get('NOTIFICACOES_TABLE', 'dev-logistics-notificacoes'))
preferencias_table = dynamodb.Table(os.environ.get('PREFERENCIAS_TABLE', 'dev-logistics-preferencias'))

def handler(event, context):
    """
    Handler principal - processa eventos SQS (equivale ao @RabbitListener Java)
    """
    try:
        # Processar cada record do SQS (batch processing)
        for record in event['Records']:
            try:
                # Parse da mensagem SNS dentro do SQS
                sns_message = json.loads(record['body'])
                if 'Message' in sns_message:
                    # Mensagem veio do SNS
                    event_data = json.loads(sns_message['Message'])
                else:
                    # Mensagem direta no SQS
                    event_data = json.loads(record['body'])
                
                # Processar evento (equivale ao processarEvento do Java)
                processar_evento(event_data)
                
            except Exception as e:
                print(f"Erro ao processar record: {str(e)}")
                # Em caso de erro, a mensagem volta para a fila (retry automático)
                raise e
        
        return {'statusCode': 200, 'body': 'Events processed successfully'}
        
    except Exception as e:
        print(f"Erro no handler de notificações: {str(e)}")
        raise e

def processar_evento(mensagem: Dict[str, Any]):
    """
    Processa evento individual - replica EventoConsumer.processarEvento()
    """
    try:
        print(f"Recebido evento: {mensagem}")
        
        tipo_evento = mensagem.get('evento')
        origem = mensagem.get('origem')
        dados = mensagem.get('dados', {})
        
        if not dados:
            print(f"Evento recebido sem dados: {tipo_evento}")
            return
        
        # Processar destinatários baseado no tipo de evento
        processar_destinatarios(tipo_evento, origem, dados, mensagem)
        
    except Exception as e:
        print(f"Erro ao processar evento: {str(e)}")
        raise e

def processar_destinatarios(tipo_evento: str, origem: str, dados: Dict, mensagem_completa: Dict):
    """
    Processa destinatários - replica EventoConsumer.processarDestinatarios()
    """
    try:
        # Para eventos PEDIDO_DISPONIVEL, envie apenas para motoristas
        if tipo_evento == "PEDIDO_DISPONIVEL":
            if dados.get("motoristasProximos"):
                processar_lista(dados, "motoristasProximos", tipo_evento, origem, mensagem_completa)
        else:
            # Para outros eventos (como PEDIDO_CRIADO), processe normalmente
            processar_id(dados, "clienteId", tipo_evento, origem, mensagem_completa)
            processar_id(dados, "motoristaId", tipo_evento, origem, mensagem_completa)
            
    except Exception as e:
        print(f"Erro ao processar destinatários: {str(e)}")

def processar_id(dados: Dict, campo_id: str, tipo_evento: str, origem: str, mensagem_completa: Dict):
    """
    Processa destinatário único - replica EventoConsumer.processarId()
    """
    if dados.get(campo_id) is not None:
        user_id = convert_to_int(dados.get(campo_id))
        if user_id is not None:
            criar_notificacao(user_id, tipo_evento, origem, dados, mensagem_completa)

def processar_lista(dados: Dict, campo_lista: str, tipo_evento: str, origem: str, mensagem_completa: Dict):
    """
    Processa lista de destinatários - replica EventoConsumer.processarLista()
    """
    lista_ids = dados.get(campo_lista)
    if lista_ids and isinstance(lista_ids, list):
        for item in lista_ids:
            user_id = convert_to_int(item)
            if user_id is not None:
                criar_notificacao(user_id, tipo_evento, origem, dados, mensagem_completa)

def convert_to_int(value: Any) -> Optional[int]:
    """
    Converte valor para int - replica EventoConsumer.convertToLong()
    """
    if value is None:
        return None
    
    if isinstance(value, int):
        return value
    elif isinstance(value, str):
        try:
            return int(value)
        except ValueError:
            return None
    elif isinstance(value, float):
        return int(value)
    
    return None

def criar_notificacao(destinatario_id: int, tipo_evento: str, origem: str, dados: Dict, mensagem_completa: Dict):
    """
    Cria notificação - replica EventoConsumer.criarNotificacao()
    """
    print(f"Criando notificacao para destinatário: {destinatario_id}, evento: {tipo_evento}")
    
    try:
        # Gerar conteúdo personalizado baseado no tipo de evento
        conteudo = gerar_conteudo_notificacao(tipo_evento, dados)
        
        # Criar objeto notificação (compatível com modelo Java)
        notificacao = {
            'id': f"{destinatario_id}_{tipo_evento}_{int(datetime.utcnow().timestamp())}",
            'destinatarioId': destinatario_id,
            'tipoEvento': tipo_evento,
            'origem': origem,
            'titulo': conteudo['titulo'],
            'mensagem': conteudo['mensagem'],
            'dadosEvento': mensagem_completa,
            'dataCriacao': datetime.utcnow().isoformat(),
            'status': 'NAO_LIDA',
            'ttl': int(datetime.utcnow().timestamp()) + (30 * 24 * 3600)  # 30 dias TTL
        }
        
        # Salvar no DynamoDB
        notificacoes_table.put_item(Item=notificacao)
        
        # Enviar notificação em tempo real via WebSocket
        enviar_notificacao_websocket(destinatario_id, notificacao)
        
        # Verificar preferências do usuário para outros canais (email, etc.)
        processar_canais_notificacao(destinatario_id, notificacao)
        
    except Exception as e:
        print(f"Erro ao criar notificação para destinatário {destinatario_id}: {str(e)}")

def gerar_conteudo_notificacao(tipo_evento: str, dados: Dict) -> Dict[str, str]:
    """
    Gera conteúdo da notificação - replica EventoConsumer.gerarConteudoNotificacao()
    """
    conteudo = {"titulo": "", "mensagem": ""}
    
    if tipo_evento == "PEDIDO_CRIADO":
        conteudo["titulo"] = "Novo pedido criado"
        conteudo["mensagem"] = "Seu pedido foi registrado com sucesso!"
        
    elif tipo_evento == "STATUS_ATUALIZADO":
        status = dados.get("novoStatus", "atualizado")
        conteudo["titulo"] = "Status atualizado"
        conteudo["mensagem"] = f"Seu pedido agora está {status}"
        
    elif tipo_evento == "PEDIDO_CANCELADO":
        motivo = dados.get("motivo", "")
        conteudo["titulo"] = "Pedido cancelado"
        if motivo:
            conteudo["mensagem"] = f"Seu pedido foi cancelado: {motivo}"
        else:
            conteudo["mensagem"] = "Seu pedido foi cancelado"
            
    elif tipo_evento == "PEDIDO_DISPONIVEL":
        origem_endereco = dados.get("origemEndereco", "local de coleta")
        conteudo["titulo"] = "Novo pedido disponível"
        conteudo["mensagem"] = f"Há um novo pedido disponível para coleta em {origem_endereco}"
        
    elif tipo_evento in ["INCIDENTE_REPORTADO", "ALERTA_INCIDENTE"]:
        tipo_incidente = dados.get("tipo", "incidente")
        conteudo["titulo"] = f"Alerta: {tipo_incidente}"
        conteudo["mensagem"] = "Um incidente foi reportado na sua rota"
        
    elif tipo_evento == "STATUS_VEICULO_ALTERADO":
        status_veiculo = dados.get("statusVeiculo", "")
        conteudo["titulo"] = "Status atualizado"
        conteudo["mensagem"] = f"O status do veículo foi atualizado para: {status_veiculo}"
        
    else:
        conteudo["titulo"] = "Notificação do sistema"
        conteudo["mensagem"] = f"Evento: {tipo_evento}"
    
    return conteudo

def enviar_notificacao_websocket(user_id: int, notificacao: Dict):
    """
    Envia notificação via WebSocket - replica NotificacaoWebSocketHandler.enviarNotificacao()
    """
    try:
        websocket_lambda_name = os.environ.get('WEBSOCKET_LAMBDA_NAME', 'dev-logistics-websocket')
        
        # Payload compatível com WebSocket Lambda
        payload = {
            'action': 'send_notification',
            'userId': user_id,
            'notification': {
                'tipoEvento': notificacao['tipoEvento'],
                'titulo': notificacao['titulo'],
                'mensagem': notificacao['mensagem'],
                'dadosEvento': notificacao['dadosEvento'],
                'dataCriacao': notificacao['dataCriacao']
            }
        }
        
        # Enviar via Lambda WebSocket (assíncrono)
        lambda_client.invoke(
            FunctionName=websocket_lambda_name,
            InvocationType='Event',
            Payload=json.dumps(payload)
        )
        
        print(f"Notificação WebSocket enviada para usuário {user_id}")
        
    except Exception as e:
        print(f"Erro ao enviar notificação WebSocket: {str(e)}")

def processar_canais_notificacao(user_id: int, notificacao: Dict):
    """
    Processa canais adicionais de notificação baseado nas preferências do usuário
    """
    try:
        # Buscar preferências do usuário
        response = preferencias_table.get_item(Key={'userId': user_id})
        
        if 'Item' in response:
            preferencias = response['Item']
            tipo_notificacao = preferencias.get('tipoNotificacao', 'PUSH')
            
            # Se preferir email ou ambos, enviar email
            if tipo_notificacao in ['EMAIL', 'AMBOS']:
                enviar_email(user_id, notificacao)
                
        else:
            # Preferência padrão: apenas PUSH (WebSocket)
            print(f"Preferências não encontradas para usuário {user_id}, usando padrão PUSH")
            
    except Exception as e:
        print(f"Erro ao processar canais de notificação: {str(e)}")

def enviar_email(user_id: int, notificacao: Dict):
    """
    Envia notificação por email (stub - implementar com SES se necessário)
    """
    try:
        # TODO: Implementar com Amazon SES
        print(f"Email seria enviado para usuário {user_id}: {notificacao['titulo']}")
        
    except Exception as e:
        print(f"Erro ao enviar email: {str(e)}")

def publicar_evento_sns(evento: str, origem: str, dados: Dict):
    """
    Função utilitária para publicar eventos no SNS (equivale ao RabbitTemplate Java)
    """
    try:
        sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
        if not sns_topic_arn:
            print("SNS_TOPIC_ARN não configurado")
            return
        
        # Estrutura da mensagem compatível com Java
        mensagem = {
            'evento': evento,
            'origem': origem,
            'timestamp': datetime.utcnow().isoformat(),
            'dados': dados
        }
        
        # Publicar no SNS com atributos para filtering
        sns.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps(mensagem),
            MessageAttributes={
                'evento': {
                    'DataType': 'String',
                    'StringValue': evento
                },
                'origem': {
                    'DataType': 'String', 
                    'StringValue': origem
                }
            }
        )
        
        print(f"Evento publicado no SNS: {evento} de {origem}")
        
    except Exception as e:
        print(f"Erro ao publicar evento no SNS: {str(e)}")