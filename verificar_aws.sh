#!/bin/bash

echo "========================================="
echo "VERIFICAÇÃO DE CREDENCIAIS AWS"
echo "========================================="
echo

# Verificar se a pasta .aws existe
if [ ! -d ~/.aws ]; then
    echo "❌ Pasta ~/.aws não encontrada!"
    echo
    echo "📝 Para configurar suas credenciais AWS:"
    echo "1. Execute: aws configure"
    echo "2. Ou crie manualmente:"
    echo "   mkdir -p ~/.aws"
    echo "   echo '[default]' > ~/.aws/credentials"
    echo "   echo 'aws_access_key_id = SEU_ACCESS_KEY' >> ~/.aws/credentials"
    echo "   echo 'aws_secret_access_key = SEU_SECRET_KEY' >> ~/.aws/credentials"
    echo
    exit 1
fi

echo "✅ Pasta ~/.aws encontrada"

# Verificar arquivo credentials
if [ ! -f ~/.aws/credentials ]; then
    echo "❌ Arquivo ~/.aws/credentials não encontrado!"
    echo
    echo "📝 Crie o arquivo de credenciais:"
    echo "   echo '[default]' > ~/.aws/credentials"
    echo "   echo 'aws_access_key_id = SEU_ACCESS_KEY' >> ~/.aws/credentials"
    echo "   echo 'aws_secret_access_key = SEU_SECRET_KEY' >> ~/.aws/credentials"
    echo
    exit 1
fi

echo "✅ Arquivo ~/.aws/credentials encontrado"

# Verificar se as credenciais têm conteúdo
if ! grep -q "aws_access_key_id" ~/.aws/credentials; then
    echo "❌ Credenciais AWS não configuradas corretamente!"
    echo
    echo "📝 Configure suas credenciais em ~/.aws/credentials:"
    echo "   [default]"
    echo "   aws_access_key_id = SEU_ACCESS_KEY"
    echo "   aws_secret_access_key = SEU_SECRET_KEY"
    echo
    exit 1
fi

echo "✅ Credenciais AWS configuradas"

# Verificar arquivo config (opcional)
if [ -f ~/.aws/config ]; then
    echo "✅ Arquivo ~/.aws/config encontrado"
    if grep -q "region" ~/.aws/config; then
        REGION=$(grep "region" ~/.aws/config | head -1 | cut -d'=' -f2 | xargs)
        echo "✅ Região configurada: $REGION"
    fi
else
    echo "⚠️  Arquivo ~/.aws/config não encontrado (opcional)"
    echo "   Para configurar região padrão:"
    echo "   echo '[default]' > ~/.aws/config"
    echo "   echo 'region = us-east-1' >> ~/.aws/config"
fi

echo
echo "🔄 Agora reinicie o serviço de notificação:"
echo "docker-compose up -d notificacao-service"
echo
echo "🧪 Execute o teste:"
echo "./teste_email_completo.sh"
echo
echo "📋 O container usará automaticamente suas credenciais AWS da pasta ~/.aws"
echo "📧 O email será enviado para arihenriquedev@hotmail.com via SQS -> Lambda -> SES"