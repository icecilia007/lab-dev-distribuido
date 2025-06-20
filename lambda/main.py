import json
import requests
import os
import psycopg2
from datetime import datetime


class NotificationLambda:
    """
    Lambda that replicates exactly what the Java notification service EventoConsumer does.
    Processes events from RabbitMQ with the same logic as the Java system.
    """

    def __init__(self):
        self.notificacoes_url = os.getenv('NOTIFICACOES_URL', 'http://host.docker.internal:8083')
        self.headers = {
            'X-Internal-Auth': '2BE2AB6217329B86A427A3819B626',
            'Content-Type': 'application/json'
        }
        self.db_config = {
            'host': os.getenv('DB_HOST', 'host.docker.internal'),
            'port': os.getenv('DB_PORT', '5432'),
            'database': os.getenv('DB_NAME', 'main_db'),
            'user': os.getenv('DB_USER', 'postgres'),
            'password': os.getenv('DB_PASSWORD', 'postgres')
        }

    def convert_to_long(self, value):
        """Convert value to long integer, similar to Java convertToLong method"""
        if isinstance(value, int):
            return value
        elif isinstance(value, str):
            try:
                return int(value)
            except ValueError:
                return None
        return None

    def gerar_conteudo_notificacao(self, tipo_evento, dados):
        """Generate notification content based on event type - exactly like Java gerarConteudoNotificacao"""
        conteudo = {}

        if tipo_evento == "PEDIDO_CRIADO":
            conteudo["titulo"] = "Novo pedido criado"
            conteudo["mensagem"] = "Seu pedido foi registrado com sucesso!"
        elif tipo_evento == "STATUS_ATUALIZADO":
            status = dados.get("novoStatus", "atualizado")
            conteudo["titulo"] = "Status atualizado"
            conteudo["mensagem"] = f"Seu pedido agora está {status}"
        elif tipo_evento == "PEDIDO_CANCELADO":
            motivo = dados.get("motivo", "")
            conteudo["titulo"] = "Pedido cancelado"
            if motivo:
                conteudo["mensagem"] = f"Seu pedido foi cancelado: {motivo}"
            else:
                conteudo["mensagem"] = "Seu pedido foi cancelado"
        elif tipo_evento == "PEDIDO_DISPONIVEL":
            origem = dados.get("origemEndereco", "local de coleta")
            conteudo["titulo"] = "Novo pedido disponível"
            conteudo["mensagem"] = f"Há um novo pedido disponível para coleta em {origem}"
        elif tipo_evento in ["INCIDENTE_REPORTADO", "ALERTA_INCIDENTE"]:
            tipo = dados.get("tipo", "incidente")
            conteudo["titulo"] = f"Alerta: {tipo}"
            conteudo["mensagem"] = "Um incidente foi reportado na sua rota"
        elif tipo_evento == "STATUS_VEICULO_ALTERADO":
            status_veiculo = dados.get("statusVeiculo", "")
            conteudo["titulo"] = "Status atualizado"
            conteudo["mensagem"] = f"O status do veículo foi atualizado para: {status_veiculo}"
        else:
            conteudo["titulo"] = "Notificação do sistema"
            conteudo["mensagem"] = f"Evento: {tipo_evento}"

        return conteudo

    def criar_notificacao(self, destinatario_id, tipo_evento, origem, dados, mensagem_completa):
        """Create notification - exactly like Java criarNotificacao method"""
        print(f"Criando notificacao para destinatário: {destinatario_id}, evento: {tipo_evento}")

        try:
            conteudo = self.gerar_conteudo_notificacao(tipo_evento, dados)

            notification_id = self.save_notification_to_db(
                tipo_evento=tipo_evento,
                origem=origem,
                destinatario_id=destinatario_id,
                titulo=conteudo["titulo"],
                mensagem=conteudo["mensagem"],
                dados_evento=mensagem_completa
            )

            if notification_id:
                print(f"Notification created successfully: ID {notification_id}")
                return notification_id
            else:
                print(f"Failed to create notification for user {destinatario_id}")
                return None

        except Exception as e:
            print(f"Erro ao criar notificação para destinatário {destinatario_id}: {e}")
            return None

    def save_notification_to_db(self, tipo_evento, origem, destinatario_id, titulo, mensagem, dados_evento):
        """Saves notification directly to PostgreSQL database with exact Java schema"""
        try:
            conn = psycopg2.connect(**self.db_config)
            cursor = conn.cursor()

            query = """
                INSERT INTO notificacoes (tipo_evento, origem, destinatario_id, titulo, mensagem, 
                                       data_criacao, status, dados_evento)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id;
            """

            cursor.execute(query, (
                tipo_evento,
                origem,
                destinatario_id,
                titulo,
                mensagem,
                datetime.now(),
                'NAO_LIDA',
                json.dumps(dados_evento)
            ))

            notification_id = cursor.fetchone()[0]
            conn.commit()
            print(f"Notification saved to database: ID {notification_id}")

            cursor.close()
            conn.close()
            return notification_id

        except Exception as e:
            print(f"Error saving to database: {e}")
            return None

    def processar_evento(self, mensagem):
        """Main event processor - exactly like Java processarEvento method"""
        try:
            print(f"Recebido evento: {mensagem}")

            tipo_evento = mensagem.get("evento")
            origem = mensagem.get("origem", "LAMBDA")
            dados = mensagem.get("dados", {})

            if dados is None:
                print(f"Evento recebido sem dados: {tipo_evento}")
                return {"status": "ignored", "message": "Event without data"}

            return self.processar_destinatarios(tipo_evento, origem, dados, mensagem)

        except Exception as e:
            print(f"Erro ao processar evento: {e}")
            return {"status": "error", "message": str(e)}

    def processar_destinatarios(self, tipo_evento, origem, dados, mensagem_completa):
        """Process recipients - exactly like Java processarDestinatarios method"""
        notifications_created = []

        if tipo_evento == "PEDIDO_DISPONIVEL":
            if "motoristasProximos" in dados:
                notifications_created.extend(
                    self.processar_lista(dados, "motoristasProximos", tipo_evento, origem, mensagem_completa)
                )
        else:
            if "clienteId" in dados and dados["clienteId"] is not None:
                notif_id = self.processar_id(dados, "clienteId", tipo_evento, origem, mensagem_completa)
                if notif_id:
                    notifications_created.append(notif_id)

            if "motoristaId" in dados and dados["motoristaId"] is not None:
                notif_id = self.processar_id(dados, "motoristaId", tipo_evento, origem, mensagem_completa)
                if notif_id:
                    notifications_created.append(notif_id)

        return {
            "status": "success",
            "message": f"Event {tipo_evento} processed",
            "notifications_created": len(notifications_created),
            "notification_ids": notifications_created
        }

    def processar_id(self, dados, campo_id, tipo_evento, origem, mensagem_completa):
        """Process single ID - exactly like Java processarId method"""
        if campo_id in dados and dados[campo_id] is not None:
            user_id = self.convert_to_long(dados[campo_id])
            if user_id is not None:
                return self.criar_notificacao(user_id, tipo_evento, origem, dados, mensagem_completa)
        return None

    def processar_lista(self, dados, campo_lista, tipo_evento, origem, mensagem_completa):
        """Process list of IDs - exactly like Java processarLista method"""
        notifications_created = []

        if campo_lista in dados and isinstance(dados[campo_lista], list):
            lista = dados[campo_lista]
            for item in lista:
                user_id = self.convert_to_long(item)
                if user_id is not None:
                    notif_id = self.criar_notificacao(user_id, tipo_evento, origem, dados, mensagem_completa)
                    if notif_id:
                        notifications_created.append(notif_id)

        return notifications_created


