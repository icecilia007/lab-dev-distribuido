import jwt
import json
import os
from functools import wraps

def validate_jwt_token(event):
    """
    Valida o token JWT presente nos headers da requisição
    Retorna o payload do token ou None se inválido
    """
    try:
        headers = event.get('headers', {})

        # Tentar diferentes variações do header Authorization
        auth_header = (headers.get('Authorization') or
                       headers.get('authorization') or
                       headers.get('x-amzn-remapped-authorization'))

        if not auth_header:
            return None

        if not auth_header.startswith('Bearer '):
            return None

        token = auth_header.split(' ')[1]
        secret_key = os.environ.get('JWT_SECRET', 'your-secret-key')

        # Decodificar e validar o token
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return payload

    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None
    except Exception as e:
        print(f"Error validating JWT: {str(e)}")
        return None

def require_auth(func):
    """
    Decorator que requer autenticação JWT para a função
    """
    @wraps(func)
    def wrapper(event, context):
        payload = validate_jwt_token(event)
        if not payload:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Token inválido ou expirado'})
            }

        # Adicionar informações do usuário ao evento
        event['user'] = payload
        return func(event, context)

    return wrapper

def cors_response(status_code, body):
    """
    Retorna uma resposta padronizada com CORS
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, PATCH, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        'body': json.dumps(body)
    }

import json
import boto3
import bcrypt
import uuid
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'dev-logistics-users'))

def handler(event, context):
    try:
        http_method = event['httpMethod']
        path_parameters = event.get('pathParameters', {})
        resource_path = event.get('resource', '')
        
        # Verificar se é uma rota de registro (POST com 'registro' no path)
        is_register_route = (http_method == 'POST' and 'registro' in resource_path)
        
        # Validar JWT para todas as rotas EXCETO rotas de registro
        if not is_register_route:
            payload = validate_jwt_token(event)
            if not payload:
                return cors_response(401, {'message': 'Token inválido ou expirado'})
            # Adicionar informações do usuário ao evento
            event['user'] = payload
        
        if http_method == 'POST':
            # Registro de usuário
            return register_user(event)
        elif http_method == 'GET' and path_parameters:
            # Buscar usuário por ID
            return get_user(path_parameters['userId'])
        
        return cors_response(405, {'message': 'Method not allowed'})
        
    except Exception as e:
        print(f"Error in usuarios lambda: {str(e)}")
        return cors_response(500, {'message': f'Erro: {str(e)}'})

def register_user(event):
    body = json.loads(event['body'])
    
    # Determinar tipo de usuário baseado no path
    resource_path = event.get('resource', '')
    user_tipo = 'CLIENTE'  # default
    
    if 'motorista' in resource_path:
        user_tipo = 'MOTORISTA'
    elif 'operador' in resource_path:
        user_tipo = 'OPERADOR'
    
    # Hash da senha
    hashed_password = bcrypt.hashpw(
        body['senha'].encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')
    
    # Criar usuário
    user_id = int(str(uuid.uuid4().int)[:10])
    
    user_item = {
        'id': str(user_id),
        'email': body['email'],
        'nome': body['nome'],
        'senha': hashed_password,
        'tipo': user_tipo,
        'telefone': body.get('telefone'),
        'created_at': str(datetime.utcnow())
    }
    
    # Adicionar campos específicos por tipo
    if user_tipo == 'MOTORISTA':
        user_item.update({
            'cnh': body.get('cnh'),
            'veiculo_tipo': body.get('veiculo_tipo'),
            'veiculo_placa': body.get('veiculo_placa')
        })
    elif user_tipo == 'CLIENTE':
        user_item.update({
            'endereco': body.get('endereco'),
            'cidade': body.get('cidade')
        })
    
    users_table.put_item(Item=user_item)
    
    return cors_response(201, {'message': f'{user_tipo.title()} registrado com sucesso'})

def get_user(user_id):
    response = users_table.get_item(Key={'id': str(user_id)})
    
    if 'Item' not in response:
        return cors_response(404, {'message': 'Usuário não encontrado'})
    
    user = response['Item']
    # Remove password from response
    user.pop('senha', None)
    
    return cors_response(200, user)