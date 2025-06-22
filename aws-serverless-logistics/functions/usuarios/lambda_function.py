import json
import boto3
import bcrypt
import uuid
import os
from datetime import datetime
from auth_utils import validate_jwt_token, cors_response

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