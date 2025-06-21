import json
import boto3
import jwt
import os
from datetime import datetime

# AWS Services
dynamodb = boto3.resource('dynamodb')
apigateway = boto3.client('apigatewaymanagementapi')

# Tables
connections_table = dynamodb.Table(os.environ.get('CONNECTIONS_TABLE', 'dev-logistics-websocket-connections'))

def handler(event, context):
    """
    Handle WebSocket events: connect, disconnect, message
    Também pode ser invocado diretamente pelas outras lambdas para enviar notificações
    """
    try:
        # Verificar se é uma invocação direta (send_notification)
        if 'action' in event and event['action'] == 'send_notification':
            return handle_direct_notification(event)
        
        # Caso contrário, é uma invocação via WebSocket API Gateway
        route_key = event.get('requestContext', {}).get('routeKey')
        connection_id = event.get('requestContext', {}).get('connectionId')
        domain_name = event.get('requestContext', {}).get('domainName')
        stage = event.get('requestContext', {}).get('stage')
        
        # Setup API Gateway Management API endpoint
        endpoint_url = f"https://{domain_name}/{stage}"
        global apigateway
        apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=endpoint_url)
        
        print(f"WebSocket event: {route_key}, connection: {connection_id}")
        
        if route_key == '$connect':
            return handle_connect(event, connection_id)
        elif route_key == '$disconnect':
            return handle_disconnect(connection_id)
        elif route_key == 'sendMessage':
            return handle_message(event, connection_id)
        else:
            return {'statusCode': 400, 'body': 'Unknown route'}
            
    except Exception as e:
        print(f"Error in WebSocket handler: {str(e)}")
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}

def handle_connect(event, connection_id):
    """
    Handle WebSocket connection - compatível com Java (?userId=123)
    """
    try:
        # Extrair userId da query string (igual ao Java)
        query_params = event.get('queryStringParameters') or {}
        user_id = query_params.get('userId')
        
        if not user_id:
            print("Missing userId in query parameters")
            return {'statusCode': 400, 'body': 'Missing userId parameter'}
        
        # Extrair token JWT dos headers ou query parameters
        headers = event.get('headers') or {}
        auth_header = headers.get('Authorization') or headers.get('authorization')
        
        token = None
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header[7:]
        elif query_params.get('token'):
            token = query_params.get('token')
        
        if token:
            try:
                # Validar JWT
                jwt_secret = os.environ.get('JWT_SECRET', 'your-jwt-secret-key')
                payload = jwt.decode(token, jwt_secret, algorithms=['HS256'])
                
                # Verificar se o userId do token bate com o da query
                token_user_id = str(payload.get('user_id'))
                if token_user_id != str(user_id):
                    print(f"Token user_id {token_user_id} doesn't match query userId {user_id}")
                    return {'statusCode': 403, 'body': 'Invalid token for user'}
                
                print(f"JWT validation successful for user {user_id}")
                    
            except jwt.ExpiredSignatureError:
                print(f"JWT token expired for user {user_id}")
                return {'statusCode': 401, 'body': 'Token expired'}
            except jwt.InvalidTokenError as e:
                print(f"Invalid JWT token: {str(e)}")
                return {'statusCode': 401, 'body': 'Invalid token'}
        else:
            print("No JWT token provided")
            return {'statusCode': 401, 'body': 'No token provided'}
        
        # Salvar conexão no DynamoDB (igual ao Map do Java)
        connection = {
            'connectionId': connection_id,
            'userId': int(user_id),
            'connectedAt': str(datetime.utcnow()),
            'ttl': int(datetime.utcnow().timestamp()) + 86400  # 24h TTL
        }
        
        connections_table.put_item(Item=connection)
        
        print(f"User {user_id} connected with connection {connection_id}")
        
        return {'statusCode': 200, 'body': 'Connected'}
        
    except Exception as e:
        print(f"Error in handle_connect: {str(e)}")
        return {'statusCode': 500, 'body': f'Connection error: {str(e)}'}

