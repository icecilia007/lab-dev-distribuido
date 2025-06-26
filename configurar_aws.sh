#!/bin/bash

echo "========================================="
echo "CONFIGURAÇÃO AWS PARA ENVIO DE EMAILS"
echo "========================================="
echo

# Verificar se a pasta .aws já existe
if [ -d ~/.aws ]; then
    echo "⚠️  Credenciais AWS já existem em ~/.aws"
    echo "Deseja sobrescrever? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Configuração cancelada."
        echo "Use ./verificar_aws.sh para verificar as credenciais existentes."
        exit 0
    fi
fi

echo "Por favor, insira suas credenciais AWS:"
echo

read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
echo

read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
echo
echo

read -p "AWS Region (padrão: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

echo
echo "Criando/atualizando pasta ~/.aws..."

# Criar pasta .aws se não existir
mkdir -p ~/.aws

# Criar arquivo credentials
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

# Criar arquivo config
cat > ~/.aws/config << EOF
[default]
region = $AWS_REGION
output = json
EOF

# Definir permissões seguras
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config

echo "✅ Credenciais AWS configuradas em ~/.aws/"
echo
echo "🔄 Agora reinicie o serviço de notificação:"
echo "docker-compose up -d notificacao-service"
echo
echo "🧪 Execute o teste:"
echo "./teste_email_completo.sh"
echo
echo "📋 O container usará automaticamente suas credenciais AWS da pasta ~/.aws"
echo "📧 O email será enviado para arihenriquedev@hotmail.com via SQS -> Lambda -> SES"