import json
import boto3
import uuid
import os
from datetime import datetime
from decimal import Decimal

from auth_utils import validate_jwt_token, cors_response

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')
sns = boto3.client('sns')  # Adicionar SNS para eventos
pedidos_table = dynamodb.Table(os.environ.get('PEDIDOS_TABLE', 'dev-logistics-pedidos'))


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def convert_to_decimal(value, default=0.0):
    """Converte um valor para Decimal, tratando casos especiais"""
    if value is None:
        return Decimal(str(default))
    try:
        return Decimal(str(value))
    except (ValueError, TypeError):
        return Decimal(str(default))


def handler(event, context):
    try:
        # Validar JWT token para todas as rotas exceto OPTIONS
        # if event.get('httpMethod') != 'OPTIONS':
        #     user_payload = validate_jwt_token(event)
        #     if not user_payload:
        #         return cors_response(401, {'message': 'Token inválido ou expirado'})
        #
        #     # Adicionar informações do usuário ao evento
        #     event['user'] = user_payload

        http_method = event['httpMethod']
        query_params = event.get('queryStringParameters') or {}
        path_parameters = event.get('pathParameters') or {}
        print(f"Received event: {json.dumps(event)}")
        # Primeiro verificar rotas específicas com path parameters
        if http_method == 'GET' and path_parameters.get('pedidoId'):
            return get_pedido_by_id(path_parameters['pedidoId'])
        elif http_method == 'GET' and query_params.get('userType') and query_params.get('userId'):
            mock_user = {'user_id': int(query_params['userId'])}
            return get_pedidos_by_user(query_params['userType'], query_params['userId'], mock_user)
        elif http_method == 'GET' and query_params.get('pedidoId'):
            return get_pedido_by_id(query_params['pedidoId'])
        elif http_method == 'POST':
            if 'aceitar' in event.get('resource', ''):
                return aceitar_pedido(event)
            elif 'cancelar' in event.get('resource', ''):
                return cancelar_pedido(path_parameters['pedidoId'])
            else:
                return create_pedido(event)

        elif http_method == 'PATCH' and 'cancelar' in event.get('resource', ''):
            return cancelar_pedido(path_parameters['pedidoId'])

        elif http_method == 'OPTIONS':
            return cors_response(200, {})

        return cors_response(405, {'message': 'Method not allowed'})

    except Exception as e:
        print(f"Error in pedidos lambda: {str(e)}")
        return cors_response(500, {'message': f'Erro: {str(e)}'})


def get_pedidos_by_user(user_type, user_id, user_info):
    try:
        # Com JWT comentado, pular validação de usuário
        # requested_user_id = int(user_id)
        # authenticated_user_id = user_info['user_id']
        # if requested_user_id != authenticated_user_id:
        #     return cors_response(403, {'message': 'Acesso negado aos pedidos deste usuário'})

        if user_type == 'cliente':
            response = pedidos_table.scan(
                FilterExpression='clienteId = :client_id',
                ExpressionAttributeValues={':client_id': int(user_id)}
            )
        elif user_type == 'motorista':
            response = pedidos_table.scan(
                FilterExpression='motoristaId = :motorista_id',
                ExpressionAttributeValues={':motorista_id': int(user_id)}
            )
        elif user_type == 'operador':
            response = pedidos_table.scan(
                FilterExpression='operadorId = :operador_id',
                ExpressionAttributeValues={':operador_id': int(user_id)}
            )
        else:
            return cors_response(400, {'message': 'Tipo de usuário inválido'})

        pedidos = response.get('Items', [])

        formatted_pedidos = []
        for pedido in pedidos:
            formatted_pedidos.append({
                'id': int(pedido['id']),
                'origemLatitude': str(pedido['origemLatitude']),
                'origemLongitude': str(pedido['origemLongitude']),
                'destinoLatitude': str(pedido['destinoLatitude']),
                'destinoLongitude': str(pedido['destinoLongitude']),
                'tipoMercadoria': str(pedido['tipoMercadoria']),
                'status': str(pedido['status']),
                'clienteId': int(pedido.get('clienteId', 0)),
                'motoristaId': int(pedido.get('motoristaId', 0)) if pedido.get('motoristaId') is not None else None,
                'dataCriacao': str(pedido['dataCriacao']),
                'dataAtualizacao': str(pedido.get('dataAtualizacao', pedido['dataCriacao'])),
                'dataEntregaEstimada': str(pedido.get('dataEntregaEstimada')) if pedido.get('dataEntregaEstimada') else None,
                'tempoEstimadoMinutos': int(pedido.get('tempoEstimadoMinutos', 0)),
                'distanciaKm': float(pedido.get('distanciaKm', 0.0)),
                'rotaMotorista': pedido.get('rotaMotorista')
            })

        return cors_response(200, json.loads(json.dumps(formatted_pedidos, cls=DecimalEncoder)))

    except Exception as e:
        print(f"Error getting pedidos: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar pedidos: {str(e)}'})


def get_pedido_by_id(pedido_id):
    try:
        response = pedidos_table.get_item(Key={'id': str(pedido_id)})

        if 'Item' not in response:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'message': 'Pedido não encontrado'})
            }

        pedido = response['Item']
        formatted_pedido = {
            'id': int(pedido['id']),
            'origemLatitude': str(pedido['origemLatitude']),
            'origemLongitude': str(pedido['origemLongitude']),
            'destinoLatitude': str(pedido['destinoLatitude']),
            'destinoLongitude': str(pedido['destinoLongitude']),
            'tipoMercadoria': str(pedido['tipoMercadoria']),
            'status': str(pedido['status']),
            'clienteId': int(pedido.get('clienteId', 0)),
            'motoristaId': int(pedido.get('motoristaId', 0)) if pedido.get('motoristaId') is not None else None,
            'dataCriacao': str(pedido['dataCriacao']),
            'dataAtualizacao': str(pedido.get('dataAtualizacao', pedido['dataCriacao'])),
            'dataEntregaEstimada': str(pedido.get('dataEntregaEstimada')) if pedido.get('dataEntregaEstimada') else None,
            'tempoEstimadoMinutos': int(pedido.get('tempoEstimadoMinutos', 0)),
            'distanciaKm': float(pedido.get('distanciaKm', 0.0)),
            'rotaMotorista': pedido.get('rotaMotorista')
        }

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(formatted_pedido, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"Error fetching pedido by ID: {str(e)}")
        return cors_response(500, {'message': f'Erro ao buscar pedido: {str(e)}'})


