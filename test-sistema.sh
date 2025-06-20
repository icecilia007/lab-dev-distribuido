#!/bin/bash

echo "=== Testing Logistics System ==="
echo "Starting system tests based on TESTES.md..."

BASE_URL="http://localhost:8000"
TIMESTAMP=$(date +%s)
CLIENT_EMAIL="joao.silva.$TIMESTAMP@exemplo.com"
DRIVER_EMAIL="pedro.motorista.$TIMESTAMP@exemplo.com"

make_request() {
    local method=$1
    local endpoint=$2
    local data=$3
    local token=$4

    headers=(
        -H "Content-Type: application/json"
        -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626"
    )

    if [ -n "$token" ]; then
        headers+=(-H "Authorization: Bearer $token")
    fi

    if [ -n "$data" ]; then
        curl -s -X "$method" "${headers[@]}" -d "$data" "$BASE_URL$endpoint"
    else
        curl -s -X "$method" "${headers[@]}" "$BASE_URL$endpoint"
    fi
}

make_request_no_auth() {
    local method=$1
    local endpoint=$2
    local data=$3

    headers=(
        -H "Content-Type: application/json"
        -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626"
    )

    if [ -n "$data" ]; then
        curl -s -X "$method" "${headers[@]}" -d "$data" "$BASE_URL$endpoint"
    else
        curl -s -X "$method" "${headers[@]}" "$BASE_URL$endpoint"
    fi
}

extract_id() {
    echo "$1" | grep -o '"id":[0-9]*' | cut -d':' -f2
}

# Function to login and extract token from response headers
login_usuario() {
    local email="$1"
    local senha="$2"

    response=$(curl -i -s -X POST "$BASE_URL/api/usuarios/login" \
        -H "Content-Type: application/json" \
        -H "X-Internal-Auth: 2BE2AB6217329B86A427A3819B626" \
        -d "{\"email\":\"$email\", \"password\":\"$senha\"}")

    echo "$response" | grep -i "^Authorization:" | sed -E 's/Authorization: Bearer (.*)/\1/i' | tr -d '\r'
}


echo ""
echo "1. Registering a client..."
CLIENT_RESPONSE=$(make_request_no_auth POST "/api/auth/registro/cliente" '{
    "nome": "Joao Silva",
    "email": "'$CLIENT_EMAIL'",
    "senha": "senha123",
    "telefone": "11999998888"
}')
CLIENT_ID=$(extract_id "$CLIENT_RESPONSE")
echo "Client registered with ID: $CLIENT_ID"
echo "Response: $CLIENT_RESPONSE"

echo ""
echo "2. Registering a driver..."
DRIVER_RESPONSE=$(make_request_no_auth POST "/api/auth/registro/motorista" '{
    "nome": "Pedro Motorista",
    "email": "'$DRIVER_EMAIL'",
    "senha": "senha456",
    "telefone": "11988887777",
    "placa": "ABC1234",
    "modeloVeiculo": "Fiat Strada",
    "anoVeiculo": 2022,
    "consumoMedioPorKm": 12.5
}')
DRIVER_ID=$(extract_id "$DRIVER_RESPONSE")
echo "Driver registered with ID: $DRIVER_ID"
echo "Response: $DRIVER_RESPONSE"

echo ""
echo "3. Logging in the driver to verify credentials..."
LOGIN_RESPONSE=$(curl -i -s -X POST "$BASE_URL/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$DRIVER_EMAIL\", \"password\":\"senha456\"}")

DRIVER_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -i "^Authorization:" | sed -E 's/Authorization: Bearer (.*)/\1/i' | tr -d '\r')
echo "Driver token: $DRIVER_TOKEN"

echo ""
echo "4. Setting initial driver location..."
LOCATION_RESPONSE=$(make_request POST "/api/rastreamento/localizacao" "{
    \"motoristaId\": $DRIVER_ID,
    \"latitude\": 52.516677,
    \"longitude\": 13.388763,
    \"statusVeiculo\": \"DISPONIVEL\"
}" "$DRIVER_TOKEN")
echo "Location set: $LOCATION_RESPONSE"

