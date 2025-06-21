import json
import boto3
import uuid
import os
import sys
import jwt
from datetime import datetime
from boto3.dynamodb.conditions import Key

from auth_utils import validate_jwt_token, cors_response

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')
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
        
        if http_method == 'GET' and path_parameters:
            if 'userType' in path_parameters and 'userId' in path_parameters:
                return get_pedidos_by_user(path_parameters['userType'], path_parameters['userId'], event['user'])
            elif 'pedidoId' in path_parameters:
                return get_pedido_by_id(path_parameters['pedidoId'])
                
        elif http_method == 'POST':
            if 'aceitar' in event.get('resource', ''):
                return aceitar_pedido(event)
            elif 'cancelar' in event.get('resource', ''):
                return cancelar_pedido(path_parameters['pedidoId'])
            else:
                return create_pedido(event)
                
        elif http_method == 'PATCH' and 'cancelar' in event.get('resource', ''):
            return cancelar_pedido(path_parameters['pedidoId'])
        
        elif http_method == 'OPTIONS':
            return cors_response(200, {})
        
        return cors_response(405, {'message': 'Method not allowed'})
        
    except Exception as e:
        print(f"Error in pedidos lambda: {str(e)}")
        return cors_response(500, {'message': f'Erro: {str(e)}'})
    

def get_pedidos_by_user(user_type, user_id, user_info):
    try:
        # Validar se o usuário pode acessar os pedidos solicitados
        requested_user_id = int(user_id)
        authenticated_user_id = user_info['user_id']
        
        if requested_user_id != authenticated_user_id:
            return cors_response(403, {'message': 'Acesso negado aos pedidos deste usuário'})
        
        if user_type == 'cliente':
            response = pedidos_table.scan(
                FilterExpression='clienteId = :client_id',
                ExpressionAttributeValues={':client_id': int(user_id)}
            )
        elif user_type == 'motorista':
            response = pedidos_table.scan(
                FilterExpression='motoristaId = :motorista_id',
                ExpressionAttributeValues={':motorista_id': int(user_id)}
            )
        else:
            return cors_response(400, {'message': 'Tipo de usuário inválido'})
        
        pedidos = response.get('Items', [])
        
        # Converter para formato compatível com Flutter
        formatted_pedidos = []
        for pedido in pedidos:
            formatted_pedidos.append({
                'id': int(pedido['id']),
                'origemLatitude': pedido['origemLatitude'],
                'origemLongitude': pedido['origemLongitude'],
                'destinoLatitude': pedido['destinoLatitude'],
                'destinoLongitude': pedido['destinoLongitude'],
                'tipoMercadoria': pedido['tipoMercadoria'],
                'status': pedido['status'],
                'clienteId': pedido.get('clienteId'),
                'motoristaId': pedido.get('motoristaId'),
                'dataCriacao': pedido['dataCriacao']
            })
        
        return cors_response(200, formatted_pedidos)
        
    except Exception as e:
        print(f"Error getting pedidos: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar pedidos: {str(e)}'})

def get_pedido_by_id(pedido_id):
    response = pedidos_table.get_item(Key={'id': str(pedido_id)})
    
    if 'Item' not in response:
        return {
            'statusCode': 404,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': 'Pedido não encontrado'})
        }
    
    pedido = response['Item']
    formatted_pedido = {
        'id': int(pedido['id']),
        'origemLatitude': pedido['origemLatitude'],
        'origemLongitude': pedido['origemLongitude'],
        'destinoLatitude': pedido['destinoLatitude'],
        'destinoLongitude': pedido['destinoLongitude'],
        'tipoMercadoria': pedido['tipoMercadoria'],
        'status': pedido['status'],
        'clienteId': pedido.get('clienteId'),
        'motoristaId': pedido.get('motoristaId'),
        'dataCriacao': pedido['dataCriacao']
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(formatted_pedido)
    }

def create_pedido(event):
    body = json.loads(event['body'])
    
    # Criar pedido
    pedido_id = int(str(uuid.uuid4().int)[:10])
    
    pedido = {
        'id': str(pedido_id),
        'origemLatitude': body['origemLatitude'],
        'origemLongitude': body['origemLongitude'],
        'destinoLatitude': body['destinoLatitude'],
        'destinoLongitude': body['destinoLongitude'],
        'tipoMercadoria': body['tipoMercadoria'],
        'clienteId': body['clienteId'],
        'status': 'AGUARDANDO_MOTORISTA',
        'dataCriacao': str(datetime.utcnow())
    }
    
    # Salvar no DynamoDB
    pedidos_table.put_item(Item=pedido)
    
    # Enviar evento para SQS (notificações)
    try:
        sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
        if sqs_queue_url:
            sqs.send_message(
                QueueUrl=sqs_queue_url,
                MessageBody=json.dumps({
                    'event': 'pedido_created',
                    'pedido_id': pedido_id,
                    'cliente_id': body['clienteId']
                })
            )
    except Exception as e:
        print(f"Error sending SQS message: {str(e)}")
    
    # Retornar pedido no formato compatível
    formatted_pedido = {
        'id': pedido_id,
        'origemLatitude': pedido['origemLatitude'],
        'origemLongitude': pedido['origemLongitude'],
        'destinoLatitude': pedido['destinoLatitude'],
        'destinoLongitude': pedido['destinoLongitude'],
        'tipoMercadoria': pedido['tipoMercadoria'],
        'status': pedido['status'],
        'clienteId': pedido['clienteId'],
        'dataCriacao': pedido['dataCriacao']
    }
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(formatted_pedido)
    }

def aceitar_pedido(event):
    path_parameters = event.get('pathParameters', {})
    query_parameters = event.get('queryStringParameters', {})
    
    pedido_id = path_parameters.get('pedidoId')
    motorista_id = query_parameters.get('motoristaId')
    latitude = query_parameters.get('latitude')
    longitude = query_parameters.get('longitude')
    
    # Atualizar pedido
    pedidos_table.update_item(
        Key={'id': str(pedido_id)},
        UpdateExpression='SET motoristaId = :mid, #status = :status, dataAceite = :data',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':mid': int(motorista_id),
            ':status': 'EM_ROTA',
            ':data': str(datetime.utcnow())
        }
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Pedido aceito com sucesso'})
    }

def cancelar_pedido(pedido_id):
    pedidos_table.update_item(
        Key={'id': str(pedido_id)},
        UpdateExpression='SET #status = :status, dataCancelamento = :data',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'CANCELADO',
            ':data': str(datetime.utcnow())
        }
    )
    
    return {
        'statusCode': 204,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': ''
    }