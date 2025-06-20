#!/usr/bin/env python3
import pika
import json
import time

def test_rabbitmq_to_lambda():
    """Test sending message from RabbitMQ to Lambda via webhook"""
    connection = pika.BlockingConnection(pika.URLParameters('amqp://guest:guest@localhost:5672/'))
    channel = connection.channel()

    test_event = {
        "type": "pedido_finalizado",
        "pedido_id": "TEST-12345", 
        "cliente_id": "456",
        "contratado_id": "789",
        "timestamp": "2025-06-19T18:50:00Z"
    }
    
    print("Sending test event to RabbitMQ...")
    print(f"Event: {json.dumps(test_event, indent=2)}")

    channel.basic_publish(
        exchange='logistica.exchange',
        routing_key='pedidos.finalizado',
        body=json.dumps(test_event),
        properties=pika.BasicProperties(
            content_type='application/json',
            type='pedido_finalizado'
        )
    )
    
    print("ok")
    
    connection.close()

if __name__ == "__main__":
    test_rabbitmq_to_lambda()