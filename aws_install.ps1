# Script para instalar AWS CLI no Windows
# Execute como Administrador para melhor compatibilidade

param(
    [switch]$ForceReinstall,
    [switch]$SkipPathCheck
)

Write-Host "=== Script de Instalação do AWS CLI ===" -ForegroundColor Cyan
Write-Host "Iniciando instalação..." -ForegroundColor Green

# Função para verificar se o comando existe
function Test-CommandExists {
    param($Command)
    try {
        Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Verificar se AWS CLI já está instalado
if (Test-CommandExists "aws" -and -not $ForceReinstall) {
    Write-Host "AWS CLI já está instalado!" -ForegroundColor Yellow
    aws --version
    $choice = Read-Host "Deseja reinstalar? (s/N)"
    if ($choice -notmatch "^[sS]") {
        Write-Host "Instalação cancelada." -ForegroundColor Yellow
        exit 0
    }
}

# Detectar arquitetura do sistema
$architecture = if ([Environment]::Is64BitOperatingSystem) { "x86_64" } else { "x86" }
Write-Host "Arquitetura detectada: $architecture" -ForegroundColor Green

# URLs de download
$downloadUrl = if ($architecture -eq "x86_64") {
    "https://awscli.amazonaws.com/AWSCLIV2.msi"
} else {
    "https://awscli.amazonaws.com/AWSCLIV2-x86.msi"
}

# Caminho temporário para download
$tempPath = "$env:TEMP\AWSCLIV2.msi"

Write-Host "Baixando AWS CLI..." -ForegroundColor Green
Write-Host "URL: $downloadUrl" -ForegroundColor Gray

try {
    # Download do instalador
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
    Write-Host "Download concluído!" -ForegroundColor Green
}
catch {
    Write-Host "Erro no download: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Verificar se o arquivo foi baixado
if (-not (Test-Path $tempPath)) {
    Write-Host "Erro: Arquivo não foi baixado corretamente" -ForegroundColor Red
    exit 1
}

Write-Host "Instalando AWS CLI..." -ForegroundColor Green

try {
    # Instalar silenciosamente
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$tempPath`" /quiet /norestart" -Wait -NoNewWindow
    Write-Host "Instalação concluída!" -ForegroundColor Green
}
catch {
    Write-Host "Erro na instalação: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Limpar arquivo temporário
Remove-Item $tempPath -ErrorAction SilentlyContinue

# Atualizar PATH da sessão atual
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Aguardar um momento para o sistema atualizar
Start-Sleep -Seconds 2

Write-Host "Verificando instalação..." -ForegroundColor Green

# Verificar se a instalação foi bem-sucedida
if (Test-CommandExists "aws") {
    Write-Host "✅ AWS CLI instalado com sucesso!" -ForegroundColor Green
    Write-Host "Versão instalada:" -ForegroundColor Cyan
    aws --version

    Write-Host "`n=== Próximos Passos ===" -ForegroundColor Cyan
    Write-Host "1. Configure suas credenciais AWS:" -ForegroundColor White
    Write-Host "   aws configure" -ForegroundColor Gray
    Write-Host "`n2. Ou configure um perfil específico:" -ForegroundColor White
    Write-Host "   aws configure --profile meu-perfil" -ForegroundColor Gray
    Write-Host "`n3. Teste a conexão:" -ForegroundColor White
    Write-Host "   aws sts get-caller-identity" -ForegroundColor Gray

} else {
    Write-Host "❌ Falha na instalação ou AWS CLI não encontrado no PATH" -ForegroundColor Red
    Write-Host "Tente:" -ForegroundColor Yellow
    Write-Host "1. Reiniciar o PowerShell" -ForegroundColor Gray
    Write-Host "2. Verificar se C:\Program Files\Amazon\AWSCLIV2\ está no PATH" -ForegroundColor Gray
    Write-Host "3. Executar o script como Administrador" -ForegroundColor Gray
}

# Função adicional para configuração básica (opcional)
function Start-AWSConfiguration {
    Write-Host "`n=== Configuração Rápida do AWS CLI ===" -ForegroundColor Cyan
    $configure = Read-Host "Deseja configurar agora? (s/N)"

    if ($configure -match "^[sS]") {
        Write-Host "Executando 'aws configure'..." -ForegroundColor Green
        aws configure
    }
}

# Perguntar se deseja configurar
if (Test-CommandExists "aws") {
    Start-AWSConfiguration
}

Write-Host "`nScript concluído!" -ForegroundColor Green