import json
import boto3
import os
import jwt
from datetime import datetime
from auth_utils import validate_jwt_token, cors_response

# AWS Services
dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')
ses = boto3.client('ses')

# Tables
notifications_table = dynamodb.Table(os.environ.get('NOTIFICATIONS_TABLE', 'dev-logistics-notifications'))
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'dev-logistics-users'))

def handler(event, context):
    try:
        # Determinar origem da invocação
        if 'Records' in event:
            # Invocado via SQS
            return process_sqs_events(event)
        elif 'action' in event:
            # Invocado diretamente por outras lambdas
            return handle_direct_action(event)
        else:
            # Invocado via API Gateway
            return handle_api_request(event, context)
            
    except Exception as e:
        print(f"Error in notificacoes lambda: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }

def handle_api_request(event, context):
    """Handle direct API Gateway requests"""
    
    # Validar JWT token para todas as rotas exceto OPTIONS
    if event.get('httpMethod') != 'OPTIONS':
        user_payload = validate_jwt_token(event)
        if not user_payload:
            return cors_response(401, {'message': 'Token inválido ou expirado'})
        
        # Adicionar informações do usuário ao evento
        event['user'] = user_payload
    
    http_method = event['httpMethod']
    path_parameters = event.get('pathParameters', {})
    
    if http_method == 'GET':
        if 'destinatario' in event.get('resource', ''):
            return get_notifications(path_parameters['userId'], event.get('user'))
        elif 'contagem' in event.get('resource', ''):
            return get_unread_count(path_parameters['userId'], event.get('user'))
        elif 'preferencias' in event.get('resource', ''):
            return get_preferences(path_parameters['userId'], event.get('user'))
    
    elif http_method == 'POST':
        if 'preferencias' in event.get('resource', ''):
            return update_preferences(event)
            
    elif http_method == 'PATCH':
        if 'marcar-lida' in event.get('resource', ''):
            return mark_as_read(path_parameters['notificationId'])
    
    return {
        'statusCode': 405,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Method not allowed'})
    }

def process_sqs_events(event):
    """Process events from SQS queue"""
    for record in event['Records']:
        try:
            message_body = json.loads(record['body'])
            event_type = message_body.get('event')
            
            print(f"Processing event: {event_type}")
            
            if event_type == 'pedido_created':
                handle_pedido_created(message_body)
            elif event_type == 'pedido_finalizado':
                handle_pedido_finalizado(message_body)
            elif event_type == 'campanha_promocional':
                handle_campanha_promocional(message_body)
            elif event_type == 'motorista_proximo':
                handle_motorista_proximo(message_body)
            elif event_type == 'coleta_confirmada':
                handle_coleta_confirmada(message_body)
            elif event_type == 'motorista_chegou_coleta':
                handle_motorista_chegou_coleta(message_body)
            elif event_type == 'pedido_aceito':
                handle_pedido_aceito(message_body)
            elif event_type == 'sem_motoristas_disponiveis':
                handle_sem_motoristas_disponiveis(message_body)
            elif event_type == 'status_veiculo_alterado':
                handle_status_veiculo_alterado(message_body)
            elif event_type == 'alerta_incidente':
                handle_alerta_incidente(message_body)
            elif event_type == 'pedido_cancelado':
                handle_pedido_cancelado(message_body)
            elif event_type == 'motorista_chegou_destino':
                handle_motorista_chegou_destino(message_body)
            elif event_type == 'atraso_estimado':
                handle_atraso_estimado(message_body)
            else:
                print(f"Unknown event type: {event_type}")
                
        except Exception as e:
            print(f"Error processing SQS record: {str(e)}")
    
    return {'statusCode': 200}

def handle_pedido_created(message):
    """Notificar que pedido foi criado"""
    pedido_id = message.get('pedido_id')
    cliente_id = message.get('cliente_id')
    
    # Buscar dados do cliente
    client_response = users_table.get_item(Key={'id': str(cliente_id)})
    if 'Item' not in client_response:
        return
    
    cliente = client_response['Item']
    
    # Criar notificação
    notification = {
        'id': f"notif_{pedido_id}_{int(datetime.now().timestamp())}",
        'destinatarioId': cliente_id,
        'tipo': 'PEDIDO_CRIADO',
        'titulo': 'Pedido Criado!',
        'conteudo': f'Seu pedido #{pedido_id} foi criado e está procurando um motorista.',
        'dataCriacao': str(datetime.utcnow()),
        'lida': False,
        'pedidoId': pedido_id,
        'dadosEvento': {
            'evento': 'PEDIDO_CRIADO',
            'pedidoId': pedido_id,
            'clienteId': cliente_id,
            'dados': {
                'status': 'PROCURANDO_MOTORISTA',
                'timestamp': str(datetime.utcnow())
            }
        }
    }
    
    # Salvar notificação
    notifications_table.put_item(Item=notification)
    
    # Enviar push notification
    send_push_notification(cliente, notification)
    
    # Enviar via WebSocket
    send_websocket_notification(cliente_id, notification)

def handle_pedido_finalizado(message):
    """Notificar finalização de pedido"""
    pedido_id = message.get('pedido_id')
    cliente_id = message.get('cliente_id')
    motorista_id = message.get('motorista_id')
    
    # Notificar cliente
    notify_pedido_finalizado_cliente(pedido_id, cliente_id)
    
    # Notificar motorista
    if motorista_id:
        notify_pedido_finalizado_motorista(pedido_id, motorista_id)
    
    # Enviar emails de resumo
    send_completion_emails(pedido_id, cliente_id, motorista_id)

def notify_pedido_finalizado_cliente(pedido_id, cliente_id):
    """Notificar cliente sobre finalização"""
    client_response = users_table.get_item(Key={'id': str(cliente_id)})
    if 'Item' not in client_response:
        return
    
    cliente = client_response['Item']
    
    notification = {
        'id': f"completion_{pedido_id}_{int(datetime.now().timestamp())}",
        'destinatarioId': cliente_id,
        'tipo': 'PEDIDO_ENTREGUE',
        'titulo': 'Pedido Concluído! 🎉',
        'conteudo': f'Seu pedido #{pedido_id} foi entregue com sucesso! Avalie o serviço prestado.',
        'dataCriacao': str(datetime.utcnow()),
        'lida': False,
        'pedidoId': pedido_id,
        'dadosEvento': {
            'evento': 'PEDIDO_ENTREGUE',
            'pedidoId': pedido_id,
            'clienteId': cliente_id,
            'dados': {
                'status': 'ENTREGUE',
                'timestamp': str(datetime.utcnow())
            }
        }
    }
    
    notifications_table.put_item(Item=notification)
    send_push_notification(cliente, notification)
    send_websocket_notification(cliente_id, notification)

def notify_pedido_finalizado_motorista(pedido_id, motorista_id):
    """Notificar motorista sobre finalização"""
    motorista_response = users_table.get_item(Key={'id': str(motorista_id)})
    if 'Item' not in motorista_response:
        return
    
    motorista = motorista_response['Item']
    
    notification = {
        'id': f"completion_driver_{pedido_id}_{int(datetime.now().timestamp())}",
        'destinatarioId': motorista_id,
        'tipo': 'ENTREGA_CONCLUIDA',
        'titulo': 'Entrega Finalizada! ✅',
        'conteudo': f'Parabéns! Você finalizou a entrega do pedido #{pedido_id}.',
        'dataCriacao': str(datetime.utcnow()),
        'lida': False,
        'pedidoId': pedido_id,
        'dadosEvento': {
            'evento': 'ENTREGA_CONCLUIDA',
            'pedidoId': pedido_id,
            'motoristaId': motorista_id,
            'dados': {
                'status': 'FINALIZADA',
                'timestamp': str(datetime.utcnow())
            }
        }
    }
    
    notifications_table.put_item(Item=notification)
    send_push_notification(motorista, notification)
    send_websocket_notification(motorista_id, notification)

def send_completion_emails(pedido_id, cliente_id, motorista_id):
    """Enviar emails de resumo da entrega"""
    try:
        # Email para cliente
        send_completion_email_cliente(pedido_id, cliente_id)
        
        # Email para motorista
        if motorista_id:
            send_completion_email_motorista(pedido_id, motorista_id)
            
    except Exception as e:
        print(f"Error sending completion emails: {str(e)}")

def handle_motorista_proximo(message):
    """Notificar que motorista está próximo"""
    pedido_id = message.get('pedido_id')
    cliente_id = message.get('cliente_id')
    distancia_km = message.get('distancia_km', 0.5)
    
    # Buscar dados do cliente
    client_response = users_table.get_item(Key={'id': str(cliente_id)})
    if 'Item' not in client_response:
        return
    
    cliente = client_response['Item']
    
    # Criar notificação
    notification = {
        'id': f"proximity_{pedido_id}_{int(datetime.now().timestamp())}",
        'destinatarioId': cliente_id,
        'tipo': 'MOTORISTA_PROXIMO',
        'titulo': 'Motorista Chegando! 🚗',
        'conteudo': f'O motorista está a {distancia_km}km do destino. Prepare-se para receber seu pedido #{pedido_id}!',
        'dataCriacao': str(datetime.utcnow()),
        'lida': False,
        'pedidoId': pedido_id,
        'dadosEvento': {
            'evento': 'MOTORISTA_PROXIMO',
            'pedidoId': pedido_id,
            'clienteId': cliente_id,
            'dados': {
                'distancia_km': distancia_km,
                'timestamp': str(datetime.utcnow())
            }
        }
    }
    
    # Salvar notificação
    notifications_table.put_item(Item=notification)
    
    # Enviar push notification
    send_push_notification(cliente, notification)
    send_websocket_notification(cliente_id, notification)

def handle_coleta_confirmada(message):
    """Notificar que coleta foi confirmada"""
    pedido_id = message.get('pedido_id')
    motorista_id = message.get('motorista_id')
    
    # Buscar dados do pedido para encontrar o cliente
    try:
        pedidos_table = dynamodb.Table(os.environ.get('PEDIDOS_TABLE', 'dev-logistics-pedidos'))
        pedido_response = pedidos_table.get_item(Key={'id': str(pedido_id)})
        
        if 'Item' not in pedido_response:
            return
        
        pedido = pedido_response['Item']
        cliente_id = pedido.get('clienteId')
        
        if not cliente_id:
            return
        
        # Buscar dados do cliente
        client_response = users_table.get_item(Key={'id': str(cliente_id)})
        if 'Item' not in client_response:
            return
        
        cliente = client_response['Item']
        
        # Criar notificação
        notification = {
            'id': f"pickup_{pedido_id}_{int(datetime.now().timestamp())}",
            'destinatarioId': cliente_id,
            'tipo': 'COLETA_CONFIRMADA',
            'titulo': 'Coleta Confirmada! 📦',
            'conteudo': f'O motorista coletou seu pedido #{pedido_id} e está a caminho do destino!',
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'pedidoId': pedido_id,
            'dadosEvento': {
                'evento': 'COLETA_CONFIRMADA',
                'pedidoId': pedido_id,
                'clienteId': cliente_id,
                'motoristaId': motorista_id,
                'dados': {
                    'status': 'EM_TRANSITO',
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Salvar notificação
        notifications_table.put_item(Item=notification)
        
        # Enviar push notification
        send_push_notification(cliente, notification)
        send_websocket_notification(cliente_id, notification)
        
    except Exception as e:
        print(f"Error handling coleta confirmada: {str(e)}")

def handle_motorista_chegou_coleta(message):
    """Notificar que motorista chegou para coleta"""
    pedido_id = message.get('pedido_id')
    cliente_id = message.get('cliente_id')
    
    # Buscar dados do cliente
    client_response = users_table.get_item(Key={'id': str(cliente_id)})
    if 'Item' not in client_response:
        return
    
    cliente = client_response['Item']
    
    # Criar notificação
    notification = {
        'id': f"arrival_{pedido_id}_{int(datetime.now().timestamp())}",
        'destinatarioId': cliente_id,
        'tipo': 'MOTORISTA_CHEGOU',
        'titulo': 'Motorista Chegou! 🚛',
        'conteudo': f'O motorista chegou para coletar seu pedido #{pedido_id}. Prepare o item para entrega!',
        'dataCriacao': str(datetime.utcnow()),
        'lida': False,
        'pedidoId': pedido_id,
        'dadosEvento': {
            'evento': 'MOTORISTA_CHEGOU',
            'pedidoId': pedido_id,
            'clienteId': cliente_id,
            'dados': {
                'status': 'AGUARDANDO_COLETA',
                'timestamp': str(datetime.utcnow())
            }
        }
    }
    
    # Salvar notificação
    notifications_table.put_item(Item=notification)
    
    # Enviar push notification
    send_push_notification(cliente, notification)
    send_websocket_notification(cliente_id, notification)

def send_completion_email_cliente(pedido_id, cliente_id):
    """Email de conclusão para cliente"""
    client_response = users_table.get_item(Key={'id': str(cliente_id)})
    if 'Item' not in client_response:
        return
    
    cliente = client_response['Item']
    
    if not cliente.get('email'):
        return
    
    subject = "Entrega Concluída - Logistics Platform"
    
    html_body = f"""
    <html>
    <body>
        <h2>🎉 Entrega Concluída!</h2>
        <p>Olá <strong>{cliente['name']}</strong>,</p>
        
        <p>Seu pedido <strong>#{pedido_id}</strong> foi entregue com sucesso!</p>
        
        <div style="background-color: #f0f9ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3>Detalhes da Entrega:</h3>
            <ul>
                <li><strong>Pedido:</strong> #{pedido_id}</li>
                <li><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</li>
                <li><strong>Status:</strong> Entregue ✅</li>
            </ul>
        </div>
        
        <p>🌟 <strong>Avalie nosso serviço!</strong> Sua opinião é muito importante para nós.</p>
        
        <p>Obrigado por escolher a Logistics Platform!</p>
        
        <hr>
        <small>Este é um email automático. Não responda a esta mensagem.</small>
    </body>
    </html>
    """
    
    try:
        ses.send_email(
            Source='noreply@logistics.com',
            Destination={'ToAddresses': [cliente['email']]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Html': {'Data': html_body}}
            }
        )
        print(f"Completion email sent to client: {cliente['email']}")
    except Exception as e:
        print(f"Error sending email to client: {str(e)}")

def send_completion_email_motorista(pedido_id, motorista_id):
    """Email de conclusão para motorista"""
    motorista_response = users_table.get_item(Key={'id': str(motorista_id)})
    if 'Item' not in motorista_response:
        return
    
    motorista = motorista_response['Item']
    
    if not motorista.get('email'):
        return
    
    subject = "Entrega Finalizada - Logistics Platform"
    
    html_body = f"""
    <html>
    <body>
        <h2>✅ Entrega Finalizada!</h2>
        <p>Olá <strong>{motorista['name']}</strong>,</p>
        
        <p>Parabéns! Você finalizou com sucesso a entrega do pedido <strong>#{pedido_id}</strong>!</p>
        
        <div style="background-color: #f0f9ff; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3>Detalhes da Entrega:</h3>
            <ul>
                <li><strong>Pedido:</strong> #{pedido_id}</li>
                <li><strong>Data:</strong> {datetime.now().strftime('%d/%m/%Y às %H:%M')}</li>
                <li><strong>Status:</strong> Entregue ✅</li>
                <li><strong>Motorista:</strong> {motorista['name']}</li>
            </ul>
        </div>
        
        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <h3>💰 Pagamento</h3>
            <p>O pagamento desta entrega será processado em até 2 dias úteis.</p>
        </div>
        
        <p>🚛 Obrigado por fazer parte da nossa equipe de entregadores!</p>
        
        <p>Continue assim e mantenha sua excelente avaliação!</p>
        
        <hr>
        <small>Este é um email automático. Não responda a esta mensagem.</small>
    </body>
    </html>
    """
    
    try:
        ses.send_email(
            Source='noreply@logistics.com',
            Destination={'ToAddresses': [motorista['email']]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Html': {'Data': html_body}}
            }
        )
        print(f"Completion email sent to driver: {motorista['email']}")
    except Exception as e:
        print(f"Error sending email to driver: {str(e)}")

def handle_campanha_promocional(message):
    """Processar campanhas promocionais com segmentação"""
    campanha_tipo = message.get('campanha_tipo', 'geral')
    desconto = message.get('desconto', '10%')
    titulo = message.get('titulo', 'Promoção Especial!')
    conteudo = message.get('conteudo', 'Aproveite nossa promoção!')
    
    # Segmentação baseada no tipo
    if campanha_tipo == 'premium':
        segment_and_notify_premium(titulo, conteudo, desconto)
    elif campanha_tipo == 'regiao_sul':
        segment_and_notify_region(titulo, conteudo, 'sul')
    else:
        broadcast_campaign(titulo, conteudo)

def segment_and_notify_premium(titulo, conteudo, desconto):
    """Notificar clientes premium"""
    # Buscar clientes premium (mais de 10 pedidos)
    # Isso seria uma query mais complexa, simulando aqui
    premium_topic_arn = os.environ.get('SNS_PREMIUM_TOPIC_ARN')
    
    if premium_topic_arn:
        enhanced_message = f"{conteudo} Desconto especial de {desconto} para clientes VIP!"
        
        sns.publish(
            TopicArn=premium_topic_arn,
            Subject=titulo,
            Message=json.dumps({
                'default': enhanced_message,
                'tipo': 'campanha_premium',
                'desconto': desconto
            }),
            MessageStructure='json'
        )

def segment_and_notify_region(titulo, conteudo, regiao):
    """Notificar clientes por região"""
    regional_topic_arn = os.environ.get('SNS_REGIONAL_TOPIC_ARN')
    
    if regional_topic_arn:
        enhanced_message = f"{conteudo} Promoção especial para a região {regiao.title()}!"
        
        sns.publish(
            TopicArn=regional_topic_arn,
            Subject=titulo,
            Message=json.dumps({
                'default': enhanced_message,
                'tipo': 'campanha_regional',
                'regiao': regiao
            }),
            MessageStructure='json'
        )
        
        print(f"Regional campaign sent to {regiao}")

def broadcast_campaign(titulo, conteudo):
    """Broadcast para todos os clientes"""
    general_topic_arn = os.environ.get('SNS_GENERAL_TOPIC_ARN')
    
    if general_topic_arn:
        sns.publish(
            TopicArn=general_topic_arn,
            Subject=titulo,
            Message=json.dumps({
                'default': conteudo,
                'tipo': 'campanha_geral'
            }),
            MessageStructure='json'
        )

def send_push_notification(user, notification):
    """Enviar push notification via SNS"""
    try:
        # Aqui você usaria o endpoint SNS do dispositivo do usuário
        # Por enquanto, apenas registramos
        print(f"Push notification sent to user {user['id']}: {notification['titulo']}")
        
        # Em produção, você faria:
        # sns.publish(
        #     TargetArn=user['device_token_arn'],
        #     Message=json.dumps({
        #         'default': notification['conteudo'],
        #         'APNS': json.dumps({
        #             'aps': {
        #                 'alert': {
        #                     'title': notification['titulo'],
        #                     'body': notification['conteudo']
        #                 },
        #                 'badge': 1
        #             }
        #         }),
        #         'GCM': json.dumps({
        #             'data': {
        #                 'title': notification['titulo'],
        #                 'message': notification['conteudo'],
        #                 'pedido_id': notification.get('pedidoId')
        #             }
        #         })
        #     }),
        #     MessageStructure='json'
        # )
        
    except Exception as e:
        print(f"Error sending push notification: {str(e)}")

def get_notifications(user_id, user_info):
    """Buscar notificações do usuário"""
    try:
        # Validar se o usuário pode acessar as notificações
        if not user_info:
            return cors_response(401, {'message': 'Token inválido ou expirado'})
        
        # Verificar se o usuário pode acessar as notificações do user_id solicitado
        if str(user_info['id']) != str(user_id):
            return cors_response(403, {'message': 'Acesso negado. Você só pode visualizar suas próprias notificações'})
        
        response = notifications_table.scan(
            FilterExpression='destinatarioId = :user_id',
            ExpressionAttributeValues={':user_id': int(user_id)}
        )
        
        notifications = response.get('Items', [])
        
        # Formatar para compatibilidade com Flutter
        formatted_notifications = []
        for notif in notifications:
            formatted_notifications.append({
                'id': int(notif['id'].split('_')[-1]) if '_' in notif['id'] else int(notif['id']),
                'destinatarioId': notif['destinatarioId'],
                'tipo': notif['tipo'],
                'titulo': notif['titulo'],
                'conteudo': notif['conteudo'],
                'dataCriacao': notif['dataCriacao'],
                'lida': notif['lida'],
                'dadosEvento': notif.get('dadosEvento', {})
            })
        
        return cors_response(200, formatted_notifications)
        
    except Exception as e:
        print(f"Error getting notifications: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar notificações: {str(e)}'})

def get_unread_count(user_id, user_info):
    """Contar notificações não lidas do usuário"""
    try:
        # Validar se o usuário pode acessar as notificações
        if not user_info:
            return cors_response(401, {'message': 'Token inválido ou expirado'})
        
        # Verificar se o usuário pode acessar as notificações do user_id solicitado
        if str(user_info['id']) != str(user_id):
            return cors_response(403, {'message': 'Acesso negado. Você só pode visualizar suas próprias notificações'})
        
        response = notifications_table.scan(
            FilterExpression='destinatarioId = :user_id AND lida = :lida',
            ExpressionAttributeValues={
                ':user_id': int(user_id),
                ':lida': False
            }
        )
        
        count = len(response.get('Items', []))
        
        return cors_response(200, {'count': count})
        
    except Exception as e:
        print(f"Error getting unread count: {str(e)}")
        return cors_response(500, {'message': f'Erro ao contar notificações: {str(e)}'})

def mark_as_read(notification_id):
    """Marcar notificação como lida"""
    try:
        notifications_table.update_item(
            Key={'id': str(notification_id)},
            UpdateExpression='SET lida = :lida',
            ExpressionAttributeValues={':lida': True}
        )
        
        return {
            'statusCode': 204,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': ''
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }

def update_preferences(event):
    """Atualizar preferências de notificação"""
    try:
        body = json.loads(event['body'])
        
        # Salvar preferências na tabela de usuários ou preferências
        user_id = body['usuarioId']
        tipo_preferido = body['tipoPreferido']
        email = body.get('email')
        
        # Atualizar na tabela de usuários
        update_expression = 'SET notification_preferences = :prefs'
        expression_values = {
            ':prefs': {
                'tipo': tipo_preferido,
                'email': email,
                'push_enabled': tipo_preferido in ['PUSH', 'AMBOS'],
                'email_enabled': tipo_preferido in ['EMAIL', 'AMBOS']
            }
        }
        
        users_table.update_item(
            Key={'id': str(user_id)},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Preferências atualizadas com sucesso'})
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Erro: {str(e)}'})
        }

def get_preferences(user_id, user_info):
    """Buscar preferências de notificação"""
    try:
        # Validar se o usuário pode acessar as preferências
        if not user_info:
            return cors_response(401, {'message': 'Token inválido ou expirado'})
        
        # Verificar se o usuário pode acessar as preferências do user_id solicitado
        if str(user_info['id']) != str(user_id):
            return cors_response(403, {'message': 'Acesso negado. Você só pode visualizar suas próprias preferências'})
        
        response = users_table.get_item(Key={'id': str(user_id)})
        
        if 'Item' not in response:
            return cors_response(404, {'message': 'Usuário não encontrado'})
        
        user = response['Item']
        preferences = user.get('notification_preferences', {
            'tipo': 'AMBOS',
            'email': user.get('email'),
            'push_enabled': True,
            'email_enabled': True
        })
        
        return cors_response(200, preferences)
        
    except Exception as e:
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def send_websocket_notification(user_id, notification):
    """Enviar notificação via WebSocket"""
    try:
        # Importar a função do WebSocket Lambda
        import boto3
        lambda_client = boto3.client('lambda')
        
        # Invocar a função WebSocket Lambda para enviar notificação
        websocket_lambda_name = os.environ.get('WEBSOCKET_LAMBDA_NAME', 'dev-logistics-websocket')
        
        payload = {
            'action': 'send_notification',
            'userId': int(user_id),  
            'notification': {
                'tipo': notification['tipo'],
                'conteudo': notification['conteudo'],
                'dadosEvento': notification.get('dadosEvento', {})
            }
        }
        
        lambda_client.invoke(
            FunctionName=websocket_lambda_name,
            InvocationType='Event',  # Asíncrono
            Payload=json.dumps(payload)
        )
        
        print(f"WebSocket notification sent to user {user_id}")
        
    except Exception as e:
        print(f"Error sending WebSocket notification: {str(e)}")
        # Não falhar a operação principal se WebSocket falhar

def handle_direct_action(event):
    """
    Handle direct action from other Lambda functions (Smart Routing)
    """
    try:
        action = event.get('action')
        
        if action == 'send_driver_offer':
            motorista_id = event.get('motorista_id')
            notification = event.get('notification')
            
            # Criar notificação de oferta no banco
            save_driver_offer_notification(motorista_id, notification)
            
            # Enviar via WebSocket
            send_websocket_notification(motorista_id, notification)
            
            return {'statusCode': 200, 'body': 'Driver offer notification sent'}
            
        elif action == 'send_driver_notification':
            motorista_id = event.get('motorista_id')
            notification = event.get('notification')
            
            # Salvar notificação
            save_driver_notification(motorista_id, notification)
            
            # Enviar via WebSocket
            send_websocket_notification(motorista_id, notification)
            
            return {'statusCode': 200, 'body': 'Driver notification sent'}
        
        else:
            return {'statusCode': 400, 'body': f'Unknown action: {action}'}
            
    except Exception as e:
        print(f"Error in handle_direct_action: {str(e)}")
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}

def save_driver_offer_notification(motorista_id: str, notification: dict):
    """
    Salvar notificação de oferta para motorista
    """
    try:
        dados_evento = notification.get('dadosEvento', {})
        
        notification_item = {
            'id': f"offer_{dados_evento.get('ofertaId', '')}_{int(datetime.now().timestamp())}",
            'destinatarioId': int(motorista_id),
            'tipo': notification['tipo'],
            'titulo': notification['titulo'],
            'conteudo': notification['conteudo'],
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'dadosEvento': dados_evento
        }
        
        notifications_table.put_item(Item=notification_item)
        print(f"Driver offer notification saved for motorista {motorista_id}")
        
    except Exception as e:
        print(f"Error saving driver offer notification: {str(e)}")

def save_driver_notification(motorista_id: str, notification: dict):
    """
    Salvar notificação geral para motorista
    """
    try:
        dados_evento = notification.get('dadosEvento', {})
        
        notification_item = {
            'id': f"driver_{notification['tipo'].lower()}_{int(datetime.now().timestamp())}",
            'destinatarioId': int(motorista_id),
            'tipo': notification['tipo'],
            'titulo': notification['titulo'],
            'conteudo': notification['conteudo'],
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'dadosEvento': dados_evento
        }
        
        notifications_table.put_item(Item=notification_item)
        print(f"Driver notification saved for motorista {motorista_id}")
        
    except Exception as e:
        print(f"Error saving driver notification: {str(e)}")

def handle_pedido_aceito(message):
    """
    Notificar cliente que pedido foi aceito por motorista
    """
    try:
        pedido_id = message.get('pedido_id')
        motorista_id = message.get('motorista_id')
        
        # Buscar dados do pedido para encontrar o cliente
        pedidos_table = dynamodb.Table(os.environ.get('PEDIDOS_TABLE', 'dev-logistics-pedidos'))
        pedido_response = pedidos_table.get_item(Key={'id': str(pedido_id)})
        
        if 'Item' not in pedido_response:
            return
        
        pedido = pedido_response['Item']
        cliente_id = pedido.get('clienteId')
        
        if not cliente_id:
            return
        
        # Buscar dados do motorista
        motorista_response = users_table.get_item(Key={'id': str(motorista_id)})
        if 'Item' not in motorista_response:
            return
        
        motorista = motorista_response['Item']
        
        # Buscar dados do cliente
        client_response = users_table.get_item(Key={'id': str(cliente_id)})
        if 'Item' not in client_response:
            return
        
        cliente = client_response['Item']
        
        # Criar notificação
        notification = {
            'id': f"accepted_{pedido_id}_{int(datetime.now().timestamp())}",
            'destinatarioId': int(cliente_id),
            'tipo': 'PEDIDO_ACEITO',
            'titulo': 'Pedido Aceito! 🎉',
            'conteudo': f'Seu pedido #{pedido_id} foi aceito pelo motorista {motorista.get("name", "Motorista")}. Ele está a caminho!',
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'pedidoId': pedido_id,
            'dadosEvento': {
                'evento': 'PEDIDO_ACEITO',
                'pedidoId': pedido_id,
                'clienteId': cliente_id,
                'motoristaId': motorista_id,
                'dados': {
                    'motorista_nome': motorista.get('name', 'Motorista'),
                    'motorista_veiculo': motorista.get('veiculo_tipo', 'MOTO'),
                    'status': 'EM_ROTA',
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Salvar notificação
        notifications_table.put_item(Item=notification)
        
        # Enviar push notification
        send_push_notification(cliente, notification)
        
        # Enviar via WebSocket
        send_websocket_notification(cliente_id, notification)
        
        print(f"Pedido aceito notification sent to client {cliente_id}")
        
    except Exception as e:
        print(f"Error handling pedido aceito: {str(e)}")

def handle_sem_motoristas_disponiveis(message):
    """
    Notificar cliente que não há motoristas disponíveis
    """
    try:
        pedido_id = message.get('pedido_id')
        cliente_id = message.get('cliente_id')
        
        # Buscar dados do cliente
        client_response = users_table.get_item(Key={'id': str(cliente_id)})
        if 'Item' not in client_response:
            return
        
        cliente = client_response['Item']
        
        # Criar notificação
        notification = {
            'id': f"no_drivers_{pedido_id}_{int(datetime.now().timestamp())}",
            'destinatarioId': int(cliente_id),
            'tipo': 'SEM_MOTORISTAS_DISPONIVEIS',
            'titulo': 'Buscando Motorista... ⏳',
            'conteudo': f'Estamos buscando um motorista para seu pedido #{pedido_id}. Isso pode demorar alguns minutos.',
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'pedidoId': pedido_id,
            'dadosEvento': {
                'evento': 'SEM_MOTORISTAS_DISPONIVEIS',
                'pedidoId': pedido_id,
                'clienteId': cliente_id,
                'dados': {
                    'status': 'BUSCANDO_MOTORISTA',
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Salvar notificação
        notifications_table.put_item(Item=notification)
        
        # Enviar push notification
        send_push_notification(cliente, notification)
        
        # Enviar via WebSocket
        send_websocket_notification(cliente_id, notification)
        
        print(f"No drivers available notification sent to client {cliente_id}")
        
    except Exception as e:
        print(f"Error handling sem motoristas disponiveis: {str(e)}")

def handle_status_veiculo_alterado(message):
    """
    Notificar sobre alteração no status do veículo do motorista
    """
    try:
        motorista_id = message.get('motorista_id')
        novo_status = message.get('novo_status')
        motivo = message.get('motivo', '')
        
        # Buscar dados do motorista
        motorista_response = users_table.get_item(Key={'id': str(motorista_id)})
        if 'Item' not in motorista_response:
            return
        
        motorista = motorista_response['Item']
        
        # Determinar título e conteúdo baseado no status
        if novo_status == 'QUEBRADO':
            titulo = 'Veículo em Manutenção 🔧'
            conteudo = f'Seu veículo foi marcado como em manutenção. {motivo}' if motivo else 'Seu veículo foi marcado como em manutenção.'
        elif novo_status == 'DISPONIVEL':
            titulo = 'Veículo Disponível ✅'
            conteudo = 'Seu veículo está disponível para entregas novamente!'
        elif novo_status == 'OCUPADO':
            titulo = 'Veículo em Uso 🚚'
            conteudo = 'Seu veículo está sendo usado em uma entrega.'
        else:
            titulo = 'Status do Veículo Alterado'
            conteudo = f'Status do seu veículo foi alterado para: {novo_status}'
        
        # Criar notificação
        notification = {
            'id': f"vehicle_status_{motorista_id}_{int(datetime.now().timestamp())}",
            'destinatarioId': int(motorista_id),
            'tipo': 'STATUS_VEICULO_ALTERADO',
            'titulo': titulo,
            'conteudo': conteudo,
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'dadosEvento': {
                'evento': 'STATUS_VEICULO_ALTERADO',
                'motoristaId': motorista_id,
                'dados': {
                    'novo_status': novo_status,
                    'status_anterior': message.get('status_anterior', ''),
                    'motivo': motivo,
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Salvar notificação
        notifications_table.put_item(Item=notification)
        
        # Enviar push notification
        send_push_notification(motorista, notification)
        
        # Enviar via WebSocket
        send_websocket_notification(motorista_id, notification)
        
        print(f"Vehicle status notification sent to driver {motorista_id}")
        
    except Exception as e:
        print(f"Error handling status veiculo alterado: {str(e)}")

def handle_alerta_incidente(message):
    """
    Notificar sobre incidentes/alertas no sistema
    """
    try:
        tipo_incidente = message.get('tipo_incidente')
        descricao = message.get('descricao')
        gravidade = message.get('gravidade', 'MEDIA')  # BAIXA, MEDIA, ALTA, CRITICA
        afetados = message.get('afetados', [])  # Lista de user_ids afetados
        pedido_id = message.get('pedido_id')  # Se relacionado a um pedido específico
        
        # Determinar título baseado no tipo de incidente
        if tipo_incidente == 'TRANSITO':
            titulo = 'Alerta de Trânsito 🚦'
        elif tipo_incidente == 'CLIMA':
            titulo = 'Alerta Climático 🌧️'
        elif tipo_incidente == 'SISTEMA':
            titulo = 'Alerta do Sistema ⚠️'
        elif tipo_incidente == 'SEGURANCA':
            titulo = 'Alerta de Segurança 🚨'
        else:
            titulo = 'Alerta Importante ⚠️'
        
        # Se não há afetados específicos, notificar todos os motoristas ativos
        if not afetados:
            afetados = get_active_drivers()
        
        # Enviar notificação para cada afetado
        for user_id in afetados:
            try:
                # Buscar dados do usuário
                user_response = users_table.get_item(Key={'id': str(user_id)})
                if 'Item' not in user_response:
                    continue
                
                user = user_response['Item']
                
                # Criar notificação
                notification = {
                    'id': f"incident_{tipo_incidente.lower()}_{user_id}_{int(datetime.now().timestamp())}",
                    'destinatarioId': int(user_id),
                    'tipo': 'ALERTA_INCIDENTE',
                    'titulo': titulo,
                    'conteudo': descricao,
                    'dataCriacao': str(datetime.utcnow()),
                    'lida': False,
                    'dadosEvento': {
                        'evento': 'ALERTA_INCIDENTE',
                        'dados': {
                            'tipo_incidente': tipo_incidente,
                            'gravidade': gravidade,
                            'descricao': descricao,
                            'pedido_id': pedido_id,
                            'timestamp': str(datetime.utcnow())
                        }
                    }
                }
                
                # Salvar notificação
                notifications_table.put_item(Item=notification)
                
                # Enviar push notification
                send_push_notification(user, notification)
                
                # Enviar via WebSocket
                send_websocket_notification(user_id, notification)
                
            except Exception as e:
                print(f"Error sending incident alert to user {user_id}: {str(e)}")
        
        print(f"Incident alert sent to {len(afetados)} users")
        
    except Exception as e:
        print(f"Error handling alerta incidente: {str(e)}")

def handle_pedido_cancelado(message):
    """
    Notificar sobre cancelamento de pedido
    """
    try:
        pedido_id = message.get('pedido_id')
        cliente_id = message.get('cliente_id')
        motorista_id = message.get('motorista_id')
        motivo_cancelamento = message.get('motivo', 'Não especificado')
        cancelado_por = message.get('cancelado_por', 'sistema')  # cliente, motorista, sistema
        
        # Notificar cliente
        if cliente_id:
            client_response = users_table.get_item(Key={'id': str(cliente_id)})
            if 'Item' in client_response:
                cliente = client_response['Item']
                
                if cancelado_por == 'motorista':
                    titulo = 'Pedido Cancelado pelo Motorista ❌'
                    conteudo = f'Seu pedido #{pedido_id} foi cancelado pelo motorista. Motivo: {motivo_cancelamento}'
                elif cancelado_por == 'sistema':
                    titulo = 'Pedido Cancelado ❌'
                    conteudo = f'Seu pedido #{pedido_id} foi cancelado. Motivo: {motivo_cancelamento}'
                else:
                    titulo = 'Pedido Cancelado ❌'
                    conteudo = f'Seu pedido #{pedido_id} foi cancelado. Motivo: {motivo_cancelamento}'
                
                notification = {
                    'id': f"cancelled_client_{pedido_id}_{int(datetime.now().timestamp())}",
                    'destinatarioId': int(cliente_id),
                    'tipo': 'PEDIDO_CANCELADO',
                    'titulo': titulo,
                    'conteudo': conteudo,
                    'dataCriacao': str(datetime.utcnow()),
                    'lida': False,
                    'pedidoId': pedido_id,
                    'dadosEvento': {
                        'evento': 'PEDIDO_CANCELADO',
                        'pedidoId': pedido_id,
                        'clienteId': cliente_id,
                        'dados': {
                            'motivo': motivo_cancelamento,
                            'cancelado_por': cancelado_por,
                            'timestamp': str(datetime.utcnow())
                        }
                    }
                }
                
                notifications_table.put_item(Item=notification)
                send_push_notification(cliente, notification)
                send_websocket_notification(cliente_id, notification)
        
        # Notificar motorista se aplicável
        if motorista_id and cancelado_por != 'motorista':
            motorista_response = users_table.get_item(Key={'id': str(motorista_id)})
            if 'Item' in motorista_response:
                motorista = motorista_response['Item']
                
                if cancelado_por == 'cliente':
                    titulo = 'Pedido Cancelado pelo Cliente ❌'
                    conteudo = f'O pedido #{pedido_id} foi cancelado pelo cliente. Motivo: {motivo_cancelamento}'
                else:
                    titulo = 'Pedido Cancelado ❌'
                    conteudo = f'O pedido #{pedido_id} foi cancelado. Motivo: {motivo_cancelamento}'
                
                notification = {
                    'id': f"cancelled_driver_{pedido_id}_{int(datetime.now().timestamp())}",
                    'destinatarioId': int(motorista_id),
                    'tipo': 'PEDIDO_CANCELADO',
                    'titulo': titulo,
                    'conteudo': conteudo,
                    'dataCriacao': str(datetime.utcnow()),
                    'lida': False,
                    'pedidoId': pedido_id,
                    'dadosEvento': {
                        'evento': 'PEDIDO_CANCELADO',
                        'pedidoId': pedido_id,
                        'motoristaId': motorista_id,
                        'dados': {
                            'motivo': motivo_cancelamento,
                            'cancelado_por': cancelado_por,
                            'timestamp': str(datetime.utcnow())
                        }
                    }
                }
                
                notifications_table.put_item(Item=notification)
                send_push_notification(motorista, notification)
                send_websocket_notification(motorista_id, notification)
        
        print(f"Cancellation notifications sent for pedido {pedido_id}")
        
    except Exception as e:
        print(f"Error handling pedido cancelado: {str(e)}")

def handle_motorista_chegou_destino(message):
    """
    Notificar que motorista chegou ao destino
    """
    try:
        pedido_id = message.get('pedido_id')
        cliente_id = message.get('cliente_id')
        motorista_id = message.get('motorista_id')
        
        # Buscar dados do cliente
        client_response = users_table.get_item(Key={'id': str(cliente_id)})
        if 'Item' not in client_response:
            return
        
        cliente = client_response['Item']
        
        # Criar notificação
        notification = {
            'id': f"arrived_destination_{pedido_id}_{int(datetime.now().timestamp())}",
            'destinatarioId': int(cliente_id),
            'tipo': 'MOTORISTA_CHEGOU_DESTINO',
            'titulo': 'Motorista Chegou! 📍',
            'conteudo': f'O motorista chegou ao destino para entregar seu pedido #{pedido_id}. Prepare-se para receber!',
            'dataCriacao': str(datetime.utcnow()),
            'lida': False,
            'pedidoId': pedido_id,
            'dadosEvento': {
                'evento': 'MOTORISTA_CHEGOU_DESTINO',
                'pedidoId': pedido_id,
                'clienteId': cliente_id,
                'motoristaId': motorista_id,
                'dados': {
                    'status': 'AGUARDANDO_ENTREGA',
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Salvar notificação
        notifications_table.put_item(Item=notification)
        
        # Enviar push notification
        send_push_notification(cliente, notification)
        
        # Enviar via WebSocket
        send_websocket_notification(cliente_id, notification)
        
        print(f"Driver arrival at destination notification sent to client {cliente_id}")
        
    except Exception as e:
        print(f"Error handling motorista chegou destino: {str(e)}")

def handle_atraso_estimado(message):
    """
    Notificar sobre atraso estimado na entrega
    """
    try:
        pedido_id = message.get('pedido_id')
        cliente_id = message.get('cliente_id')
        motorista_id = message.get('motorista_id')
        atraso_minutos = message.get('atraso_minutos', 0)
        motivo = message.get('motivo', 'Não especificado')
        nova_estimativa = message.get('nova_estimativa', '')
        
        # Notificar cliente sobre o atraso
        if cliente_id:
            client_response = users_table.get_item(Key={'id': str(cliente_id)})
            if 'Item' in client_response:
                cliente = client_response['Item']
                
                if atraso_minutos > 60:
                    horas = atraso_minutos // 60
                    minutos = atraso_minutos % 60
                    tempo_str = f"{horas}h{minutos}min" if minutos > 0 else f"{horas}h"
                else:
                    tempo_str = f"{atraso_minutos} minutos"
                
                titulo = 'Atraso na Entrega ⏰'
                conteudo = f'Seu pedido #{pedido_id} está com atraso estimado de {tempo_str}. Motivo: {motivo}'
                if nova_estimativa:
                    conteudo += f' Nova estimativa: {nova_estimativa}'
                
                notification = {
                    'id': f"delay_{pedido_id}_{int(datetime.now().timestamp())}",
                    'destinatarioId': int(cliente_id),
                    'tipo': 'ATRASO_ESTIMADO',
                    'titulo': titulo,
                    'conteudo': conteudo,
                    'dataCriacao': str(datetime.utcnow()),
                    'lida': False,
                    'pedidoId': pedido_id,
                    'dadosEvento': {
                        'evento': 'ATRASO_ESTIMADO',
                        'pedidoId': pedido_id,
                        'clienteId': cliente_id,
                        'dados': {
                            'atraso_minutos': atraso_minutos,
                            'motivo': motivo,
                            'nova_estimativa': nova_estimativa,
                            'timestamp': str(datetime.utcnow())
                        }
                    }
                }
                
                notifications_table.put_item(Item=notification)
                send_push_notification(cliente, notification)
                send_websocket_notification(cliente_id, notification)
        
        print(f"Delay notification sent for pedido {pedido_id}")
        
    except Exception as e:
        print(f"Error handling atraso estimado: {str(e)}")

def get_active_drivers():
    """
    Buscar todos os motoristas ativos/disponíveis
    """
    try:
        response = users_table.scan(
            FilterExpression='#type = :user_type AND disponibilidade = :disponivel',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={
                ':user_type': 'MOTORISTA',
                ':disponivel': 'DISPONIVEL'
            }
        )
        
        drivers = response.get('Items', [])
        return [int(driver['id']) for driver in drivers]
        
    except Exception as e:
        print(f"Error getting active drivers: {str(e)}")
        return []