def extract_event_data(event):
    """Extracts event data from AWS Lambda RabbitMQ format or simple format"""
    try:
        if isinstance(event, str):
            event = json.loads(event)

        event_data = {}

        if "Records" in event and len(event["Records"]) > 0:
            record = event["Records"][0]

            if "rmqMessagesByQueue" in record:
                for queue_name, messages in record["rmqMessagesByQueue"].items():
                    if messages and len(messages) > 0:
                        message = messages[0]
                        if "data" in message:
                            message_data = json.loads(message["data"])
                            event_data.update(message_data)

        for key, value in event.items():
            if key not in ["Records"]:
                event_data[key] = value

        return event_data

    except Exception as e:
        print(f"Error extracting event: {e}")
        return event


def main(event, context):
    """
    Main Lambda handler.
    Replicates exactly the Java EventoConsumer.processarEvento behavior.
    """
    try:
        print(f"\nLambda invoked!")
        print(f"Event: {json.dumps(event, indent=2)}")

        event_data = extract_event_data(event)

        notification_lambda = NotificationLambda()

        if "evento" in event_data:
            result = notification_lambda.processar_evento(event_data)
        else:
            event_type = event_data.get('type', 'unknown')
            print(f"Legacy event type: {event_type}")

            if event_type in ['pedido_finalizado', 'pedido_entregue']:
                java_event = {
                    "evento": "STATUS_ATUALIZADO" if event_type == 'pedido_entregue' else event_type,
                    "origem": "LAMBDA",
                    "dados": event_data
                }
                result = notification_lambda.processar_evento(java_event)
            else:
                print(f"Unsupported event type: {event_type}")
                result = {"status": "ignored", "message": f"Event {event_type} ignored"}

        print(f"Result: {result}")

        return {
            'statusCode': 200,
            'body': json.dumps(result),
            'headers': {'Content-Type': 'application/json'}
        }

    except Exception as e:
        print(f"Lambda error: {e}")
        import traceback
        traceback.print_exc()

        return {
            'statusCode': 500,
            'body': json.dumps({
                'status': 'error',
                'message': str(e)
            }),
            'headers': {'Content-Type': 'application/json'}
        }
