#!/bin/bash

# Script simplificado para testar apenas a finalização de corrida
# Pressupõe que você já tem um pedido em andamento (status EM_ROTA)

BASE_URL="http://localhost:8000"

echo "=== TESTE SIMPLES DE FINALIZAÇÃO DE CORRIDA ==="
echo

# Parâmetros - ALTERE ESTES VALORES CONFORME SEU PEDIDO EXISTENTE
PEDIDO_ID="1"  # Substitua pelo ID do seu pedido em EM_ROTA
MOTORISTA_ID="1"  # Substitua pelo ID do seu motorista

echo "Testando com:"
echo "- Pedido ID: $PEDIDO_ID"
echo "- Motorista ID: $MOTORISTA_ID"
echo "- Email de teste: arihenriquedev@hotmail.com"
echo

# 1. Verificar status atual do pedido
echo "1. Verificando status atual do pedido..."
STATUS_ATUAL=$(curl -s -X GET "${BASE_URL}/api/pedidos/${PEDIDO_ID}" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626")
echo "Status atual: $STATUS_ATUAL"
echo

# 2. Posicionar motorista no destino com status EM_MOVIMENTO
echo "2. Posicionando motorista no destino (coordenadas de Berlim) com status EM_MOVIMENTO..."
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": $PEDIDO_ID,
    \"latitude\": 52.520008,
    \"longitude\": 13.404954,
    \"statusVeiculo\": \"EM_MOVIMENTO\"
  }"
echo "Motorista posicionado no destino."
echo

# 3. CONFIRMAR ENTREGA - Este é o passo que dispara o email
echo "3. *** CONFIRMANDO ENTREGA (DEVE DISPARAR EMAIL) ***"
ENTREGA_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/rastreamento/pedido/${PEDIDO_ID}/entrega?motoristaId=${MOTORISTA_ID}" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626")

echo "Resposta da entrega: $ENTREGA_RESPONSE"
echo

# 4. Verificar status final
echo "4. Verificando status final do pedido..."
STATUS_FINAL=$(curl -s -X GET "${BASE_URL}/api/pedidos/${PEDIDO_ID}" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626")
echo "Status final: $STATUS_FINAL"
echo

echo "=== PONTOS DE VERIFICAÇÃO ==="
echo "1. Status do pedido deve estar 'ENTREGUE'"
echo "2. Verifique os logs do serviço de notificação:"
echo "   - Deve aparecer 'Status é ENTREGUE, enviando email de entrega'"
echo "   - Deve aparecer 'Email de entrega enviado para cliente'"
echo "3. Verifique a fila SQS para mensagem de email"
echo "4. Verifique se email chegou em arihenriquedev@hotmail.com"
echo "5. Verifique logs da Lambda se configurada"
echo

echo "Comandos úteis para debug:"
echo "# Ver logs do container de notificação:"
echo "docker logs <container_notificacao>"
echo
echo "# Ver mensagens na fila SQS (se AWS CLI configurado):"
echo "aws sqs receive-message --queue-url <sua_queue_url>"