const express = require('express');
const cors = require('cors');
const md5 = require('md5');
const axios = require('axios');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Servir arquivos estáticos
app.use(express.static('public'));

// Função para gerar MD5
function generateMD5(str) {
  return md5(str).toUpperCase();
}

// Função para gerar timestamp no formato yyyy-MM-dd HH:mm:ss
function generateTimestamp() {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, '0');
  const day = String(now.getUTCDate()).padStart(2, '0');
  const hours = String(now.getUTCHours()).padStart(2, '0');
  const minutes = String(now.getUTCMinutes()).padStart(2, '0');
  const seconds = String(now.getUTCSeconds()).padStart(2, '0');
  return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}

// Função para gerar assinatura (sign)
function generateSign(params, appSecret) {
  // Ordenar parâmetros alfabeticamente (exceto 'sign')
  const sortedKeys = Object.keys(params)
    .filter(key => key !== 'sign')
    .sort();

  // Construir string de parâmetros: CHAVE + VALOR + CHAVE + VALOR + ...
  let paramString = '';
  sortedKeys.forEach(key => {
    paramString += key + params[key];
  });

  // Aplicar a regra de assinatura: appSecret + (chave+valor+chave+valor+...) + appSecret
  const stringToSign = appSecret + paramString + appSecret;

  // Gerar MD5 em MAIÚSCULAS
  const sign = generateMD5(stringToSign);

  return { sign, stringToSign };
}

