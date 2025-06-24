# 🚀 Setup Rápido - Postman Collection

## Passos Simples para Testar a API

### 1️⃣ Importe a Collection
- Importe o arquivo: `postman-collection-simple.json`

### 2️⃣ Faça Login e Copie o Token
1. Execute o request **"1️⃣ Login (sem auth)"**
2. Na resposta, vá para a aba **Headers**
3. Copie o valor do header **"Authorization"** (vai ser algo como: `Bearer eyJhbGciOiJIUzI1NiIs...`)
4. Copie **APENAS A PARTE DO TOKEN** (sem o "Bearer ", só: `eyJhbGciOiJIUzI1NiIs...`)

### 3️⃣ Configure o Token na Collection
1. Clique na collection "AWS Logistics API - Simple"
2. Vá para a aba **Variables**
3. Na variável **"authToken"**, cole o token que você copiou
4. Clique **Save**

### 4️⃣ Teste os Endpoints
Agora execute qualquer um dos outros requests:
- **2️⃣ Consultar Pedido por ID** - Deve funcionar ✅
- **3️⃣ Criar Pedido** - Deve funcionar ✅
- **4️⃣ Listar Pedidos por Usuário** - Deve funcionar ✅
- **5️⃣ Teste sem Token** - Deve dar erro "Missing Authentication Token" ❌ (isso é esperado)

## 🔧 Troubleshooting

### Se der "Missing Authentication Token":
- ✅ **Request "5️⃣ Teste sem Token"**: Normal, é esperado
- ❌ **Outros requests**: Verifique se copiou o token corretamente

### Como copiar o token corretamente:
```
❌ ERRADO: Bearer eyJhbGciOiJIUzI1NiIs...
✅ CORRETO: eyJhbGciOiJIUzI1NiIs...
```

### Se der "Token inválido ou expirado":
- Execute o login novamente
- Copie o novo token
- Cole na variável da collection

## 📝 Exemplo de Resposta do Login

**Headers da resposta:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo4NTE2NDQwODkyLCJlbWFpbCI6ImFyaUBnbWFpbC5jb20iLCJ0aXBvIjoiY2xpZW50ZSIsImV4cCI6MTc1MDY4Njk3OH0.7yLah2IFOFO_W0zyiVqeIjy4TFacOE6Qrs_6zxAgPC8
```

**Cole na variável apenas:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo4NTE2NDQwODkyLCJlbWFpbCI6ImFyaUBnbWFpbC5jb20iLCJ0aXBvIjoiY2xpZW50ZSIsImV4cCI6MTc1MDY4Njk3OH0.7yLah2IFOFO_W0zyiVqeIjy4TFacOE6Qrs_6zxAgPC8
```

## 🎯 Status Esperados

| Request | Status | Resposta |
|---------|--------|----------|
| Login | 200 | Dados do usuário + token no header |
| Consultar Pedido | 200 | Dados do pedido |
| Criar Pedido | 201 | Novo pedido criado |
| Listar Pedidos | 200 | Lista de pedidos |
| Teste sem Token | 401 | "Missing Authentication Token" |

✅ **Se todos os requests com token funcionarem, sua API está 100% operacional!**