def create_pedido(event):
    try:
        body = json.loads(event['body'])

        # Criar ID único
        pedido_id = int(str(uuid.uuid4().int)[:10])
        data_criacao = datetime.utcnow().isoformat()

        pedido = {
            'id': str(pedido_id),
            'origemLatitude': str(body['origemLatitude']),
            'origemLongitude': str(body['origemLongitude']),
            'destinoLatitude': str(body['destinoLatitude']),
            'destinoLongitude': str(body['destinoLongitude']),
            'tipoMercadoria': str(body['tipoMercadoria']),
            'clienteId': int(body['clienteId']),
            'status': 'AGUARDANDO_MOTORISTA',
            'dataCriacao': data_criacao,
            'dataAtualizacao': data_criacao,
            'dataEntregaEstimada': body.get('dataEntregaEstimada'),
            'tempoEstimadoMinutos': int(body.get('tempoEstimadoMinutos', 0)),
            # CORREÇÃO: Usar Decimal em vez de float
            'distanciaKm': convert_to_decimal(body.get('distanciaKm', 0.0)),
            'rotaMotorista': body.get('rotaMotorista')
        }

        # Salvar no DynamoDB
        pedidos_table.put_item(Item=pedido)

        # Publicar evento PEDIDO_CRIADO (compatível com RabbitMQ Java)
        try:
            publicar_evento_pedido('PEDIDO_CRIADO', pedido_id, pedido, body)
        except Exception as e:
            print(f"Error publishing PEDIDO_CRIADO event: {str(e)}")

        # Enviar mensagem para SQS (se configurado) - manter compatibilidade
        try:
            sqs_queue_url = os.environ.get('SQS_QUEUE_URL')
            if sqs_queue_url:
                message_body = json.dumps({
                    'event': 'pedido_created',
                    'pedido_id': pedido_id,
                    'cliente_id': pedido['clienteId'],
                    'origem_latitude': pedido['origemLatitude'],
                    'origem_longitude': pedido['origemLongitude'],
                    'destino_latitude': pedido['destinoLatitude'],
                    'destino_longitude': pedido['destinoLongitude'],
                    'tipo_mercadoria': pedido['tipoMercadoria'],
                    'origem_endereco': body.get('origemEndereco', ''),
                    'destino_endereco': body.get('destinoEndereco', '')
                })
                
                # Verificar se é fila FIFO (tem .fifo no final)
                if sqs_queue_url.endswith('.fifo'):
                    sqs.send_message(
                        QueueUrl=sqs_queue_url,
                        MessageBody=message_body,
                        MessageGroupId='pedidos',  # Agrupar todos os pedidos
                        MessageDeduplicationId=f"pedido_{pedido_id}_{int(datetime.utcnow().timestamp())}"
                    )
                else:
                    sqs.send_message(
                        QueueUrl=sqs_queue_url,
                        MessageBody=message_body
                    )
        except Exception as e:
            print(f"Error sending SQS message: {str(e)}")

        # Resposta formatada (convertendo Decimal para float na resposta)
        formatted_pedido = {
            'id': pedido_id,
            'origemLatitude': pedido['origemLatitude'],
            'origemLongitude': pedido['origemLongitude'],
            'destinoLatitude': pedido['destinoLatitude'],
            'destinoLongitude': pedido['destinoLongitude'],
            'tipoMercadoria': pedido['tipoMercadoria'],
            'status': pedido['status'],
            'clienteId': pedido['clienteId'],
            'motoristaId': None,
            'dataCriacao': pedido['dataCriacao'],
            'dataAtualizacao': pedido['dataAtualizacao'],
            'dataEntregaEstimada': pedido.get('dataEntregaEstimada'),
            'tempoEstimadoMinutos': pedido['tempoEstimadoMinutos'],
            'distanciaKm': float(pedido['distanciaKm']),  # Converte para float na resposta
            'rotaMotorista': pedido.get('rotaMotorista')
        }

        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(formatted_pedido, cls=DecimalEncoder)
        }

    except Exception as e:
        print(f"Erro ao criar pedido: {str(e)}")
        return cors_response(500, {'message': f'Erro ao criar pedido: {str(e)}'})


