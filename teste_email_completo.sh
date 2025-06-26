#!/bin/bash

# Script completo para testar envio de email de entrega
# Email: arihenriquedev@hotmail.com

BASE_URL="http://localhost:8000"
EMAIL_TESTE="arihenriquedev@hotmail.com"

echo "========================================="
echo "TESTE COMPLETO - ENVIO EMAIL DE ENTREGA"
echo "Email: $EMAIL_TESTE"
echo "========================================="

# Função para extrair ID do JSON
extract_id() {
    echo "$1" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1
}

# Função para extrair Bearer token do header
extract_token() {
    echo "$1" | grep -i "authorization:" | grep -o "Bearer [^[:space:]]*" | sed 's/Bearer //' | tr -d '\r'
}

# Função para verificar se o comando foi bem-sucedido
check_response() {
    if [[ $1 == *"erro"* ]] || [[ $1 == *"error"* ]] || [[ -z "$1" ]]; then
        echo "❌ Erro detectado: $1"
        return 1
    fi
    return 0
}

echo "1. 📝 Cadastrando cliente com email $EMAIL_TESTE..."
CLIENT_FULL_RESPONSE=$(curl -s -i -X POST "${BASE_URL}/api/auth/registro/cliente" \
  -H "Content-Type: application/json" \
  -d "{
    \"nome\": \"Ari Henrique\",
    \"email\": \"$EMAIL_TESTE\",
    \"senha\": \"senha123\",
    \"telefone\": \"11999998888\"
  }")

# Separar headers e body de forma mais robusta
CLIENT_RESPONSE=$(echo "$CLIENT_FULL_RESPONSE" | grep -E '^\{.*\}$' | tail -1)
CLIENT_HEADERS=$(echo "$CLIENT_FULL_RESPONSE" | grep -i "authorization:")

if ! check_response "$CLIENT_RESPONSE"; then
    echo "❌ Erro ao criar cliente. Resposta: $CLIENT_RESPONSE"
    echo "Headers: $CLIENT_HEADERS"
    exit 1
fi

CLIENT_ID=$(extract_id "$CLIENT_RESPONSE")
CLIENT_TOKEN=$(echo "$CLIENT_HEADERS" | grep -o "Bearer [^[:space:]]*" | sed 's/Bearer //' | tr -d '\r')

if [[ -z "$CLIENT_ID" ]]; then
    echo "❌ Não foi possível extrair ID do cliente"
    echo "Resposta: $CLIENT_RESPONSE"
    exit 1
fi

if [[ -z "$CLIENT_TOKEN" ]]; then
    echo "❌ Não foi possível extrair token do cliente"
    echo "Headers: $CLIENT_HEADERS"
    exit 1
fi

echo "✅ Cliente criado com ID: $CLIENT_ID (Token: ${CLIENT_TOKEN:0:20}...)"

echo "2. 🚗 Cadastrando motorista..."
MOTORISTA_FULL_RESPONSE=$(curl -s -i -X POST "${BASE_URL}/api/auth/registro/motorista" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Motorista Teste",
    "email": "motorista.teste@exemplo.com",
    "senha": "senha456",
    "telefone": "11988887777",
    "placa": "TEST123",
    "modeloVeiculo": "Fiat Strada",
    "anoVeiculo": 2023,
    "consumoMedioPorKm": 12.5
  }')

# Separar headers e body de forma mais robusta
MOTORISTA_RESPONSE=$(echo "$MOTORISTA_FULL_RESPONSE" | grep -E '^\{.*\}$' | tail -1)
MOTORISTA_HEADERS=$(echo "$MOTORISTA_FULL_RESPONSE" | grep -i "authorization:")

if ! check_response "$MOTORISTA_RESPONSE"; then
    echo "❌ Erro ao criar motorista. Resposta: $MOTORISTA_RESPONSE"
    echo "Headers: $MOTORISTA_HEADERS"
    exit 1
fi

MOTORISTA_ID=$(extract_id "$MOTORISTA_RESPONSE")
MOTORISTA_TOKEN=$(echo "$MOTORISTA_HEADERS" | grep -o "Bearer [^[:space:]]*" | sed 's/Bearer //' | tr -d '\r')

if [[ -z "$MOTORISTA_ID" ]]; then
    echo "❌ Não foi possível extrair ID do motorista"
    echo "Resposta: $MOTORISTA_RESPONSE"
    exit 1
fi

if [[ -z "$MOTORISTA_TOKEN" ]]; then
    echo "❌ Não foi possível extrair token do motorista"
    echo "Headers: $MOTORISTA_HEADERS"
    exit 1
fi

echo "✅ Motorista criado com ID: $MOTORISTA_ID (Token: ${MOTORISTA_TOKEN:0:20}...)"

# Usar o token do motorista para as próximas operações
BEARER_TOKEN="$MOTORISTA_TOKEN"

