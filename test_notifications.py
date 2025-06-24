#!/usr/bin/env python3
import requests
import json

# API Gateway URL
API_GATEWAY_URL = "https://tntpd380l5.execute-api.us-east-1.amazonaws.com/prod"
USER_ID = "2388191532"  # The user ID we just created

print("=== Testing login first ===")
# Let's try to login first to get a token
login_response = requests.post(
    f"{API_GATEWAY_URL}/api/auth/login",
    headers={'Content-Type': 'application/json'},
    json={
        'email': 'test@example.com',
        'senha': 'password123'
    }
)
print(f"Login Status: {login_response.status_code}")
print(f"Login Response: {login_response.text}")
print(f"Login Headers: {login_response.headers}")

# Extract token if available
auth_token = None
user_info = None

if login_response.status_code == 200:
    user_info = json.loads(login_response.text)
    print(f"User info: {user_info}")
    
    # Check for Authorization header (API Gateway remaps it)
    if 'x-amzn-Remapped-Authorization' in login_response.headers:
        auth_header = login_response.headers['x-amzn-Remapped-Authorization']
        if auth_header.startswith('Bearer '):
            auth_token = auth_header[7:]
            print(f"Token extracted from x-amzn-Remapped-Authorization header: {auth_token}")
    elif 'Authorization' in login_response.headers:
        auth_header = login_response.headers['Authorization']
        if auth_header.startswith('Bearer '):
            auth_token = auth_header[7:]
            print(f"Token extracted from Authorization header: {auth_token}")

if auth_token and user_info:
    user_id = user_info['id']
    print(f"\n=== Testing notifications endpoint with auth token for user {user_id} ===")
    
    # Test with correct user ID
    response = requests.get(
        f"{API_GATEWAY_URL}/api/notificacoes/destinatario/{user_id}",
        headers={'Authorization': f'Bearer {auth_token}'}
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
    
    # Test with wrong user ID
    print(f"\n=== Testing notifications endpoint with wrong user ID ===")
    response = requests.get(
        f"{API_GATEWAY_URL}/api/notificacoes/destinatario/999999",
        headers={'Authorization': f'Bearer {auth_token}'}
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {response.text}")
else:
    print("Failed to get auth token or user info")