def aceitar_pedido(event):
    path_parameters = event.get('pathParameters', {})
    query_parameters = event.get('queryStringParameters', {})

    pedido_id = path_parameters.get('pedidoId')
    motorista_id = query_parameters.get('motoristaId')
    latitude = query_parameters.get('latitude')
    longitude = query_parameters.get('longitude')

    # Atualizar pedido
    pedidos_table.update_item(
        Key={'id': str(pedido_id)},
        UpdateExpression='SET motoristaId = :mid, #status = :status, dataAceite = :data',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':mid': int(motorista_id),
            ':status': 'EM_ROTA',
            ':data': str(datetime.utcnow())
        }
    )
    
    # Publicar evento STATUS_ATUALIZADO
    try:
        pedido_atualizado = {
            'id': str(pedido_id),
            'motoristaId': int(motorista_id),
            'status': 'EM_ROTA',
            'dataAceite': str(datetime.utcnow())
        }
        publicar_evento_pedido('STATUS_ATUALIZADO', int(pedido_id), pedido_atualizado, {})
    except Exception as e:
        print(f"Error publishing STATUS_ATUALIZADO event: {str(e)}")

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Pedido aceito com sucesso'})
    }

def cancelar_pedido(pedido_id):
    pedidos_table.update_item(
        Key={'id': str(pedido_id)},
        UpdateExpression='SET #status = :status, dataCancelamento = :data',
        ExpressionAttributeNames={'#status': 'status'},
        ExpressionAttributeValues={
            ':status': 'CANCELADO',
            ':data': str(datetime.utcnow())
        }
    )
    
    # Publicar evento PEDIDO_CANCELADO
    try:
        pedido_cancelado = {
            'id': str(pedido_id),
            'status': 'CANCELADO',
            'dataCancelamento': str(datetime.utcnow())
        }
        publicar_evento_pedido('PEDIDO_CANCELADO', int(pedido_id), pedido_cancelado, {'motivo': 'Cancelado pelo sistema'})
    except Exception as e:
        print(f"Error publishing PEDIDO_CANCELADO event: {str(e)}")

    return {
        'statusCode': 204,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': ''
    }

def publicar_evento_pedido(evento: str, pedido_id: int, pedido: dict, body: dict):
    """
    Publica evento no SNS Topic - replica PedidoEventSender do Java
    """
    try:
        sns_topic_arn = os.environ.get('SNS_TOPIC_ARN')
        if not sns_topic_arn:
            print("SNS_TOPIC_ARN não configurado")
            return
        
        # Estrutura da mensagem compatível com EventoConsumer Java
        dados = {
            'pedidoId': pedido_id,
            'clienteId': pedido['clienteId'],
            'origemLatitude': pedido['origemLatitude'],
            'origemLongitude': pedido['origemLongitude'],
            'destinoLatitude': pedido['destinoLatitude'],
            'destinoLongitude': pedido['destinoLongitude'],
            'tipoMercadoria': pedido['tipoMercadoria'],
            'status': pedido['status'],
            'dataCriacao': pedido['dataCriacao'],
            'tempoEstimadoMinutos': pedido.get('tempoEstimadoMinutos', 0),
            'distanciaKm': float(pedido.get('distanciaKm', 0.0)),
            'origemEndereco': body.get('origemEndereco', ''),
            'destinoEndereco': body.get('destinoEndereco', '')
        }
        
        if evento == 'STATUS_ATUALIZADO':
            dados['novoStatus'] = pedido['status']
            dados['motoristaId'] = pedido.get('motoristaId')
        elif evento == 'PEDIDO_CANCELADO':
            dados['motivo'] = body.get('motivo', 'Cancelado pelo cliente')
        
        mensagem = {
            'evento': evento,
            'origem': 'pedidos',
            'timestamp': datetime.utcnow().isoformat(),
            'dados': dados
        }
        
        # Publicar no SNS com message attributes para filtering
        sns.publish(
            TopicArn=sns_topic_arn,
            Message=json.dumps(mensagem, cls=DecimalEncoder),
            MessageAttributes={
                'evento': {
                    'DataType': 'String',
                    'StringValue': evento
                },
                'origem': {
                    'DataType': 'String', 
                    'StringValue': 'pedidos'
                }
            }
        )
        
        print(f"Evento {evento} publicado no SNS para pedido {pedido_id}")
        
    except Exception as e:
        print(f"Erro ao publicar evento {evento}: {str(e)}")