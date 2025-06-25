#!/bin/bash

# Script para automatizar verificação de emails no SES e configuração do Terraform
# Uso: ./setup_emails.sh [arquivo_csv] [--verify-only] [--terraform-update]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
DEFAULT_CSV_FILE="emails_teste.csv"
LAMBDA_FILE="../lambda/email_processor/lambda_function.py"
VERIFIED_EMAILS_FILE="verified_emails.json"

# Funções de utilitário
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar dependências
check_dependencies() {
    log_info "Verificando dependências..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI não encontrado. Instale com: pip install awscli"
        exit 1
    fi
    
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform não encontrado. Instale: https://terraform.io/downloads"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq não encontrado. Algumas funcionalidades podem ser limitadas"
        log_info "Para instalar: sudo apt-get install jq"
    fi
    
    # Verificar credenciais AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Credenciais AWS não configuradas. Execute: aws configure"
        exit 1
    fi
    
    log_success "Todas as dependências estão instaladas"
}

# Criar CSV template se não existir
create_csv_template() {
    local csv_file="$1"
    
    if [ ! -f "$csv_file" ]; then
        log_info "Criando template CSV: $csv_file"
        cat > "$csv_file" << 'EOF'
email,nome,regiao,tipo_cliente
arihenriquedev@hotmail.com,Ari Henrique,sudeste,premium
1457902@sga.pucminas.br,Estudante PUC,sudeste,premium
icsbarbosa@sga.pucminas.br,Vagabundando na PUC,norte,pobre
g2002souzajardim@gmail.com,Estudante PUC,nordeste,premium
EOF
        log_success "Template CSV criado: $csv_file"
        log_warning "EDITE o arquivo $csv_file com os emails reais antes de continuar"
        echo
        echo "Formato do CSV:"
        echo "email,nome,regiao,tipo_cliente"
        echo "exemplo@email.com,Nome Completo,sudeste,premium"
        echo
        exit 0
    fi
}

# Validar formato do CSV
validate_csv() {
    local csv_file="$1"
    
    log_info "Validando formato do CSV: $csv_file"
    
    if [ ! -f "$csv_file" ]; then
        log_error "Arquivo CSV não encontrado: $csv_file"
        exit 1
    fi
    
    # Verificar cabeçalho
    local header=$(head -n1 "$csv_file")
    local expected_header="email,nome,regiao,tipo_cliente"
    
    if [ "$header" != "$expected_header" ]; then
        log_error "Cabeçalho CSV inválido. Esperado: $expected_header"
        log_error "Encontrado: $header"
        exit 1
    fi
    
    # Contar linhas (excluindo cabeçalho)
    local email_count=$(($(wc -l < "$csv_file") - 1))
    log_success "CSV válido com $email_count emails"
}

# Extrair emails únicos do CSV
extract_emails() {
    local csv_file="$1"
    
    # Pular cabeçalho e extrair coluna de email, removendo duplicatas
    tail -n +2 "$csv_file" | cut -d',' -f1 | sort -u | while read -r email; do
        # Validar formato básico de email
        if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
            echo "$email"
        fi
    done
}

# Verificar email no SES
verify_email_ses() {
    local email="$1"
    
    log_info "Verificando email no SES: $email"
    
    # Adicionar email para verificação
    if aws ses verify-email-identity --email-address "$email" 2>/dev/null; then
        log_success "Solicitação de verificação enviada para: $email"
        return 0
    else
        log_error "Falha ao solicitar verificação para: $email"
        return 1
    fi
}

# Verificar status de verificação
check_verification_status() {
    local email="$1"
    
    local status=$(aws ses get-identity-verification-attributes \
        --identities "$email" \
        --query "VerificationAttributes.\"$email\".VerificationStatus" \
        --output text 2>/dev/null)
    
    if [ "$status" = "Success" ]; then
        echo "verified"
    elif [ "$status" = "Pending" ]; then
        echo "pending"
    else
        echo "not_verified"
    fi
}

