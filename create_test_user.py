#!/usr/bin/env python3
import boto3
import bcrypt
import uuid
from datetime import datetime

# DynamoDB setup
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
users_table = dynamodb.Table('dev-logistics-users')

# Create test user
password = 'password123'
hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

user_id = int(str(uuid.uuid4().int)[:10])

user_item = {
    'email': 'test@example.com',  # This is the primary key
    'id': str(user_id),
    'nome': 'Test User',
    'senha': hashed_password,
    'tipo': 'cliente',
    'telefone': '+5511999999999',
    'created_at': str(datetime.utcnow()),
    'endereco': 'Test Address 123',
    'cidade': 'São Paulo'
}

try:
    users_table.put_item(Item=user_item)
    print(f"Test user created successfully!")
    print(f"Email: test@example.com")
    print(f"Password: password123")
    print(f"User ID: {user_id}")
except Exception as e:
    print(f"Error creating test user: {e}")