def handle_disconnect(connection_id):
    """
    Handle WebSocket disconnection
    """
    try:
        # Remover conexão do DynamoDB
        connections_table.delete_item(Key={'connectionId': connection_id})
        
        print(f"Connection {connection_id} disconnected")
        
        return {'statusCode': 200, 'body': 'Disconnected'}
        
    except Exception as e:
        print(f"Error in handle_disconnect: {str(e)}")
        return {'statusCode': 500, 'body': f'Disconnect error: {str(e)}'}

def handle_message(event, connection_id):
    """
    Handle incoming WebSocket messages (se necessário)
    """
    try:
        body = event.get('body', '{}')
        message = json.loads(body)
        
        # Processar mensagem se necessário
        # Por enquanto, apenas log
        print(f"Received message from {connection_id}: {message}")
        
        return {'statusCode': 200, 'body': 'Message received'}
        
    except Exception as e:
        print(f"Error in handle_message: {str(e)}")
        return {'statusCode': 500, 'body': f'Message error: {str(e)}'}

def send_notification_to_user(user_id, notification):
    """
    Enviar notificação para usuário específico via WebSocket
    Função chamada pelas outras lambdas
    """
    try:
        # Buscar conexões ativas do usuário
        response = connections_table.scan(
            FilterExpression='userId = :user_id',
            ExpressionAttributeValues={':user_id': int(user_id)}
        )
        
        connections = response.get('Items', [])
        
        if not connections:
            print(f"No active connections for user {user_id}")
            return False
        
        # Preparar mensagem no formato esperado pelo Flutter
        message = {
            'tipoEvento': notification.get('tipo', 'NOTIFICACAO'),
            'mensagem': notification.get('conteudo', ''),
            'dadosEvento': {
                'evento': notification.get('tipo', 'NOTIFICACAO'),
                'dados': notification.get('dadosEvento', {})
            }
        }
        
        message_json = json.dumps(message)
        successful_sends = 0
        
        # Enviar para todas as conexões ativas do usuário
        for connection in connections:
            connection_id = connection['connectionId']
            try:
                apigateway.post_to_connection(
                    ConnectionId=connection_id,
                    Data=message_json
                )
                successful_sends += 1
                print(f"Notification sent to connection {connection_id}")
                
            except apigateway.exceptions.GoneException:
                # Conexão não existe mais, remover do banco
                print(f"Connection {connection_id} is gone, removing from database")
                connections_table.delete_item(Key={'connectionId': connection_id})
                
            except Exception as e:
                print(f"Error sending to connection {connection_id}: {str(e)}")
        
        print(f"Notification sent to {successful_sends}/{len(connections)} connections for user {user_id}")
        return successful_sends > 0
        
    except Exception as e:
        print(f"Error sending notification to user {user_id}: {str(e)}")
        return False

def send_notification_to_multiple_users(user_ids, notification):
    """
    Enviar notificação para múltiplos usuários
    Usado para PEDIDO_DISPONIVEL com motoristasProximos
    """
    successful_users = 0
    
    for user_id in user_ids:
        if send_notification_to_user(user_id, notification):
            successful_users += 1
    
    print(f"Notification sent to {successful_users}/{len(user_ids)} users")
    return successful_users

def handle_direct_notification(event):
    """
    Handle direct notification from other Lambda functions
    """
    try:
        user_id = event.get('userId')
        notification = event.get('notification')
        
        if not user_id or not notification:
            print("Missing userId or notification in direct invocation")
            return {'statusCode': 400, 'body': 'Missing required parameters'}
        
        # Setup API Gateway Management API endpoint from environment
        websocket_api_endpoint = os.environ.get('WEBSOCKET_API_ENDPOINT')
        if not websocket_api_endpoint:
            print("WEBSOCKET_API_ENDPOINT not configured")
            return {'statusCode': 500, 'body': 'WebSocket endpoint not configured'}
        
        global apigateway
        apigateway = boto3.client('apigatewaymanagementapi', endpoint_url=websocket_api_endpoint)
        
        # Send notification to user
        success = send_notification_to_user(user_id, notification)
        
        return {
            'statusCode': 200 if success else 404,
            'body': f'Notification {"sent" if success else "failed - no connections"}'
        }
        
    except Exception as e:
        print(f"Error in handle_direct_notification: {str(e)}")
        return {'statusCode': 500, 'body': f'Error: {str(e)}'}