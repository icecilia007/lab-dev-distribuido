#!/bin/bash

echo "=== Teste de Integração: Pedido Finalizado → EmailService → SQS ==="

# Configurações
API_GATEWAY="http://localhost:8000"
CLIENTE_ID="1"
MOTORISTA_ID="1"

echo ""
echo "1. Criando cliente de teste..."
curl -X POST "$API_GATEWAY/api/usuarios/clientes" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Cliente Teste",
    "email": "cliente.teste@example.com",
    "telefone": "11999999999",
    "documento": "12345678901"
  }'

echo ""
echo ""
echo "2. Criando motorista de teste..."
curl -X POST "$API_GATEWAY/api/usuarios/motoristas" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Motorista Teste",
    "email": "motorista.teste@example.com",
    "telefone": "11888888888",
    "documento": "98765432100",
    "cnh": "12345678900",
    "veiculo": "Honda Civic",
    "placa": "ABC1234"
  }'

echo ""
echo ""
echo "3. Criando pedido..."
PEDIDO_RESPONSE=$(curl -s -X POST "$API_GATEWAY/api/pedidos" \
  -H "Content-Type: application/json" \
  -d '{
    "clienteId": 1,
    "origemLatitude": "-19.9167",
    "origemLongitude": "-43.9345",
    "destinoLatitude": "-19.9208",
    "destinoLongitude": "-43.9378",
    "tipoMercadoria": "Documentos"
  }')

echo "Resposta do pedido:"
echo "$PEDIDO_RESPONSE" | python3 -m json.tool

# Extrair ID do pedido
PEDIDO_ID=$(echo "$PEDIDO_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "1")

echo ""
echo "ID do pedido criado: $PEDIDO_ID"

echo ""
echo "4. Simulando aceite do pedido pelo motorista..."
curl -X PUT "$API_GATEWAY/api/pedidos/$PEDIDO_ID/aceitar" \
  -H "Content-Type: application/json" \
  -d '{
    "motoristaId": 1,
    "motoristaLatitude": -19.9167,
    "motoristaLongitude": -43.9345
  }'

echo ""
echo ""
echo "5. Aguardando processamento..."
sleep 3

echo ""
echo "6. Atualizando status para EM_ROTA..."
curl -X PUT "$API_GATEWAY/api/pedidos/$PEDIDO_ID/status" \
  -H "Content-Type: application/json" \
  -d '{
    "novoStatus": "EM_ROTA"
  }'

echo ""
echo ""
echo "7. Aguardando processamento..."
sleep 3

echo ""
echo "8. *** FINALIZANDO PEDIDO (ENTREGUE) - Deve disparar EmailService ***"
curl -X PUT "$API_GATEWAY/api/pedidos/$PEDIDO_ID/status" \
  -H "Content-Type: application/json" \
  -d '{
    "novoStatus": "ENTREGUE"
  }'

echo ""
echo ""
echo "9. Verificando logs do serviço de notificação..."
echo "Aguarde 5 segundos para o processamento..."
sleep 5

echo ""
echo "Verificando logs do contêiner notificacao-service:"
docker logs notificacao-service --tail 20

echo ""
echo "=== Teste Concluído ==="
echo "Verifique os logs acima para confirmar se o email foi enviado para a fila SQS"
echo "Procure por mensagens como:"
echo "- 'Email de entrega enviado para cliente ID: 1'"
echo "- 'Mensagem enviada para fila SQS para email: cliente.teste@example.com'"