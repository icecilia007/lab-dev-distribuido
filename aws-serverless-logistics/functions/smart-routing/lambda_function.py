import json
import boto3
import os
import math
import jwt
from datetime import datetime, timedelta
from typing import List, Dict, Tuple

# AWS Services
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')
lambda_client = boto3.client('lambda')

# Tables
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'dev-logistics-users'))
pedidos_table = dynamodb.Table(os.environ.get('PEDIDOS_TABLE', 'dev-logistics-pedidos'))
ofertas_table = dynamodb.Table(os.environ.get('OFERTAS_TABLE', 'dev-logistics-pedido-ofertas'))

# JWT Configuration
JWT_SECRET = os.environ.get('JWT_SECRET', 'default-secret-key')
JWT_ALGORITHM = 'HS256'

def cors_response(status_code: int, body: dict) -> dict:
    """Helper function to create CORS-enabled response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'
        },
        'body': json.dumps(body)
    }

def validate_jwt_token(token: str) -> dict:
    """Validate JWT token and return user data"""
    try:
        if not token:
            raise ValueError("Token is required")
        
        # Remove Bearer prefix if present
        if token.startswith('Bearer '):
            token = token[7:]
        
        # Decode and validate token
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        
        # Check if token is expired
        if 'exp' in payload and datetime.utcnow().timestamp() > payload['exp']:
            raise ValueError("Token has expired")
        
        return payload
        
    except jwt.ExpiredSignatureError:
        raise ValueError("Token has expired")
    except jwt.InvalidTokenError:
        raise ValueError("Invalid token")
    except Exception as e:
        raise ValueError(f"Token validation error: {str(e)}")

def extract_user_from_event(event) -> dict:
    """Extract and validate user from JWT token in event"""
    try:
        # Get token from Authorization header
        headers = event.get('headers', {})
        auth_header = headers.get('Authorization') or headers.get('authorization')
        
        if not auth_header:
            raise ValueError("Authorization header is required")
        
        # Validate token and get user data
        user_data = validate_jwt_token(auth_header)
        
        return user_data
        
    except Exception as e:
        raise ValueError(f"Authentication failed: {str(e)}")

def handler(event, context):
    """
    Smart Routing Lambda - Roteamento inteligente de pedidos para motoristas
    """
    try:
        # Determinar origem da invocação
        if 'Records' in event:
            # Invocado via SQS
            return process_sqs_events(event)
        else:
            # Invocado via API Gateway
            return handle_api_request(event, context)
            
    except Exception as e:
        print(f"Error in smart-routing lambda: {str(e)}")
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def process_sqs_events(event):
    """Process events from SQS queue"""
    for record in event['Records']:
        try:
            message_body = json.loads(record['body'])
            event_type = message_body.get('event')
            
            print(f"Processing smart routing event: {event_type}")
            
            if event_type == 'pedido_created':
                handle_pedido_disponivel(message_body)
            elif event_type == 'oferta_expirada':
                handle_oferta_expirada(message_body)
            elif event_type == 'motorista_indisponivel':
                handle_motorista_indisponivel(message_body)
            else:
                print(f"Unknown smart routing event: {event_type}")
                
        except Exception as e:
            print(f"Error processing SQS record: {str(e)}")
    
    return {'statusCode': 200}

def handle_api_request(event, context):
    """Handle direct API Gateway requests"""
    http_method = event['httpMethod']
    path_parameters = event.get('pathParameters', {})
    
    # Handle OPTIONS requests for CORS
    if http_method == 'OPTIONS':
        return cors_response(200, {'message': 'OK'})
    
    # Validate JWT token for all non-OPTIONS requests
    try:
        user_data = extract_user_from_event(event)
        print(f"Authenticated user: {user_data.get('sub', 'unknown')}")
    except ValueError as e:
        print(f"Authentication error: {str(e)}")
        return cors_response(401, {'message': 'Unauthorized', 'error': str(e)})
    
    if http_method == 'POST':
        if 'ofertar-motoristas' in event.get('resource', ''):
            return ofertar_pedido_para_motoristas(event, user_data)
        elif 'aceitar' in event.get('resource', ''):
            return aceitar_oferta(event, user_data)
        elif 'rejeitar' in event.get('resource', ''):
            return rejeitar_oferta(event, user_data)
        elif 'buscar-motoristas' in event.get('resource', ''):
            return buscar_motoristas_proximos(event, user_data)
    
    elif http_method == 'GET':
        if 'ofertas' in event.get('resource', ''):
            return get_ofertas_motorista(path_parameters.get('motoristaId'), user_data)
    
    return cors_response(405, {'message': 'Method not allowed'})

def handle_pedido_disponivel(message):
    """
    Processar pedido criado e iniciar roteamento inteligente
    """
    pedido_id = message.get('pedido_id')
    cliente_id = message.get('cliente_id')
    
    if not pedido_id:
        print("Missing pedido_id in message")
        return
    
    # Buscar dados do pedido
    pedido_response = pedidos_table.get_item(Key={'id': str(pedido_id)})
    if 'Item' not in pedido_response:
        print(f"Pedido {pedido_id} not found")
        return
    
    pedido = pedido_response['Item']
    
    # Extrair localização de origem
    origem_lat = float(pedido.get('origem_latitude', 0))
    origem_lng = float(pedido.get('origem_longitude', 0))
    
    if origem_lat == 0 or origem_lng == 0:
        print(f"Pedido {pedido_id} missing location data")
        return
    
    # Buscar motoristas próximos
    motoristas_proximos = buscar_motoristas_disponiveis(
        origem_lat, 
        origem_lng, 
        raio_inicial_km=5.0,
        max_motoristas=5
    )
    
    if not motoristas_proximos:
        print(f"No drivers found for pedido {pedido_id}")
        # Tentar raio maior
        motoristas_proximos = buscar_motoristas_disponiveis(
            origem_lat, 
            origem_lng, 
            raio_inicial_km=10.0,
            max_motoristas=3
        )
    
    if motoristas_proximos:
        # Criar ofertas para os motoristas selecionados
        criar_ofertas_para_motoristas(pedido_id, motoristas_proximos)
    else:
        print(f"No drivers available for pedido {pedido_id}")
        # Notificar sistema que não há motoristas disponíveis
        notificar_sem_motoristas_disponiveis(pedido_id, cliente_id)

def buscar_motoristas_disponiveis(lat: float, lng: float, raio_inicial_km: float = 5.0, max_motoristas: int = 5) -> List[Dict]:
    """
    Buscar motoristas disponíveis próximos à localização
    """
    try:
        # Scan table for available drivers
        # Em produção, usaria uma GSI com geohash para otimizar
        response = users_table.scan(
            FilterExpression='#type = :user_type AND disponibilidade = :disponivel',
            ExpressionAttributeNames={'#type': 'type'},
            ExpressionAttributeValues={
                ':user_type': 'MOTORISTA',
                ':disponivel': 'DISPONIVEL'
            }
        )
        
        motoristas = response.get('Items', [])
        motoristas_proximos = []
        
        for motorista in motoristas:
            # Verificar se tem localização atual
            if not motorista.get('latitude_atual') or not motorista.get('longitude_atual'):
                continue
                
            motorista_lat = float(motorista['latitude_atual'])
            motorista_lng = float(motorista['longitude_atual'])
            
            # Calcular distância
            distancia_km = haversine_distance(lat, lng, motorista_lat, motorista_lng)
            
            if distancia_km <= raio_inicial_km:
                # Calcular score de prioridade
                score = calcular_score_motorista(motorista, distancia_km)
                
                motoristas_proximos.append({
                    'motorista_id': motorista['id'],
                    'distancia_km': distancia_km,
                    'score': score,
                    'avaliacao': motorista.get('avaliacao_media', 5.0),
                    'total_entregas': motorista.get('total_entregas', 0),
                    'veiculo_tipo': motorista.get('veiculo_tipo', 'MOTO'),
                    'latitude': motorista_lat,
                    'longitude': motorista_lng
                })
        
        # Ordenar por score (maior para menor)
        motoristas_proximos.sort(key=lambda x: x['score'], reverse=True)
        
        # Retornar apenas os melhores
        return motoristas_proximos[:max_motoristas]
        
    except Exception as e:
        print(f"Error searching for drivers: {str(e)}")
        return []

def calcular_score_motorista(motorista: Dict, distancia_km: float) -> float:
    """
    Calcular score de prioridade do motorista
    Score = 0-100 baseado em proximidade, avaliação e experiência
    """
    try:
        # Peso para proximidade (40%) - quanto menor a distância, maior o score
        proximidade_score = max(0, (10 - distancia_km) * 10) * 0.4
        
        # Peso para avaliação (30%) - escala 0-5 convertida para 0-100
        avaliacao = float(motorista.get('avaliacao_media', 5.0))
        avaliacao_score = (avaliacao * 20) * 0.3
        
        # Peso para experiência (20%) - cap em 100 entregas
        total_entregas = int(motorista.get('total_entregas', 0))
        experiencia_score = min(total_entregas, 100) * 0.2
        
        # Bonus disponibilidade (10%)
        disponibilidade_bonus = 10 * 0.1
        
        score_final = proximidade_score + avaliacao_score + experiencia_score + disponibilidade_bonus
        
        return round(score_final, 2)
        
    except Exception as e:
        print(f"Error calculating driver score: {str(e)}")
        return 0.0

def criar_ofertas_para_motoristas(pedido_id: str, motoristas_proximos: List[Dict]):
    """
    Criar ofertas de pedido para os motoristas selecionados
    """
    try:
        agora = datetime.utcnow()
        expiracao = agora + timedelta(minutes=2)  # 2 minutos para aceitar
        
        ofertas_criadas = []
        
        for motorista in motoristas_proximos:
            oferta_id = f"oferta_{pedido_id}_{motorista['motorista_id']}_{int(agora.timestamp())}"
            
            oferta = {
                'id': oferta_id,
                'pedido_id': str(pedido_id),
                'motorista_id': str(motorista['motorista_id']),
                'status': 'PENDENTE',
                'data_envio': str(agora),
                'data_expiracao': str(expiracao),
                'distancia_km': motorista['distancia_km'],
                'score_prioridade': motorista['score'],
                'tempo_estimado_min': int(motorista['distancia_km'] * 3)  # ~3 min por km
            }
            
            # Salvar oferta no DynamoDB
            ofertas_table.put_item(Item=oferta)
            ofertas_criadas.append(oferta)
            
            # Enviar notificação para o motorista
            enviar_notificacao_oferta_motorista(motorista['motorista_id'], pedido_id, oferta)
        
        print(f"Criadas {len(ofertas_criadas)} ofertas para pedido {pedido_id}")
        
        # Agendar expiração das ofertas
        agendar_expiracao_ofertas(pedido_id, ofertas_criadas)
        
    except Exception as e:
        print(f"Error creating offers: {str(e)}")

def enviar_notificacao_oferta_motorista(motorista_id: str, pedido_id: str, oferta: Dict):
    """
    Enviar notificação de nova oferta para motorista
    """
    try:
        # Buscar dados do pedido para a notificação
        pedido_response = pedidos_table.get_item(Key={'id': str(pedido_id)})
        if 'Item' not in pedido_response:
            return
        
        pedido = pedido_response['Item']
        
        # Preparar notificação
        notification = {
            'tipo': 'PEDIDO_DISPONIVEL',
            'titulo': 'Novo Pedido Disponível! 🚚',
            'conteudo': f'Pedido #{pedido_id} - {oferta["distancia_km"]:.1f}km de distância. Expires em 2 min!',
            'dadosEvento': {
                'evento': 'PEDIDO_DISPONIVEL',
                'pedidoId': pedido_id,
                'motoristaId': motorista_id,
                'ofertaId': oferta['id'],
                'dados': {
                    'distancia_km': oferta['distancia_km'],
                    'tempo_estimado_min': oferta['tempo_estimado_min'],
                    'valor_estimado': pedido.get('valor_total', 0),
                    'origem': pedido.get('origem_endereco', ''),
                    'destino': pedido.get('destino_endereco', ''),
                    'data_expiracao': oferta['data_expiracao'],
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Enviar via Lambda de notificações
        notificacoes_lambda_name = os.environ.get('NOTIFICACOES_LAMBDA_NAME', 'dev-logistics-notificacoes')
        
        payload = {
            'action': 'send_driver_offer',
            'motorista_id': motorista_id,
            'notification': notification
        }
        
        lambda_client.invoke(
            FunctionName=notificacoes_lambda_name,
            InvocationType='Event',  # Asíncrono
            Payload=json.dumps(payload)
        )
        
        print(f"Offer notification sent to driver {motorista_id}")
        
    except Exception as e:
        print(f"Error sending offer notification: {str(e)}")

def aceitar_oferta(event, user_data):
    """
    Motorista aceita uma oferta de pedido
    """
    try:
        path_parameters = event.get('pathParameters', {})
        oferta_id = path_parameters.get('ofertaId')
        
        body = json.loads(event['body'])
        motorista_id = body.get('motoristaId')
        
        if not oferta_id or not motorista_id:
            return cors_response(400, {'message': 'Missing ofertaId or motoristaId'})
        
        # Verify user has permission to accept this offer
        user_id = str(user_data.get('sub', ''))
        if user_id != str(motorista_id):
            return cors_response(403, {'message': 'Forbidden: You can only accept your own offers'})
        
        # Buscar oferta
        oferta_response = ofertas_table.get_item(Key={'id': oferta_id})
        if 'Item' not in oferta_response:
            return cors_response(404, {'message': 'Oferta não encontrada'})
        
        oferta = oferta_response['Item']
        
        # Verificar se oferta ainda está pendente
        if oferta['status'] != 'PENDENTE':
            return cors_response(409, {'message': 'Oferta não está mais disponível'})
        
        # Verificar se não expirou
        if datetime.utcnow() > datetime.fromisoformat(oferta['data_expiracao']):
            return cors_response(410, {'message': 'Oferta expirada'})
        
        # Atualizar oferta como aceita
        ofertas_table.update_item(
            Key={'id': oferta_id},
            UpdateExpression='SET #status = :status, data_aceite = :data_aceite',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'ACEITA',
                ':data_aceite': str(datetime.utcnow())
            }
        )
        
        # Atualizar pedido com motorista
        pedidos_table.update_item(
            Key={'id': oferta['pedido_id']},
            UpdateExpression='SET motoristaId = :mid, #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':mid': int(motorista_id),
                ':status': 'EM_ROTA'
            }
        )
        
        # Cancelar todas as outras ofertas do mesmo pedido
        cancelar_ofertas_concorrentes(oferta['pedido_id'], oferta_id)
        
        # Notificar cliente que pedido foi aceito
        notificar_cliente_pedido_aceito(oferta['pedido_id'], motorista_id)
        
        return cors_response(200, {'message': 'Oferta aceita com sucesso'})
        
    except Exception as e:
        print(f"Error accepting offer: {str(e)}")
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def cancelar_ofertas_concorrentes(pedido_id: str, oferta_aceita_id: str):
    """
    Cancelar todas as outras ofertas do mesmo pedido
    """
    try:
        # Buscar todas as ofertas pendentes do pedido
        response = ofertas_table.scan(
            FilterExpression='pedido_id = :pid AND #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':pid': pedido_id,
                ':status': 'PENDENTE'
            }
        )
        
        ofertas_pendentes = response.get('Items', [])
        
        for oferta in ofertas_pendentes:
            if oferta['id'] != oferta_aceita_id:
                # Cancelar oferta
                ofertas_table.update_item(
                    Key={'id': oferta['id']},
                    UpdateExpression='SET #status = :status',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={':status': 'CANCELADA'}
                )
                
                # Notificar motorista que oferta foi cancelada
                notificar_motorista_oferta_cancelada(oferta['motorista_id'], pedido_id)
        
        print(f"Cancelled {len(ofertas_pendentes)-1} competing offers for pedido {pedido_id}")
        
    except Exception as e:
        print(f"Error cancelling competing offers: {str(e)}")

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calcular distância entre dois pontos usando fórmula Haversine
    Retorna distância em quilômetros
    """
    # Raio da Terra em km
    R = 6371.0
    
    # Converter graus para radianos
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)
    
    # Diferenças
    dlat = lat2_rad - lat1_rad
    dlon = lon2_rad - lon1_rad
    
    # Fórmula Haversine
    a = math.sin(dlat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    distance = R * c
    return round(distance, 2)

def notificar_cliente_pedido_aceito(pedido_id: str, motorista_id: str):
    """
    Notificar cliente que pedido foi aceito por motorista
    """
    try:
        # Enviar evento via SQS
        sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
        if sqs_queue_url:
            sqs.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=json.dumps({
                    'event': 'pedido_aceito',
                    'pedido_id': pedido_id,
                    'motorista_id': motorista_id,
                    'timestamp': str(datetime.utcnow())
                })
            )
            
    except Exception as e:
        print(f"Error notifying client: {str(e)}")

