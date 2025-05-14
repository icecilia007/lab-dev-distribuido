# Documentação do Projeto Mobile - Sistema Logístico

Esta documentação fornece instruções detalhadas para configurar e executar o aplicativo móvel do sistema logístico, incluindo a configuração do ambiente de desenvolvimento e a integração com os microsserviços de backend.

## Pré-requisitos

**Ambiente de Desenvolvimento:**
- IntelliJ IDEA (qualquer edição)
- JDK 21
- Flutter versão 3.13.6
- Dart versão 3.3.4
- Emulador Android ou dispositivo físico

**Backend:**
- Cinco microsserviços em execução:
    - API Gateway
    - Serviço de Usuários
    - Serviço de Rastreamento
    - Serviço de Notificações
    - Serviço de Pedidos
- RabbitMQ configurado com as filas e exchanges necessárias
- Banco de dados PostgreSQL (imagem via Rancher)
Para iniciar o processo das imagens, com o Rancher instalado acesse o diretorio
```bash
cd lab-dev-distribuido/infra
```
- Abra os arquivos yml da pasta ``database`` e ``rabbitmq`` e execute-os pelo IntelliJ Idea

Para visualizar o banco de dados, rode o seguinte comando no terminal com permissões de administrador.
```bash
docker exec -it postgres-db psql -U postgres -d main_db
```

## Configuração do Ambiente de Desenvolvimento

### 1. Instalação do JDK 21

1. Baixe o JDK 21 do site oficial da Oracle ou use o OpenJDK
2. Configure a variável de ambiente JAVA_HOME:

#### No Windows
```bash
setx JAVA_HOME "C:\Program Files\Java\jdk-21"
```


### 2. Instalação do Flutter e Dart

1. Baixe Flutter 3.13.6 do site oficial: https://flutter.dev/docs/get-started/install
2. Extraia o arquivo em uma pasta de sua preferência
3. Adicione o diretório `flutter/bin` ao seu PATH
4. Execute `flutter doctor` para verificar a instalação e resolver dependências

### 3. Configuração do IntelliJ IDEA

1. Instale o plugin Flutter e Dart:
- Vá em File > Settings > Plugins
- Busque por "Flutter" e instale
- O plugin Dart será instalado automaticamente
2. Configure o SDK do Flutter:
- Vá em File > Settings > Languages & Frameworks > Flutter
- Defina o caminho para o diretório do Flutter SDK instalado
3. Configure o SDK do Dart:
- Vá em File > Settings > Languages & Frameworks > Dart
- Defina o caminho para o diretório do Dart SDK instalado dentro do pasta do Flutter ```flutter\bin\cache\dart-sdk```
4. Configure o Android SDK Manager:
- Vá em File > Settings > Languages & Frameworks > Android SDK Updater
- Na aba SDK Platfroms, deixe selecionado a caixa Android API 36.0
- Na aba SDK Tools marque ```Android SDK Build-tools 36```, ```NDK (Side by side)```, ```Android SDK Command_line tools```, ```Android Emulator```, ```Android Emulator hypervisor driver (installer)``` e ```Android SDK Platform-Tools```.
- Na aba SDK Update Sites deixe tudo marcado

## Configuração do Projeto Mobile

### 1. Acesse a seguinte pasta do projeto
```bash
cd lab-dev-distribuido/app
```

### 2. Instalação das Dependências

As dependências necessárias estão listadas no arquivo `pubspec.yaml`. Para instalá-las:
```bash
flutter pub get
```

O projeto utiliza as seguintes dependências principais:
- **http**: Para comunicação com as APIs
- **geolocator**: Para funcionalidades de geolocalização
- **flutter_map**: Para exibição de mapas interativos
- **web_socket_channel**: Para comunicação em tempo real
- **provider**: Para gerenciamento de estado
- **flutter_local_notifications**: Para notificações locais

### 3. Configuração dos Microsserviços

Todos os cinco microsserviços precisam estar em execução e configurados para se conectarem ao RabbitMQ e ao banco de dados:

#### API Gateway (porta 8080)
- Serve como ponto de entrada único para as APIs
- Redireciona requisições para os serviços apropriados

## Executando o Projeto Mobile

### 1. Iniciando o Emulador Android

Através do IntelliJ IDEA:
1. Vá em Tools > AVD Manager
2. Selecione um dispositivo virtual existente ou crie um novo
3. Inicie o emulador clicando no botão de play

Alternativamente, conecte um dispositivo físico via USB com depuração USB ativada.

### 2. Executando o Aplicativo

No IntelliJ IDEA:
1. Abra o projeto Flutter
2. Selecione o dispositivo/emulador na barra de ferramentas
3. Clique em Run > Run 'main.dart' ou pressione Shift+F10

## Solução de Problemas Comuns

1. **Erro de conexão com as APIs**:
- Verifique se o IP/hostname está correto no arquivo de configuração
- Confirme se todos os microsserviços estão em execução
- Verifique se o emulador/dispositivo tem acesso à rede onde os serviços estão hospedados

2. **Erros de compilação Flutter**:
- Execute `flutter clean` seguido de `flutter pub get`
- Verifique se a versão do Flutter é compatível (3.13.6)

3. **Problemas de compatibilidade do JDK**:
- Confirme que está usando JDK 21
- Verifique as variáveis de ambiente JAVA_HOME e PATH