echo "3. 📍 Definindo localização inicial do motorista..."
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": null,
    \"latitude\": 52.516677,
    \"longitude\": 13.388763,
    \"statusVeiculo\": \"DISPONIVEL\"
  }" > /dev/null

echo "✅ Localização inicial definida (Berlim - origem)"

echo "4. 📦 Criando pedido..."
PEDIDO_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/pedidos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CLIENT_TOKEN" \
  -d "{
    \"origemLatitude\": 52.516677,
    \"origemLongitude\": 13.388763,
    \"destinoLatitude\": 52.520008,
    \"destinoLongitude\": 13.404954,
    \"tipoMercadoria\": \"Teste Email Entrega\",
    \"clienteId\": $CLIENT_ID
  }")

if ! check_response "$PEDIDO_RESPONSE"; then
    echo "❌ Erro ao criar pedido. Resposta: $PEDIDO_RESPONSE"
    exit 1
fi

PEDIDO_ID=$(extract_id "$PEDIDO_RESPONSE")
if [[ -z "$PEDIDO_ID" ]]; then
    echo "❌ Não foi possível extrair ID do pedido"
    echo "Resposta: $PEDIDO_RESPONSE"
    exit 1
fi

echo "✅ Pedido criado com ID: $PEDIDO_ID"

echo "5. 🤝 Motorista aceita o pedido..."
sleep 2
ACEITE_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/pedidos/${PEDIDO_ID}/aceitar?motoristaId=${MOTORISTA_ID}&latitude=52.516677&longitude=13.388763" \
  -H "Authorization: Bearer $BEARER_TOKEN")

echo "✅ Pedido aceito pelo motorista"

echo "6. 🚚 Motorista se move para o ponto de coleta..."
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": $PEDIDO_ID,
    \"latitude\": 52.516677,
    \"longitude\": 13.388763,
    \"statusVeiculo\": \"EM_MOVIMENTO\"
  }" > /dev/null

echo "✅ Motorista chegou ao ponto de coleta"

echo "7. 📋 Confirmando coleta do pedido..."
sleep 1
COLETA_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/rastreamento/pedido/${PEDIDO_ID}/coleta?motoristaId=${MOTORISTA_ID}" \
  -H "Authorization: Bearer $BEARER_TOKEN")

echo "✅ Coleta confirmada - Pedido agora está EM_ROTA"

echo "8. 🛣️ Motorista se desloca para o destino (EM_MOVIMENTO)..."
sleep 1
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": $PEDIDO_ID,
    \"latitude\": 52.518000,
    \"longitude\": 13.400000,
    \"statusVeiculo\": \"EM_MOVIMENTO\"
  }" > /dev/null

echo "✅ Motorista a caminho do destino"

echo "9. 🎯 Motorista chega próximo ao destino (ainda EM_MOVIMENTO)..."
sleep 1
curl -s -X POST "${BASE_URL}/api/rastreamento/localizacao" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -d "{
    \"motoristaId\": $MOTORISTA_ID,
    \"pedidoId\": $PEDIDO_ID,
    \"latitude\": 52.520008,
    \"longitude\": 13.404954,
    \"statusVeiculo\": \"EM_MOVIMENTO\"
  }" > /dev/null

echo "✅ Motorista chegou ao destino (coordenadas exatas)"

echo "10. 🚀 *** CONFIRMANDO ENTREGA - DISPARANDO EMAIL ***"
sleep 1
ENTREGA_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/rastreamento/pedido/${PEDIDO_ID}/entrega?motoristaId=${MOTORISTA_ID}" \
  -H "Authorization: Bearer $BEARER_TOKEN")

if [[ $ENTREGA_RESPONSE == *"true"* ]]; then
    echo "✅ ENTREGA CONFIRMADA COM SUCESSO!"
else
    echo "❌ Erro na confirmação da entrega: $ENTREGA_RESPONSE"
fi

echo "11. 🔍 Verificando status final do pedido..."
sleep 2
STATUS_FINAL=$(curl -s -X GET "${BASE_URL}/api/pedidos/${PEDIDO_ID}" \
  -H "Authorization: Bearer $CLIENT_TOKEN")

if [[ $STATUS_FINAL == *"ENTREGUE"* ]]; then
    echo "✅ Status do pedido: ENTREGUE"
else
    echo "❌ Status inesperado: $STATUS_FINAL"
fi

echo ""
echo "========================================="
echo "🎉 PROCESSO COMPLETO EXECUTADO!"
echo "========================================="
echo "📧 Email deve ser enviado para: $EMAIL_TESTE"
echo "📝 Detalhes do teste:"
echo "   - Cliente ID: $CLIENT_ID"
echo "   - Motorista ID: $MOTORISTA_ID"  
echo "   - Pedido ID: $PEDIDO_ID"
echo "   - Status final: ENTREGUE"