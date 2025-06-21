import json
import boto3
import uuid
import os
import jwt
from datetime import datetime
from geopy.distance import geodesic
from haversine import haversine, Unit

from auth_utils import validate_jwt_token, cors_response

# AWS Services
dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

# Tables
locations_table = dynamodb.Table(os.environ.get('LOCATIONS_TABLE', 'dev-logistics-locations'))
pedidos_table = dynamodb.Table(os.environ.get('PEDIDOS_TABLE', 'dev-logistics-pedidos'))

def handler(event, context):
    try:
        # Validar JWT token para todas as rotas exceto OPTIONS
        if event.get('httpMethod') != 'OPTIONS':
            user_payload = validate_jwt_token(event)
            if not user_payload:
                return cors_response(401, {'message': 'Token inválido ou expirado'})
            
            # Adicionar informações do usuário ao evento
            event['user'] = user_payload
        
        http_method = event['httpMethod']
        path_parameters = event.get('pathParameters', {})
        resource = event.get('resource', '')
        
        if http_method == 'GET':
            if 'pedido' in resource and 'historico' not in resource:
                return get_current_location(path_parameters['pedidoId'])
            elif 'historico' in resource:
                return get_location_history(path_parameters['pedidoId'])
            elif 'estatisticas' in resource:
                return get_driver_statistics(path_parameters)
        
        elif http_method == 'POST':
            if 'localizacao' in resource:
                return update_location(event)
            elif 'coleta' in resource:
                return confirm_pickup(event, path_parameters)
            elif 'entrega' in resource:
                return confirm_delivery(event, path_parameters)
        
        elif http_method == 'OPTIONS':
            return cors_response(200, {})
        
        return cors_response(405, {'message': 'Method not allowed'})
        
    except Exception as e:
        print(f"Error in rastreamento lambda: {str(e)}")
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def update_location(event):
    """Atualizar localização do motorista/pedido"""
    try:
        body = json.loads(event['body'])
        
        motorista_id = body['motoristaId']
        pedido_id = body.get('pedidoId')
        latitude = float(body['latitude'])
        longitude = float(body['longitude'])
        status_veiculo = body['statusVeiculo']
        
        # Criar registro de localização
        location_id = str(uuid.uuid4())
        location = {
            'id': location_id,
            'motoristaId': motorista_id,
            'pedidoId': pedido_id,
            'latitude': latitude,
            'longitude': longitude,
            'statusVeiculo': status_veiculo,
            'timestamp': str(datetime.utcnow())
        }
        
        # Salvar localização
        locations_table.put_item(Item=location)
        
        # Se há pedido associado, verificar proximidade
        if pedido_id:
            check_proximity_and_notify(pedido_id, latitude, longitude)
        
        return cors_response(200, {'success': True})
        
    except Exception as e:
        print(f"Error updating location: {str(e)}")
        return cors_response(500, {'message': f'Erro ao atualizar localização: {str(e)}'})

def check_proximity_and_notify(pedido_id, current_lat, current_lng):
    """Verificar proximidade e enviar notificações"""
    try:
        # Buscar dados do pedido
        pedido_response = pedidos_table.get_item(Key={'id': str(pedido_id)})
        if 'Item' not in pedido_response:
            return
        
        pedido = pedido_response['Item']
        
        # Verificar proximidade do destino
        destino_lat = float(pedido['destinoLatitude'])
        destino_lng = float(pedido['destinoLongitude'])
        
        distance_to_destination = haversine(
            (current_lat, current_lng),
            (destino_lat, destino_lng),
            unit=Unit.KILOMETERS
        )
        
        # Se motorista está próximo do destino (500m)
        if distance_to_destination <= 0.5 and pedido['status'] == 'EM_ROTA':
            send_proximity_notification(pedido_id, pedido['clienteId'], distance_to_destination)
        
        # Se motorista está na origem e pedido aguardando coleta
        if pedido['status'] == 'AGUARDANDO_COLETA':
            origem_lat = float(pedido['origemLatitude'])
            origem_lng = float(pedido['origemLongitude'])
            
            distance_to_origin = haversine(
                (current_lat, current_lng),
                (origem_lat, origem_lng),
                unit=Unit.KILOMETERS
            )
            
            if distance_to_origin <= 0.2:  # 200m da origem
                send_pickup_ready_notification(pedido_id, pedido['clienteId'])
                
    except Exception as e:
        print(f"Error checking proximity: {str(e)}")

def send_proximity_notification(pedido_id, cliente_id, distance):
    """Enviar notificação de proximidade"""
    try:
        sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
        if sqs_queue_url:
            message = {
                'event': 'motorista_proximo',
                'pedido_id': pedido_id,
                'cliente_id': cliente_id,
                'distancia_km': round(distance, 2),
                'timestamp': str(datetime.utcnow())
            }
            
            sqs.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=json.dumps(message)
            )
            
            print(f"Proximity notification sent for pedido {pedido_id}")
            
    except Exception as e:
        print(f"Error sending proximity notification: {str(e)}")

def send_pickup_ready_notification(pedido_id, cliente_id):
    """Notificar que motorista chegou para coleta"""
    try:
        sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
        if sqs_queue_url:
            message = {
                'event': 'motorista_chegou_coleta',
                'pedido_id': pedido_id,
                'cliente_id': cliente_id,
                'timestamp': str(datetime.utcnow())
            }
            
            sqs.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=json.dumps(message)
            )
            
    except Exception as e:
        print(f"Error sending pickup notification: {str(e)}")

