# Tracksolid API Debugger

Ferramenta web para debugar a API Tracksolid, focando na obtenção de tokens (jimi.oauth.token.get) e listagem de dispositivos (jimi.user.device.list).

## Características

✅ **Interface Intuitiva** - Layout limpo e organizado em seções
✅ **Logs Detalhados** - Cada etapa é registrada com entradas e saídas raw
✅ **Geração Automática de Assinatura** - Calcula MD5 e sign automaticamente
✅ **Suporte a Duas APIs** - Token e Listagem de Dispositivos
✅ **Cópia e Download** - Exporta logs em texto
✅ **Responsive Design** - Funciona em desktop e mobile

## Requisitos

- Node.js (v14 ou superior)
- npm

## Instalação

1. **Navegar até o diretório do projeto:**
```bash
cd "c:\Users\LuisGustavo\OneDrive - Newtec Telemetria\Documentos\apitracksolid"
```

2. **Instalar dependências:**
```bash
npm install
```

## Execução

1. **Iniciar o servidor:**
```bash
npm start
```

Ou para modo desenvolvimento:
```bash
npm run dev
```

2. **Abrir no navegador:**
```
http://localhost:3000
```

## Uso

1. **Preencher os campos:**
   - **Base URL**: Endpoint da API (ex: https://hk-open.tracksolidpro.com/route/rest)
   - **App Key**: Chave da aplicação fornecida pela JIMI
   - **App Secret**: Segredo da aplicação fornecido pela JIMI
   - **User ID**: Login da conta Tracksolid
   - **Password**: Senha da conta (sem MD5 - a ferramenta converte)
   - **Expires In**: Duração da expiração do token em segundos (recomendado 7200)
   - **Target Account**: ID da conta para listar dispositivos

2. **Clicar em "EXECUTAR DEBUG"**

3. **Analisar os logs:**
   - A ferramenta exibe todo o processo em detalhes
   - Mostra strings de assinatura antes do MD5
   - Exibe respostas raw em JSON
   - Registra todos os erros e avisos

4. **Exportar logs:**
   - Copiar para área de transferência: "📋 Copiar Logs"
   - Baixar como arquivo: "⬇️ Baixar Logs"

## Fluxo de Execução

### Fase 1: Preparação e Geração de Assinatura (Token)
- Captura dos parâmetros de entrada
- Conversão de senha em MD5
- Geração de timestamp UTC
- Preparação de parâmetros
- Geração da assinatura (sign)

### Fase 2: Chamada da API para Obter Token
- Envio de requisição POST
- Exibição do corpo da requisição
- Recebimento da resposta
- Análise do código de resposta
- Extração do access_token

### Fase 3: Listagem de Dispositivos (se Fase 2 bem-sucedida)
- Repetição do processo de assinatura com novos parâmetros
- Inclusão do access_token
- Envio de requisição POST
- Recebimento da resposta
- Exibição da quantidade de dispositivos

## Estrutura do Projeto

```
apitracksolid/
├── server.js              # Servidor backend (Node.js/Express)
├── package.json           # Dependências e scripts
├── README.md              # Este arquivo
└── public/
    ├── index.html         # Interface web
    ├── styles.css         # Estilos
    └── script.js          # JavaScript do frontend
```

## Dependências

- **express**: Framework web
- **cors**: Middleware para CORS
- **md5**: Geração de hash MD5
- **axios**: Cliente HTTP

## Detalhes Técnicos

### Geração de Assinatura (Sign)

A ferramenta segue rigorosamente o algoritmo de assinatura da API Tracksolid:

1. Ordena todos os parâmetros alfabeticamente (exceto 'sign')
2. Concatena os valores (sem chaves e sem separadores)
3. Circunda a string com appSecret: `appSecret + valores + appSecret`
4. Gera MD5 em MAIÚSCULAS
5. Adiciona o sign aos parâmetros finais

### Formato de Logs

Os logs incluem:
- ✅ Sucesso em operações
- ❌ Erros e falhas
- ⚠️ Avisos
- 📤 Dados enviados
- 📥 Dados recebidos
- ✓ Passos concluídos

## Troubleshooting

### Erro "Cannot find module"
```bash
npm install
```

### Porta 3000 já em uso
Edite o arquivo `server.js` e mude `const PORT = process.env.PORT || 3000;` para outra porta.

### CORS Error
A ferramenta já inclui suporte a CORS. Se persistir, verifique se o backend está rodando.

### Resposta "code != 0"
Verifique:
- Base URL está correta
- Credenciais (App Key, App Secret) estão corretas
- User ID e Password estão válidos
- Rede está conectada

## Licença

Desenvolvido para fins de diagnóstico da API Tracksolid.

## Suporte

Para dúvidas ou problemas, verifique:
1. Os logs detalhados gerados pela ferramenta
2. A documentação da API Tracksolid
3. As credenciais fornecidas pela JIMI