def notificar_motorista_oferta_cancelada(motorista_id: str, pedido_id: str):
    """
    Notificar motorista que oferta foi cancelada
    """
    try:
        notification = {
            'tipo': 'OFERTA_CANCELADA',
            'titulo': 'Oferta Cancelada',
            'conteudo': f'O pedido #{pedido_id} foi aceito por outro motorista.',
            'dadosEvento': {
                'evento': 'OFERTA_CANCELADA',
                'pedidoId': pedido_id,
                'motoristaId': motorista_id,
                'dados': {
                    'timestamp': str(datetime.utcnow())
                }
            }
        }
        
        # Enviar via Lambda de notificações
        notificacoes_lambda_name = os.environ.get('NOTIFICACOES_LAMBDA_NAME', 'dev-logistics-notificacoes')
        
        payload = {
            'action': 'send_driver_notification',
            'motorista_id': motorista_id,
            'notification': notification
        }
        
        lambda_client.invoke(
            FunctionName=notificacoes_lambda_name,
            InvocationType='Event',
            Payload=json.dumps(payload)
        )
        
    except Exception as e:
        print(f"Error notifying driver about cancellation: {str(e)}")

def agendar_expiracao_ofertas(pedido_id: str, ofertas: List[Dict]):
    """
    Agendar expiração automática das ofertas
    """
    try:
        # Em produção, usar EventBridge ou Step Functions
        # Por enquanto, apenas log
        print(f"Scheduled expiration for {len(ofertas)} offers of pedido {pedido_id}")
        # TODO: Implementar com EventBridge ou SQS com delay
        
    except Exception as e:
        print(f"Error scheduling offer expiration: {str(e)}")