def get_current_location(pedido_id):
    """Buscar localização atual do pedido"""
    try:
        # Buscar a localização mais recente do pedido
        response = locations_table.scan(
            FilterExpression='pedidoId = :pedido_id',
            ExpressionAttributeValues={':pedido_id': int(pedido_id)}
        )
        
        locations = response.get('Items', [])
        
        if not locations:
            return cors_response(404, {'message': 'Localização não encontrada'})
        
        # Ordenar por timestamp e pegar a mais recente
        locations.sort(key=lambda x: x['timestamp'], reverse=True)
        current_location = locations[0]
        
        formatted_location = {
            'id': current_location['id'],
            'motoristaId': current_location['motoristaId'],
            'pedidoId': current_location['pedidoId'],
            'latitude': float(current_location['latitude']),
            'longitude': float(current_location['longitude']),
            'statusVeiculo': current_location['statusVeiculo'],
            'timestamp': current_location['timestamp']
        }
        
        return cors_response(200, formatted_location)
        
    except Exception as e:
        print(f"Error getting current location: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar localização: {str(e)}'})

def get_location_history(pedido_id):
    """Buscar histórico de localizações do pedido"""
    try:
        response = locations_table.scan(
            FilterExpression='pedidoId = :pedido_id',
            ExpressionAttributeValues={':pedido_id': int(pedido_id)}
        )
        
        locations = response.get('Items', [])
        
        # Ordenar por timestamp
        locations.sort(key=lambda x: x['timestamp'])
        
        formatted_locations = []
        for location in locations:
            formatted_locations.append({
                'id': location['id'],
                'motoristaId': location['motoristaId'],
                'pedidoId': location['pedidoId'],
                'latitude': float(location['latitude']),
                'longitude': float(location['longitude']),
                'statusVeiculo': location['statusVeiculo'],
                'timestamp': location['timestamp']
            })
        
        return cors_response(200, formatted_locations)
        
    except Exception as e:
        print(f"Error getting location history: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar histórico: {str(e)}'})

def confirm_pickup(event, path_parameters):
    """Confirmar coleta do pedido"""
    try:
        pedido_id = path_parameters.get('pedidoId')
        query_params = event.get('queryStringParameters', {})
        motorista_id = query_params.get('motoristaId')
        
        # Atualizar status do pedido
        pedidos_table.update_item(
            Key={'id': str(pedido_id)},
            UpdateExpression='SET #status = :status, dataColeta = :data',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'EM_ROTA',
                ':data': str(datetime.utcnow())
            }
        )
        
        # Enviar evento de coleta confirmada
        try:
            sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
            if sqs_queue_url:
                message = {
                    'event': 'coleta_confirmada',
                    'pedido_id': pedido_id,
                    'motorista_id': motorista_id,
                    'timestamp': str(datetime.utcnow())
                }
                
                sqs.send_message(
                    QueueUrl=sqs_queue_url,
                    MessageBody=json.dumps(message)
                )
        except Exception as e:
            print(f"Error sending pickup confirmation event: {str(e)}")
        
        return cors_response(200, {'success': True})
        
    except Exception as e:
        print(f"Error confirming pickup: {str(e)}")
        return cors_response(500, {'message': f'Erro ao confirmar coleta: {str(e)}'})

def confirm_delivery(event, path_parameters):
    """Confirmar entrega do pedido"""
    try:
        pedido_id = path_parameters.get('pedidoId')
        query_params = event.get('queryStringParameters', {})
        motorista_id = query_params.get('motoristaId')
        
        # Buscar dados do pedido para notificações
        pedido_response = pedidos_table.get_item(Key={'id': str(pedido_id)})
        if 'Item' not in pedido_response:
            return cors_response(404, {'message': 'Pedido não encontrado'})
        
        pedido = pedido_response['Item']
        
        # Atualizar status do pedido
        pedidos_table.update_item(
            Key={'id': str(pedido_id)},
            UpdateExpression='SET #status = :status, dataEntrega = :data',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'ENTREGUE',
                ':data': str(datetime.utcnow())
            }
        )
        
        # Enviar evento de pedido finalizado
        try:
            sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
            if sqs_queue_url:
                message = {
                    'event': 'pedido_finalizado',
                    'pedido_id': pedido_id,
                    'cliente_id': pedido.get('clienteId'),
                    'motorista_id': motorista_id,
                    'timestamp': str(datetime.utcnow())
                }
                
                sqs.send_message(
                    QueueUrl=sqs_queue_url,
                    MessageBody=json.dumps(message)
                )
                
                print(f"Delivery confirmation event sent for pedido {pedido_id}")
        except Exception as e:
            print(f"Error sending delivery confirmation event: {str(e)}")
        
        return cors_response(200, {'success': True})
        
    except Exception as e:
        print(f"Error confirming delivery: {str(e)}")
        return cors_response(500, {'message': f'Erro ao confirmar entrega: {str(e)}'})

def get_driver_statistics(path_parameters):
    """Obter estatísticas do motorista"""
    try:
        driver_id = path_parameters.get('driverId')
        
        # Query parameters para filtro de data
        # Em produção, você faria queries mais complexas
        
        # Estatísticas simuladas baseadas nos dados
        statistics = {
            'totalEntregas': 25,
            'distanciaTotal': 480.5,
            'tempoMedioEntrega': 35,  # minutos
            'avaliacaoMedia': 4.7,
            'entregasHoje': 3,
            'entregasSemana': 18,
            'entregasMes': 25,
            'eficiencia': 92.5  # percentual
        }
        
        return cors_response(200, statistics)
        
    except Exception as e:
        print(f"Error getting driver statistics: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar estatísticas: {str(e)}'})