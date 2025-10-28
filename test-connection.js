#!/usr/bin/env node

/**
 * Script de teste para enviar requisição de debug de exemplo
 * Útil para validar que a aplicação está funcionando
 */

const axios = require('axios');

const testData = {
  baseUrl: 'https://hk-open.tracksolidpro.com/route/rest',
  appKey: '2222',
  appSecret: '3',
  userId: '4444',
  password: 'test_password',
  expiresIn: '7200',
  targetAccount: '66'
};

console.log('\n🧪 TESTE DE CONEXÃO - Tracksolid API Debugger\n');
console.log('Enviando requisição de teste ao servidor...\n');

axios.post('http://localhost:3000/api/debug', testData, {
  timeout: 30000
})
  .then(response => {
    console.log('✅ SUCESSO - Servidor respondeu!\n');
    console.log('Resultado:');
    console.log('  - Status:', response.status);
    console.log('  - Success:', response.data.success);
    console.log('  - Linhas de log:', response.data.logs.length);
    console.log('\nPrimeiras linhas do log:');
    response.data.logs.slice(0, 5).forEach(line => {
      console.log('  ', line);
    });
    console.log('\n✅ A aplicação está funcionando corretamente!\n');
  })
  .catch(error => {
    if (error.code === 'ECONNREFUSED') {
      console.log('❌ ERRO - Não foi possível conectar ao servidor.');
      console.log('\nVerifique se você executou:');
      console.log('  npm start\n');
      console.log('E abriu a aplicação em:');
      console.log('  http://localhost:3000\n');
    } else {
      console.log('❌ ERRO:', error.message);
    }
    process.exit(1);
  });
