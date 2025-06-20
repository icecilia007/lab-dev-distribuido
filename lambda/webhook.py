#!/usr/bin/env python3
import json
import pika
import requests
import os
import time


class RabbitMQWebhook:
    """
    Webhook that connects RabbitMQ to Lambda.
    Consumes messages from queue and sends to Lambda via HTTP.
    """

    def __init__(self):
        self.rabbitmq_url = os.getenv('RABBITMQ_URL', 'amqp://guest:guest@rabbitmq:5672/')
        self.lambda_url = os.getenv('LAMBDA_URL', 'http://lambda-simulator:9000/2015-03-31/functions/function/invocations')
        
    def connect_to_rabbitmq(self):
        """Connects to RabbitMQ with automatic retry"""
        max_retries = 30
        retry_count = 0
        
        while retry_count < max_retries:
            try:
                connection = pika.BlockingConnection(pika.URLParameters(self.rabbitmq_url))
                channel = connection.channel()
                print(f"Connected to RabbitMQ at {self.rabbitmq_url}")
                return connection, channel
            except Exception as e:
                retry_count += 1
                print(f"Attempt {retry_count}/{max_retries} failed: {e}")
                time.sleep(2)
        
        raise Exception("Could not connect to RabbitMQ after multiple attempts")

    def send_to_lambda(self, event_data, routing_key):
        """Sends event to Lambda in AWS Lambda RabbitMQ format"""
        try:
            lambda_event = {
                "Records": [{
                    "eventSource": "aws:rmq",
                    "eventSourceArn": "arn:aws:mq:us-east-1:123456789012:broker:MyBroker:b-c7352341-ec00-4b53-8560-b46d6c8265c5",
                    "rmqMessagesByQueue": {
                        "lambda.webhook::/": [{
                            "basicProperties": {
                                "contentType": "application/json",
                                "deliveryMode": 2,
                                "headers": {},
                                "messageId": f"msg-{int(time.time())}",
                                "timestamp": int(time.time()),
                                "type": event_data.get('type', 'unknown')
                            },
                            "data": json.dumps(event_data),
                            "redelivered": False
                        }]
                    }
                }]
            }
            
            lambda_event.update(event_data)
            lambda_event["routing_key"] = routing_key
            
            print(f"Sending to Lambda: {self.lambda_url}")
            print(f"Routing Key: {routing_key}")
            print(f"Event Data: {json.dumps(event_data, indent=2)}")
            
            response = requests.post(
                self.lambda_url,
                json=lambda_event,
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            if response.status_code == 200:
                print(f"Lambda responded: {response.status_code}")
                try:
                    response_data = response.json()
                    print(f"Response: {json.dumps(response_data, indent=2)}")
                except:
                    print(f"Response: {response.text}")
                return True
            else:
                print(f"Lambda error: {response.status_code} - {response.text}")
                return False
                
        except Exception as e:
            print(f"Error sending to Lambda: {e}")
            return False

    def process_message(self, ch, method, properties, body):
        """Processes RabbitMQ message and sends to Lambda"""
        try:
            message_data = json.loads(body.decode('utf-8'))
            routing_key = method.routing_key
            
            print(f"\nMessage received:")
            print(f"Routing Key: {routing_key}")
            print(f"Data: {json.dumps(message_data, indent=2)}")
            
            success = self.send_to_lambda(message_data, routing_key)
            
            if success:
                ch.basic_ack(delivery_tag=method.delivery_tag)
                print(f"Message processed successfully")
            else:
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
                print(f"Message rejected for reprocessing")
                
        except Exception as e:
            print(f"Error processing message: {e}")
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)

    def start_webhook(self):
        """Starts the RabbitMQ -> Lambda webhook"""
        connection, channel = self.connect_to_rabbitmq()
        
        try:
            queue_name = os.getenv('QUEUE_NAME', 'lambda.webhook')
            
            try:
                channel.queue_declare(queue=queue_name, durable=True)
                channel.basic_consume(
                    queue=queue_name,
                    on_message_callback=self.process_message,
                    auto_ack=False
                )
                print(f"Listening to queue: {queue_name}")
                print(f"This queue receives ALL events via routing_key '#'")
            except Exception as e:
                print(f"Error configuring queue {queue_name}: {e}")
            
            print(f"\nRabbitMQ Webhook started!")
            print(f"Lambda URL: {self.lambda_url}")
            print(f"Any event published to exchange will be sent to Lambda")
            print(f"To stop, press CTRL+C")
            
            channel.start_consuming()
            
        except KeyboardInterrupt:
            print("\nStopping webhook...")
            channel.stop_consuming()
            connection.close()
            print("Webhook finished")


if __name__ == "__main__":
    webhook = RabbitMQWebhook()
    webhook.start_webhook()