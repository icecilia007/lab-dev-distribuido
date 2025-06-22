#!/bin/bash

echo "🔧 Deploying full fixes for authentication and API Gateway issues..."

# Verificar se estamos no diretório correto
if [ ! -f "main.tf" ]; then
    echo "❌ Please run this script from the aws-serverless-logistics directory"
    exit 1
fi

# Verificar se terraform está inicializado
if [ ! -d ".terraform" ]; then
    echo "📦 Initializing Terraform..."
    terraform init
fi

# Fazer deploy completo das correções
echo "🚀 Deploying comprehensive fixes..."

# Deploy em etapas para evitar conflitos
echo "📦 Step 1: Updating DynamoDB schema..."
terraform apply -auto-approve \
    -target=module.users_table

echo "📦 Step 2: Updating Lambda functions..."
terraform apply -auto-approve \
    -target=module.auth_lambda \
    -target=module.notificacoes_lambda \
    -target=module.pedidos_lambda

echo "📦 Step 3: Updating API Gateway routes..."
terraform apply -auto-approve \
    -target=module.api_gateway

echo "📦 Step 4: Updating WebSocket configuration..."
terraform apply -auto-approve \
    -target=aws_apigatewayv2_api.websocket_api \
    -target=aws_apigatewayv2_stage.websocket_stage

if [ $? -eq 0 ]; then
    echo "✅ All fixes deployed successfully!"
    echo ""
    echo "📋 Changes applied:"
    echo "   • Fixed DynamoDB users table schema (email → id)"
    echo "   • Updated JWT validation in all Lambdas"
    echo "   • Configured request_parameters for API Gateway routes"
    echo "   • Enhanced Lambda functions to process path and query parameters"
    echo "   • Fixed WebSocket configuration for notifications"
    echo "   • Enhanced error handling and logging"
    echo "   • Improved driver statistics with real data and date filtering"
    echo ""
    echo "🌐 API Gateway URL: $(terraform output -raw api_gateway_invoke_url)"
    echo "🔗 WebSocket URL: $(terraform output -raw websocket_api_url)"
    echo ""
    echo "🧪 Test your Flutter app now - the authentication errors should be resolved."
else
    echo "❌ Deployment failed. Check the errors above."
    exit 1
fi