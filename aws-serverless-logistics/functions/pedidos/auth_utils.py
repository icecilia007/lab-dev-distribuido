import jwt
import json
import os
from functools import wraps

def validate_jwt_token(event):
    try:
        # Verificação defensiva para event None ou sem headers
        if not event:
            print("[DEBUG] Event é None")
            return None
            
        headers = event.get('headers') if event else None
        if not headers:
            print("[DEBUG] Headers não encontrados no event")
            return None
            
        print(f"[DEBUG] Headers: {headers}")
        
        auth_header = (headers.get('Authorization') or
                       headers.get('authorization') or
                       headers.get('x-amzn-remapped-authorization'))

        print(f"[DEBUG] Authorization header: {auth_header}")

        if not auth_header or not auth_header.startswith('Bearer '):
            print("[DEBUG] Header ausente ou malformado")
            return None

        token = auth_header.split(' ')[1]
        secret_key = os.environ.get('JWT_SECRET')

        print(f"[DEBUG] Usando JWT_SECRET: {secret_key[:5]}***")  # nunca imprima tudo

        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return payload

    except jwt.ExpiredSignatureError:
        print("[DEBUG] Token expirado")
        return None
    except jwt.InvalidTokenError as e:
        print(f"[DEBUG] Token inválido: {str(e)}")
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