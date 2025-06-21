#!/usr/bin/env python3
import jwt

# Token do log
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyMTc4NzYxMTA2LCJlbWFpbCI6ImFzZGFzZC5zaWx2YUBleGVtcGxvLmNvbSIsInRpcG8iOiJDTElFTlRFIiwiZXhwIjoxNzUwNjMwNTQ4fQ.kskqqozoYUf-5NNcuCEXBiF6UGtAeCG06sviDviJRIs"

# Segredo usado nas lambdas
secret = "your-jwt-secret-key"  # Padrão usado no código

try:
    # Decodificar sem verificar expiração primeiro
    payload = jwt.decode(token, secret, algorithms=['HS256'], options={"verify_exp": False})
    print("Payload (sem verificar exp):", payload)
    
    # Verificar se está expirado
    import time
    exp = payload.get('exp')
    now = time.time()
    print(f"Token expira em: {exp}")
    print(f"Timestamp atual: {now}")
    print(f"Token expirado: {exp < now}")
    
    # Agora tentar decodificar com verificação de expiração
    payload_verified = jwt.decode(token, secret, algorithms=['HS256'])
    print("Token válido:", payload_verified)
    
except jwt.ExpiredSignatureError:
    print("ERRO: Token expirado!")
except jwt.InvalidTokenError as e:
    print(f"ERRO: Token inválido: {e}")
except Exception as e:
    print(f"ERRO: {e}")