echo ""
echo "5. Verifying client exists..."
CLIENT_CHECK=$(make_request GET "/api/usuarios/clientes/$CLIENT_ID" "" "$DRIVER_TOKEN")
echo "Client check: $CLIENT_CHECK"

echo ""
echo "6. Creating order (Berlin coordinates)..."
ORDER_RESPONSE=$(make_request POST "/api/pedidos" "{
    \"origemLatitude\": \"52.516677\",
    \"origemLongitude\": \"13.388763\",
    \"destinoLatitude\": \"52.520008\",
    \"destinoLongitude\": \"13.404954\",
    \"tipoMercadoria\": \"Eletronicos\",
    \"clienteId\": $CLIENT_ID
}" "$DRIVER_TOKEN")
ORDER_ID=$(extract_id "$ORDER_RESPONSE")
echo "Order created with ID: $ORDER_ID"
echo "Response: $ORDER_RESPONSE"

echo ""
echo "7. Driver accepts the order..."
ACCEPT_RESPONSE=$(make_request POST "/api/pedidos/$ORDER_ID/aceitar?motoristaId=$DRIVER_ID&latitude=52.517000&longitude=13.389000" "" "$DRIVER_TOKEN")
echo "Order accepted: $ACCEPT_RESPONSE"

echo ""
echo "8. Simulating driver movement to pickup point..."
for i in {1..3}; do
    echo "   Movement update $i..."
    MOVE_RESPONSE=$(make_request POST "/api/rastreamento/localizacao" "{
        \"motoristaId\": $DRIVER_ID,
        \"pedidoId\": $ORDER_ID,
        \"latitude\": 52.516800,
        \"longitude\": 13.388900,
        \"statusVeiculo\": \"EM_MOVIMENTO\"
    }" "$DRIVER_TOKEN")
    echo "   Response: $MOVE_RESPONSE"
    sleep 2
done

echo ""
echo "9. Checking current order location..."
TRACK_RESPONSE=$(make_request GET "/api/rastreamento/pedido/$ORDER_ID" "" "$DRIVER_TOKEN")
echo "Tracking response: $TRACK_RESPONSE"

echo ""
echo "10. Driver confirms pickup..."
PICKUP_RESPONSE=$(make_request POST "/api/rastreamento/pedido/$ORDER_ID/coleta?motoristaId=$DRIVER_ID" "" "$DRIVER_TOKEN")
echo "Pickup confirmed: $PICKUP_RESPONSE"

echo ""
echo "11. Simulating driver movement to destination..."
for i in {1..3}; do
    echo "   Movement update $i..."
    MOVE_RESPONSE=$(make_request POST "/api/rastreamento/localizacao" "{
        \"motoristaId\": $DRIVER_ID,
        \"pedidoId\": $ORDER_ID,
        \"latitude\": 52.518000,
        \"longitude\": 13.395000,
        \"statusVeiculo\": \"EM_MOVIMENTO\"
    }" "$DRIVER_TOKEN")
    echo "   Response: $MOVE_RESPONSE"
    sleep 2
done

echo ""
echo "12. Driver confirms delivery..."
DELIVERY_RESPONSE=$(make_request POST "/api/rastreamento/pedido/$ORDER_ID/entrega?motoristaId=$DRIVER_ID" "" "$DRIVER_TOKEN")
echo "Delivery confirmed: $DELIVERY_RESPONSE"

echo ""
echo "13. Checking final order status..."
FINAL_STATUS=$(make_request GET "/api/pedidos/$ORDER_ID" "" "$DRIVER_TOKEN")
echo "Final order status: $FINAL_STATUS"

echo ""
echo "14. Checking driver statistics..."
STATS_RESPONSE=$(make_request GET "/api/rastreamento/estatisticas/motorista/$DRIVER_ID?dataInicio=2025-05-03&dataFim=2025-05-03" "" "$DRIVER_TOKEN")
echo "Driver statistics: $STATS_RESPONSE"

echo ""
echo "=== Test completed ==="
echo "Check the logs of lambda-simulator and lambda-webhook containers to see if notifications were processed:"
echo "docker logs lambda-simulator"
echo "docker logs lambda-webhook"
echo ""
echo "Also check RabbitMQ management interface at http://localhost:15672 (guest/guest)"
