#!/bin/bash

# Script rápido para verificar status de emails no SES
# Uso: ./check_emails_status.sh

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== STATUS DOS EMAILS NO SES ===${NC}"
echo

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI não configurado${NC}"
    exit 1
fi

# Lista de emails para verificar
EMAILS=(
    "arihenriquedev@hotmail.com"
    "1457902@sga.pucminas.br"
    "icsbarbosa@sga.pucminas.br"
    "g2002souzajardim@gmail.com"
)

# Se existe CSV, extrair emails dele
if [ -f "emails_teste.csv" ]; then
    echo -e "${BLUE}📄 Verificando emails do CSV...${NC}"
    while IFS=',' read -r email _; do
        if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            EMAILS+=("$email")
        fi
    done < <(tail -n +2 "emails_teste.csv")
fi

# Remover duplicatas
EMAILS=($(printf '%s\n' "${EMAILS[@]}" | sort -u))

echo -e "${BLUE}Verificando ${#EMAILS[@]} emails únicos...${NC}"
echo

verified_count=0
pending_count=0
failed_count=0

for email in "${EMAILS[@]}"; do
    status=$(aws ses get-identity-verification-attributes \
        --identities "$email" \
        --query "VerificationAttributes.\"$email\".VerificationStatus" \
        --output text 2>/dev/null)
    
    case "$status" in
        "Success")
            echo -e "${GREEN}✅ $email${NC} - Verificado"
            ((verified_count++))
            ;;
        "Pending")
            echo -e "${YELLOW}⏳ $email${NC} - Pendente (verificar email)"
            ((pending_count++))
            ;;
        "None"|"")
            echo -e "${RED}❌ $email${NC} - Não verificado"
            ((failed_count++))
            ;;
        *)
            echo -e "${RED}⚠️  $email${NC} - Status: $status"
            ((failed_count++))
            ;;
    esac
done

echo
echo -e "${BLUE}=== RESUMO ===${NC}"
echo -e "${GREEN}✅ Verificados: $verified_count${NC}"
echo -e "${YELLOW}⏳ Pendentes: $pending_count${NC}"
echo -e "${RED}❌ Não verificados: $failed_count${NC}"

echo
if [ $pending_count -gt 0 ]; then
    echo -e "${YELLOW}💡 Para emails pendentes: verifique a caixa de entrada e clique no link de verificação${NC}"
fi

if [ $failed_count -gt 0 ]; then
    echo -e "${BLUE}🔧 Para verificar emails: ./setup_emails.sh emails_teste.csv --verify-only${NC}"
fi

echo
echo -e "${BLUE}📊 Quota SES:${NC}"
aws ses get-send-quota --output table

echo
echo -e "${BLUE}📈 Estatísticas recentes:${NC}"
aws ses get-send-statistics --query 'SendDataPoints[-3:]' --output table