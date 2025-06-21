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