#!/usr/bin/env node

/**
 * Script de validação da instalação
 * Executa verificações básicas antes de iniciar o servidor
 */

const fs = require('fs');
const path = require('path');

console.log('\n🔍 VERIFICANDO INSTALAÇÃO DO TRACKSOLID API DEBUGGER\n');

const checks = [
  {
    name: 'Arquivo package.json',
    file: 'package.json'
  },
  {
    name: 'Arquivo server.js',
    file: 'server.js'
  },
  {
    name: 'Arquivo public/index.html',
    file: 'public/index.html'
  },
  {
    name: 'Arquivo public/styles.css',
    file: 'public/styles.css'
  },
  {
    name: 'Arquivo public/script.js',
    file: 'public/script.js'
  }
];

let allGood = true;

checks.forEach(check => {
  const filePath = path.join(__dirname, check.file);
  if (fs.existsSync(filePath)) {
    console.log(`✅ ${check.name}`);
  } else {
    console.log(`❌ ${check.name} - NÃO ENCONTRADO`);
    allGood = false;
  }
});

console.log('\n');

// Verificar dependências
console.log('📦 Verificando dependências...\n');

try {
  require('express');
  console.log('✅ express');
} catch (e) {
  console.log('❌ express - INSTALE COM: npm install');
  allGood = false;
}

try {
  require('cors');
  console.log('✅ cors');
} catch (e) {
  console.log('❌ cors - INSTALE COM: npm install');
  allGood = false;
}

try {
  require('md5');
  console.log('✅ md5');
} catch (e) {
  console.log('❌ md5 - INSTALE COM: npm install');
  allGood = false;
}

try {
  require('axios');
  console.log('✅ axios');
} catch (e) {
  console.log('❌ axios - INSTALE COM: npm install');
  allGood = false;
}

console.log('\n');

if (allGood) {
  console.log('✅ TUDO OK! Você pode executar: npm start\n');
} else {
  console.log('⚠️  Existem problemas. Execute: npm install\n');
  process.exit(1);
}