// Rota para executar o debug
app.post('/api/debug', async (req, res) => {
  const {
    baseUrl,
    appKey,
    appSecret,
    userId,
    password,
    expiresIn,
    targetAccount
  } = req.body;

  const logs = [];

  try {
    // ========== FASE 1: OBTENÇÃO DO TOKEN ==========
    logs.push('========== INICIANDO PROCESSO DE DEBUG ==========');
    logs.push('');
    logs.push('FASE 1: PREPARAÇÃO E GERAÇÃO DA ASSINATURA (OBTENÇÃO DE TOKEN)');
    logs.push('---');

    logs.push(`✓ Capturando parâmetros de entrada:`);
    logs.push(`  - Base URL: ${baseUrl}`);
    logs.push(`  - App Key: ${appKey}`);
    logs.push(`  - App Secret: ${appSecret}`);
    logs.push(`  - User ID: ${userId}`);
    logs.push(`  - Password (MD5): ${password}`);
    logs.push(`  - Expires In: ${expiresIn}`);
    logs.push(`  - Target Account: ${targetAccount}`);
    logs.push('');

    // Usar o MD5 diretamente (já vem em MD5 do frontend)
    const userPwdMd5 = password.toLowerCase();
    logs.push(`✓ Usando user_pwd_md5 (já fornecido em MD5):`);
    logs.push(`  - user_pwd_md5: ${userPwdMd5}`);
    logs.push('');

    // Gerar timestamp
    const timestamp = generateTimestamp();
    logs.push(`✓ Timestamp gerado (UTC):`);
    logs.push(`  - ${timestamp}`);
    logs.push('');

    // Preparar parâmetros para jimi.oauth.token.get
    const tokenParams = {
      method: 'jimi.oauth.token.get',
      timestamp: timestamp,
      app_key: appKey,
      sign_method: 'md5',
      v: '1.0',
      format: 'json',
      user_id: userId,
      user_pwd_md5: userPwdMd5,
      expires_in: expiresIn
    };

    logs.push(`✓ Parâmetros preparados para jimi.oauth.token.get:`);
    Object.entries(tokenParams).forEach(([key, value]) => {
      logs.push(`  - ${key}: ${value}`);
    });
    logs.push('');

    // Gerar assinatura
    const { sign: tokenSign, stringToSign: tokenStringToSign } = generateSign(
      tokenParams,
      appSecret
    );

    logs.push(`✓ Gerando assinatura (Sign):`);
    logs.push(`  - String para MD5: ${tokenStringToSign}`);
    logs.push(`  - Sign (MD5 MAIÚSCULAS): ${tokenSign}`);
    logs.push('');

    // Adicionar sign aos parâmetros
    const finalTokenParams = { ...tokenParams, sign: tokenSign };

    logs.push(`✓ Parâmetros finais para POST (com sign):`);
    Object.entries(finalTokenParams).forEach(([key, value]) => {
      logs.push(`  - ${key}: ${value}`);
    });
    logs.push('');

    // ========== FASE 2: CHAMADA DA API PARA OBTER TOKEN ==========
    logs.push('FASE 2: CHAMADA DA API PARA OBTER O TOKEN');
    logs.push('---');

    logs.push(`📤 Enviando requisição POST para: ${baseUrl}`);
    logs.push(`📤 Method: jimi.oauth.token.get`);
    logs.push(`📤 Corpo da requisição:`);
    Object.entries(finalTokenParams).forEach(([key, value]) => {
      logs.push(`   - ${key}=${value}`);
    });
    logs.push('');

    // Fazer requisição POST
    const tokenResponse = await axios.post(baseUrl, finalTokenParams, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      timeout: 30000
    });

    logs.push(`📥 Resposta recebida do servidor:`);
    logs.push(`📥 Status HTTP: ${tokenResponse.status}`);
    logs.push('');

    const tokenResponseData = tokenResponse.data;
    logs.push(`📥 Body da resposta (JSON):`);
    logs.push(JSON.stringify(tokenResponseData, null, 2));
    logs.push('');

    // Verificar resposta
    if (tokenResponseData.code === 0) {
      logs.push(`✅ SUCESSO na obtenção do Token`);
      // A API retorna "accessToken" (com A maiúsculo), não "access_token"
      const accessToken = tokenResponseData.result.accessToken || tokenResponseData.result.access_token;
      const tokenExpiresIn = tokenResponseData.result.expiresIn || tokenResponseData.result.expires_in;
      logs.push(`   - access_token: ${accessToken}`);
      logs.push(`   - expires_in: ${tokenExpiresIn}`);
      logs.push('');

      // ========== FASE 3: LISTAGEM DE DISPOSITIVOS ==========
      logs.push('FASE 3: PREPARAÇÃO E CHAMADA DA API PARA LISTAR DISPOSITIVOS');
      logs.push('---');

      logs.push(`✓ Preparando requisição para jimi.user.device.list`);
      logs.push('');

      // Gerar novo timestamp para esta chamada
      const deviceTimestamp = generateTimestamp();
      logs.push(`✓ Novo timestamp gerado (UTC):`);
      logs.push(`  - ${deviceTimestamp}`);
      logs.push('');

      // Preparar parâmetros para jimi.user.device.list
      const deviceParams = {
        method: 'jimi.user.device.list',
        timestamp: deviceTimestamp,
        app_key: appKey,
        sign_method: 'md5',
        v: '1.0',
        format: 'json',
        access_token: accessToken,
        target: targetAccount
      };

      logs.push(`✓ Parâmetros preparados para jimi.user.device.list:`);
      Object.entries(deviceParams).forEach(([key, value]) => {
        logs.push(`  - ${key}: ${value}`);
      });
      logs.push('');

      // Gerar nova assinatura
      const { sign: deviceSign, stringToSign: deviceStringToSign } = generateSign(
        deviceParams,
        appSecret
      );

      logs.push(`✓ Gerando nova assinatura (Sign):`);
      logs.push(`  - String para MD5: ${deviceStringToSign}`);
      logs.push(`  - Sign (MD5 MAIÚSCULAS): ${deviceSign}`);
      logs.push('');

      // Adicionar sign aos parâmetros
      const finalDeviceParams = { ...deviceParams, sign: deviceSign };

      logs.push(`✓ Parâmetros finais para POST (com sign):`);
      Object.entries(finalDeviceParams).forEach(([key, value]) => {
        logs.push(`  - ${key}: ${value}`);
      });
      logs.push('');

      logs.push(`📤 Enviando requisição POST para: ${baseUrl}`);
      logs.push(`📤 Method: jimi.user.device.list`);
      logs.push(`📤 Corpo da requisição:`);
      Object.entries(finalDeviceParams).forEach(([key, value]) => {
        logs.push(`   - ${key}=${value}`);
      });
      logs.push('');

      // Fazer requisição POST para listar dispositivos
      const deviceResponse = await axios.post(baseUrl, finalDeviceParams, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        timeout: 30000
      });

      logs.push(`📥 Resposta recebida do servidor:`);
      logs.push(`📥 Status HTTP: ${deviceResponse.status}`);
      logs.push('');

      const deviceResponseData = deviceResponse.data;
      logs.push(`📥 Body da resposta (JSON):`);
      logs.push(JSON.stringify(deviceResponseData, null, 2));
      logs.push('');

      // Verificar resposta de dispositivos
      if (deviceResponseData.code === 0) {
        logs.push(`✅ SUCESSO na listagem de dispositivos`);
        const deviceCount = deviceResponseData.result.length;
        logs.push(`   - Quantidade de dispositivos: ${deviceCount}`);
        if (deviceCount > 0) {
          logs.push(`   - Primeiros dispositivos:`);
          deviceResponseData.result.slice(0, 5).forEach((device, index) => {
            logs.push(`     [${index + 1}] ${JSON.stringify(device).substring(0, 100)}...`);
          });
        }
        logs.push('');
      } else {
        logs.push(
          `❌ FALHA na listagem de dispositivos - Code: ${deviceResponseData.code}`
        );
        logs.push(`   - Message: ${deviceResponseData.message}`);
        logs.push('');
      }
    } else {
      logs.push(
        `❌ FALHA na obtenção do Token - Code: ${tokenResponseData.code}`
      );
      logs.push(`   - Message: ${tokenResponseData.message}`);
      logs.push('');
      logs.push('⚠️ Processo interrompido. Não foi possível obter o token.');
      logs.push('');
    }

    logs.push('========== FIM DO PROCESSO DE DEBUG ==========');

    res.json({ success: true, logs });
  } catch (error) {
    logs.push('');
    logs.push('❌ ERRO DURANTE O PROCESSO');
    logs.push('---');
    logs.push(`Erro: ${error.message}`);
    if (error.response) {
      logs.push(`Status: ${error.response.status}`);
      logs.push(`Response: ${JSON.stringify(error.response.data)}`);
    }
    logs.push('');
    logs.push('========== PROCESSO INTERROMPIDO ==========');

    res.status(500).json({ success: false, logs, error: error.message });
  }
});

// Servir a página principal
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Iniciar servidor
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✓ Servidor iniciado em http://localhost:${PORT}`);
  console.log(`✓ Abra seu navegador e acesse: http://localhost:${PORT}`);
});
