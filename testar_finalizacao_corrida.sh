#!/bin/bash

# Script para testar finalização de corrida e envio de email
# Usa o email arihenriquedev@hotmail.com para testes

BASE_URL="http://localhost:8000"
BEARER_TOKEN=""
CLIENT_ID=""
MOTORISTA_ID=""
PEDIDO_ID=""

echo "=== TESTE DE FINALIZAÇÃO DE CORRIDA E ENVIO DE EMAIL ==="
echo

# 1. Login para obter token
echo "1. Fazendo login do motorista..."
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/auth/login" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d '{
    "email": "pedro.motorista@exemplo.com",
    "password": "senha456"
  }')

echo "Login response: $LOGIN_RESPONSE"

# Extrair token do header da resposta (simulação - ajustar conforme implementação)
BEARER_TOKEN="seu_token_aqui"  # Você precisará extrair do header da resposta real

echo "2. Cadastrando cliente com email de teste..."
CLIENT_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/registro/usuarios/clientes" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d '{
    "nome": "Ari Teste",
    "email": "arihenriquedev@hotmail.com",
    "senha": "senha123",
    "telefone": "11999998888"
  }')

echo "Cliente response: $CLIENT_RESPONSE"
CLIENT_ID=$(echo $CLIENT_RESPONSE | jq -r '.id // empty')

if [ -z "$CLIENT_ID" ]; then
  echo "Erro: Não foi possível obter ID do cliente"
  exit 1
fi

echo "Cliente ID: $CLIENT_ID"

echo "3. Cadastrando motorista..."
MOTORISTA_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/registro/usuarios/motoristas" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d '{
    "nome": "Pedro Motorista Teste",
    "email": "pedro.motorista@exemplo.com",
    "senha": "senha456",
    "telefone": "11988887777",
    "placa": "ABC1234",
    "modeloVeiculo": "Fiat Strada",
    "anoVeiculo": 2022,
    "consumoMedioPorKm": 12.5
  }')

echo "Motorista response: $MOTORISTA_RESPONSE"
MOTORISTA_ID=$(echo $MOTORISTA_RESPONSE | jq -r '.id // empty')

if [ -z "$MOTORISTA_ID" ]; then
  echo "Erro: Não foi possível obter ID do motorista"
  exit 1
fi

echo "Motorista ID: $MOTORISTA_ID"

echo "4. Criando localização inicial do motorista..."
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": null,
    \"latitude\": 52.516677,
    \"longitude\": 13.388763,
    \"statusVeiculo\": \"DISPONIVEL\"
  }"

echo "5. Criando pedido..."
PEDIDO_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/pedidos" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d "{
    \"origemLatitude\": 52.516677,
    \"origemLongitude\": 13.388763,
    \"destinoLatitude\": 52.520008,
    \"destinoLongitude\": 13.404954,
    \"tipoMercadoria\": \"Teste Email\",
    \"clienteId\": $CLIENT_ID
  }")

echo "Pedido response: $PEDIDO_RESPONSE"
PEDIDO_ID=$(echo $PEDIDO_RESPONSE | jq -r '.id // empty')

if [ -z "$PEDIDO_ID" ]; then
  echo "Erro: Não foi possível obter ID do pedido"
  exit 1
fi

echo "Pedido ID: $PEDIDO_ID"

echo "6. Motorista aceita o pedido..."
curl -s -X POST "${BASE_URL}/api/pedidos/${PEDIDO_ID}/aceitar?motoristaId=${MOTORISTA_ID}&latitude=52.517000&longitude=13.389000" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626"

echo "7. Simulando deslocamento para coleta..."
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": $PEDIDO_ID,
    \"latitude\": 52.516677,
    \"longitude\": 13.388763,
    \"statusVeiculo\": \"EM_MOVIMENTO\"
  }"

echo "8. Confirmando coleta..."
curl -s -X POST "${BASE_URL}/api/rastreamento/pedido/${PEDIDO_ID}/coleta?motoristaId=${MOTORISTA_ID}" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626"

echo "9. Simulando deslocamento para destino (EM_MOVIMENTO)..."
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": $PEDIDO_ID,
    \"latitude\": 52.519000,
    \"longitude\": 13.400000,
    \"statusVeiculo\": \"EM_MOVIMENTO\"
  }"

echo "10. Chegando próximo ao destino (ainda EM_MOVIMENTO)..."
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

echo "11. FINALIZANDO CORRIDA - Confirmando entrega..."
echo "    * Motorista deve estar no local de destino"
echo "    * Status deve ser EM_MOVIMENTO"
echo "    * Isso deve disparar o evento de entrega e email para arihenriquedev@hotmail.com"

ENTREGA_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/rastreamento/pedido/${PEDIDO_ID}/entrega?motoristaId=${MOTORISTA_ID}" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626")

echo "Entrega response: $ENTREGA_RESPONSE"

echo "12. Verificando status final do pedido..."
STATUS_RESPONSE=$(curl -s -X GET "${BASE_URL}/api/pedidos/${PEDIDO_ID}" \
  -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626")

echo "Status final: $STATUS_RESPONSE"

echo
echo "=== VERIFICAÇÕES ==="
echo "1. Verifique os logs do serviço de notificação para o evento ENTREGUE"
echo "2. Verifique a fila SQS para a mensagem de email"
echo "3. Verifique se o email foi enviado para arihenriquedev@hotmail.com"
echo "4. Pedido ID para referência: $PEDIDO_ID"
echo "5. Cliente ID: $CLIENT_ID"
echo "6. Motorista ID: $MOTORISTA_ID"
echo
echo "Comando para verificar status do pedido novamente:"
echo "curl -X GET \"${BASE_URL}/api/pedidos/${PEDIDO_ID}\" -H \"X-Internal-Auth: 2BE2AB6217329B86A427A3819B626\""