# Processar todos os emails do CSV
process_emails() {
    local csv_file="$1"
    local verify_only="$2"
    
    log_info "Processando emails do arquivo: $csv_file"
    
    local emails=($(extract_emails "$csv_file"))
    local verified_emails=()
    local pending_emails=()
    local failed_emails=()
    
    echo
    log_info "Encontrados ${#emails[@]} emails únicos para processar"
    echo
    
    for email in "${emails[@]}"; do
        local current_status=$(check_verification_status "$email")
        
        case "$current_status" in
            "verified")
                log_success "✓ $email (já verificado)"
                verified_emails+=("$email")
                ;;
            "pending")
                log_warning "⏳ $email (verificação pendente)"
                pending_emails+=("$email")
                ;;
            "not_verified")
                if [ "$verify_only" = "true" ]; then
                    log_info "📧 Enviando verificação para: $email"
                    if verify_email_ses "$email"; then
                        pending_emails+=("$email")
                    else
                        failed_emails+=("$email")
                    fi
                else
                    log_warning "❌ $email (não verificado)"
                    failed_emails+=("$email")
                fi
                ;;
        esac
    done
    
    # Salvar lista de emails verificados (formato simples sem jq)
    {
        echo "VERIFIED_EMAILS:"
        for email in "${verified_emails[@]}"; do
            echo "$email"
        done
        echo ""
        echo "PENDING_EMAILS:"
        for email in "${pending_emails[@]}"; do
            echo "$email"
        done
        echo ""
        echo "FAILED_EMAILS:"
        for email in "${failed_emails[@]}"; do
            echo "$email"
        done
        echo ""
        echo "LAST_UPDATE: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } > "$VERIFIED_EMAILS_FILE"
    
    echo
    log_info "=== RESUMO ==="
    log_success "Emails verificados: ${#verified_emails[@]}"
    log_warning "Emails pendentes: ${#pending_emails[@]}"
    log_error "Emails com falha: ${#failed_emails[@]}"
    echo
    
    if [ ${#pending_emails[@]} -gt 0 ]; then
        log_warning "IMPORTANTE: Os seguintes emails precisam confirmar a verificação:"
        for email in "${pending_emails[@]}"; do
            echo "  - $email"
        done
        echo
        log_info "Aguarde a confirmação e execute novamente: $0 $csv_file --check-status"
    fi
    
    if [ ${#verified_emails[@]} -gt 0 ]; then
        log_success "Emails prontos para uso: ${#verified_emails[@]}"
        return 0
    else
        log_warning "Nenhum email verificado ainda"
        return 1
    fi
}

# Atualizar Lambda com lista de emails verificados
update_lambda_code() {
    log_info "Atualizando código da Lambda com emails verificados..."
    
    if [ ! -f "$VERIFIED_EMAILS_FILE" ]; then
        log_error "Arquivo de emails verificados não encontrado: $VERIFIED_EMAILS_FILE"
        return 1
    fi
    
    if [ ! -f "$LAMBDA_FILE" ]; then
        log_error "Arquivo da Lambda não encontrado: $LAMBDA_FILE"
        return 1
    fi
    
    # Extrair emails verificados (sem jq)
    local verified_emails=()
    local reading_verified=false
    
    while IFS= read -r line; do
        if [[ "$line" == "VERIFIED_EMAILS:" ]]; then
            reading_verified=true
            continue
        elif [[ "$line" == "PENDING_EMAILS:" ]] || [[ "$line" == "FAILED_EMAILS:" ]] || [[ "$line" == "LAST_UPDATE:"* ]]; then
            reading_verified=false
            continue
        elif [[ "$reading_verified" == true ]] && [[ -n "$line" ]] && [[ "$line" != "" ]]; then
            verified_emails+=("$line")
        fi
    done < "$VERIFIED_EMAILS_FILE"
    
    if [ ${#verified_emails[@]} -eq 0 ]; then
        log_warning "Nenhum email verificado encontrado"
        return 1
    fi
    
    # Criar backup
    cp "$LAMBDA_FILE" "${LAMBDA_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Construir lista Python
    local python_list="["
    for i in "${!verified_emails[@]}"; do
        python_list+="'${verified_emails[$i]}'"
        if [ $i -lt $((${#verified_emails[@]} - 1)) ]; then
            python_list+=","
        fi
    done
    python_list+="]"
    
    # Atualizar arquivo Python
    sed -i "/emails_autorizados = \[/,/\]/c\\
        emails_autorizados = [\\
$(for email in "${verified_emails[@]}"; do echo "            '$email',"; done | sed '$ s/,$//')\\
        ]" "$LAMBDA_FILE"
    
    log_success "Lambda atualizada com ${#verified_emails[@]} emails verificados"
    
    # Mostrar emails atualizados
    log_info "Emails configurados na Lambda:"
    for email in "${verified_emails[@]}"; do
        echo "  - $email"
    done
}

# Executar Terraform
run_terraform() {
    log_info "Executando Terraform apply..."
    
    if terraform plan -detailed-exitcode >/dev/null 2>&1; then
        local plan_exit_code=$?
        if [ $plan_exit_code -eq 0 ]; then
            log_info "Nenhuma mudança detectada no Terraform"
            return 0
        elif [ $plan_exit_code -eq 2 ]; then
            log_info "Mudanças detectadas, aplicando..."
            if terraform apply -auto-approve; then
                log_success "Terraform aplicado com sucesso"
                return 0
            else
                log_error "Falha ao aplicar Terraform"
                return 1
            fi
        fi
    else
        log_error "Erro ao executar terraform plan"
        return 1
    fi
}

# Enviar campanha de teste para todos os emails verificados
send_test_campaign() {
    local csv_file="$1"
    
    log_info "Enviando campanha de teste para emails verificados..."
    
    if [ ! -f "$VERIFIED_EMAILS_FILE" ]; then
        log_error "Arquivo de emails verificados não encontrado"
        return 1
    fi
    
    # Obter URL da API do Terraform
    local api_url=$(terraform output -raw campanhas_api_endpoint 2>/dev/null | sed 's/POST //')
    
    if [ -z "$api_url" ]; then
        log_error "Não foi possível obter URL da API do Terraform"
        return 1
    fi
    
    # Construir payload para cada tipo de cliente
    local tipos=("premium" "regiao_sul" "geral")
    
    for tipo in "${tipos[@]}"; do
        local clientes=()
        
        # Extrair clientes do CSV por tipo
        while IFS=',' read -r email nome regiao tipo_cliente; do
            if [ "$tipo_cliente" = "$tipo" ]; then
                clientes+=("{\"id\":\"$(echo -n "$email" | md5sum | cut -d' ' -f1 | head -c8)\",\"nome\":\"$nome\",\"email\":\"$email\",\"regiao\":\"$regiao\"}")
            fi
        done < <(tail -n +2 "$csv_file")
        
        if [ ${#clientes[@]} -gt 0 ]; then
            local clientes_json=$(IFS=','; echo "[${clientes[*]}]")
            
            local payload=$(cat <<EOF
{
  "nome": "Campanha de Teste - Verificação de Emails",
  "assunto": "🔔 Confirmação de Recebimento de Notificações",
  "conteudo": "Olá! Este é um email de teste para confirmar que você está recebendo notificações do nosso sistema de logística. Se você recebeu este email, sua configuração está funcionando corretamente. Para parar de receber notificações, entre em contato conosco.",
  "grupos": [
    {
      "tipo": "$tipo",
      "clientes": $clientes_json
    }
  ]
}
EOF
)
            
            log_info "Enviando campanha para grupo '$tipo' (${#clientes[@]} emails)..."
            
            local response=$(curl -s -X POST "$api_url" \
                -H "Content-Type: application/json" \
                -d "$payload")
            
            if echo "$response" | grep -q '"campanha_id"'; then
                log_success "Campanha '$tipo' enviada com sucesso (${#clientes[@]} emails)"
                echo "Resposta: $response"
            else
                log_error "Falha ao enviar campanha para grupo '$tipo'"
                echo "Resposta: $response"
            fi
        else
            log_info "Nenhum cliente encontrado para o tipo '$tipo'"
        fi
    done
}

# Exibir ajuda
show_help() {
    echo "Script de configuração de emails para SES e Terraform"
    echo
    echo "Uso: $0 [arquivo_csv] [opções]"
    echo
    echo "Opções:"
    echo "  --verify-only       Apenas solicita verificação dos emails (não atualiza Terraform)"
    echo "  --check-status      Verifica status atual dos emails"
    echo "  --terraform-update  Atualiza Lambda e executa Terraform"
    echo "  --send-test         Envia campanha de teste para emails verificados"
    echo "  --create-template   Cria template CSV de exemplo"
    echo "  --help              Exibe esta ajuda"
    echo
    echo "Exemplos:"
    echo "  $0 --create-template                    # Cria template CSV"
    echo "  $0 emails.csv --verify-only            # Solicita verificação"
    echo "  $0 emails.csv --check-status           # Verifica status"
    echo "  $0 emails.csv --terraform-update       # Atualiza tudo"
    echo "  $0 emails.csv --send-test              # Envia teste"
    echo
}

# Função principal
main() {
    local csv_file="$DEFAULT_CSV_FILE"
    local verify_only=false
    local check_status=false
    local terraform_update=false
    local send_test=false
    local create_template=false
    
    # Parse argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verify-only)
                verify_only=true
                shift
                ;;
            --check-status)
                check_status=true
                shift
                ;;
            --terraform-update)
                terraform_update=true
                shift
                ;;
            --send-test)
                send_test=true
                shift
                ;;
            --create-template)
                create_template=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Opção desconhecida: $1"
                show_help
                exit 1
                ;;
            *)
                csv_file="$1"
                shift
                ;;
        esac
    done
    
    # Criar template se solicitado
    if [ "$create_template" = true ]; then
        create_csv_template "$csv_file"
        exit 0
    fi
    
    # Verificar dependências
    check_dependencies
    
    # Criar template se arquivo não existir
    create_csv_template "$csv_file"
    
    # Validar CSV
    validate_csv "$csv_file"
    
    echo
    log_info "=== CONFIGURAÇÃO DE EMAILS SES ==="
    log_info "Arquivo CSV: $csv_file"
    echo
    
    # Processar emails
    if process_emails "$csv_file" "$verify_only"; then
        if [ "$terraform_update" = true ]; then
            echo
            log_info "=== ATUALIZANDO TERRAFORM ==="
            update_lambda_code && run_terraform
        fi
        
        if [ "$send_test" = true ]; then
            echo
            log_info "=== ENVIANDO CAMPANHA DE TESTE ==="
            send_test_campaign "$csv_file"
        fi
    else
        log_warning "Processo interrompido: nenhum email verificado"
        exit 1
    fi
    
    echo
    log_success "Script concluído!"
}

# Executar função principal
main "$@"