def notificar_sem_motoristas_disponiveis(pedido_id: str, cliente_id: str):
    """
    Notificar que não há motoristas disponíveis
    """
    try:
        # Enviar evento via SQS
        sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
        if sqs_queue_url:
            sqs.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=json.dumps({
                    'event': 'sem_motoristas_disponiveis',
                    'pedido_id': pedido_id,
                    'cliente_id': cliente_id,
                    'timestamp': str(datetime.utcnow())
                })
            )
            
    except Exception as e:
        print(f"Error notifying no drivers available: {str(e)}")

def buscar_motoristas_proximos(event, user_data):
    """
    API endpoint para buscar motoristas próximos
    """
    try:
        body = json.loads(event['body'])
        latitude = float(body['latitude'])
        longitude = float(body['longitude'])
        raio_km = float(body.get('raio_km', 5.0))
        max_results = int(body.get('max_results', 10))
        
        motoristas = buscar_motoristas_disponiveis(latitude, longitude, raio_km, max_results)
        
        return cors_response(200, {
            'motoristas': motoristas,
            'total': len(motoristas)
        })
        
    except Exception as e:
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def get_ofertas_motorista(motorista_id: str, user_data):
    """
    Buscar ofertas pendentes de um motorista
    """
    try:
        # Verify user has permission to access this motorista's offers
        user_id = str(user_data.get('sub', ''))
        if user_id != str(motorista_id):
            return cors_response(403, {'message': 'Forbidden: You can only access your own offers'})
        
        response = ofertas_table.scan(
            FilterExpression='motorista_id = :mid AND #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':mid': str(motorista_id),
                ':status': 'PENDENTE'
            }
        )
        
        ofertas = response.get('Items', [])
        
        return cors_response(200, ofertas)
        
    except Exception as e:
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def rejeitar_oferta(event, user_data):
    """
    Motorista rejeita uma oferta
    """
    try:
        path_parameters = event.get('pathParameters', {})
        oferta_id = path_parameters.get('ofertaId')
        
        if not oferta_id:
            return cors_response(400, {'message': 'Missing ofertaId'})
        
        # Get oferta to verify ownership
        try:
            oferta_response = ofertas_table.get_item(Key={'id': oferta_id})
            if 'Item' not in oferta_response:
                return cors_response(404, {'message': 'Oferta não encontrada'})
            
            oferta = oferta_response['Item']
            user_id = str(user_data.get('sub', ''))
            if user_id != str(oferta['motorista_id']):
                return cors_response(403, {'message': 'Forbidden: You can only reject your own offers'})
        except Exception as e:
            return cors_response(500, {'message': f'Error verifying oferta: {str(e)}'})
        
        # Atualizar oferta como rejeitada
        ofertas_table.update_item(
            Key={'id': oferta_id},
            UpdateExpression='SET #status = :status, data_rejeicao = :data_rejeicao',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'REJEITADA',
                ':data_rejeicao': str(datetime.utcnow())
            }
        )
        
        return cors_response(200, {'message': 'Oferta rejeitada'})
        
    except Exception as e:
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def ofertar_pedido_para_motoristas(event, user_data):
    """
    API para ofertar pedido manualmente para motoristas específicos
    """
    try:
        body = json.loads(event['body'])
        pedido_id = body['pedido_id']
        motorista_ids = body['motorista_ids']
        
        # Buscar dados dos motoristas
        motoristas_data = []
        for motorista_id in motorista_ids:
            user_response = users_table.get_item(Key={'id': str(motorista_id)})
            if 'Item' in user_response:
                motorista = user_response['Item']
                motoristas_data.append({
                    'motorista_id': motorista_id,
                    'distancia_km': 0,  # Será calculada se necessário
                    'score': 100,  # Score máximo para oferta manual
                    'avaliacao': motorista.get('avaliacao_media', 5.0),
                    'total_entregas': motorista.get('total_entregas', 0),
                    'veiculo_tipo': motorista.get('veiculo_tipo', 'MOTO')
                })
        
        if motoristas_data:
            criar_ofertas_para_motoristas(pedido_id, motoristas_data)
        
        return cors_response(200, {
            'message': f'Ofertas criadas para {len(motoristas_data)} motoristas',
            'ofertas_criadas': len(motoristas_data)
        })
        
    except Exception as e:
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def handle_oferta_expirada(message):
    """
    Processar ofertas expiradas e re-rotear se necessário
    """
    try:
        oferta_id = message.get('oferta_id')
        
        # Atualizar status da oferta
        ofertas_table.update_item(
            Key={'id': oferta_id},
            UpdateExpression='SET #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'EXPIRADA'}
        )
        
        # TODO: Implementar re-roteamento automático
        print(f"Offer {oferta_id} expired")
        
    except Exception as e:
        print(f"Error handling expired offer: {str(e)}")

def handle_motorista_indisponivel(message):
    """
    Processar motorista que ficou indisponível
    """
    try:
        motorista_id = message.get('motorista_id')
        
        # Cancelar ofertas pendentes do motorista
        response = ofertas_table.scan(
            FilterExpression='motorista_id = :mid AND #status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':mid': str(motorista_id),
                ':status': 'PENDENTE'
            }
        )
        
        ofertas_pendentes = response.get('Items', [])
        
        for oferta in ofertas_pendentes:
            ofertas_table.update_item(
                Key={'id': oferta['id']},
                UpdateExpression='SET #status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': 'CANCELADA'}
            )
        
        print(f"Cancelled {len(ofertas_pendentes)} offers for unavailable driver {motorista_id}")
        
    except Exception as e:
        print(f"Error handling unavailable driver: {str(e)}")