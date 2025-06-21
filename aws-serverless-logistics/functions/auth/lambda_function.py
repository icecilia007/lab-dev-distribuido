import json
import boto3
import jwt
import bcrypt
from datetime import datetime, timedelta
import os

dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table(os.environ.get('USERS_TABLE', 'dev-logistics-users'))

def handler(event, context):
    try:
        # Parse request body
        body = json.loads(event['body'])
        email = body['email']
        password = body['senha']
        
        print(f"Login attempt for email: {email}")
        
        # Buscar usuário no DynamoDB  
        response = users_table.get_item(Key={'email': email})
        
        if 'Item' not in response:
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Email ou senha inválidos'})
            }
        
        user = response['Item']
        
        # Verificar senha
        if not bcrypt.checkpw(password.encode('utf-8'), user['senha'].encode('utf-8')):
            return {
                'statusCode': 401,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Email ou senha inválidos'})
            }
        
        # Gerar JWT
        payload = {
            'user_id': int(user['id']),
            'email': user['email'],
            'tipo': user['tipo'],
            'exp': datetime.utcnow() + timedelta(hours=24)
        }
        
        secret_key = os.environ.get('JWT_SECRET', 'your-secret-key')
        token = jwt.encode(payload, secret_key, algorithm='HS256')
        
        # Retorna mesmo formato que Java
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {token}',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'id': int(user['id']),
                'nome': user['nome'],
                'email': user['email'],
                'tipo': user['tipo'],
                'telefone': user.get('telefone')
            })
        }
        
    except Exception as e:
        print(f"Error in auth lambda: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'message': f'Erro interno: {str(e)}'})
        }