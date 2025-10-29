// Verificar autenticação ao carregar a página
window.addEventListener('DOMContentLoaded', () => {
  const isAuthenticated = sessionStorage.getItem('authenticated');
  if (isAuthenticated !== 'true') {
    window.location.href = 'login.html';
  }
});

// Variáveis globais
let currentLogs = [];

// Função para alternar visibilidade de senha
function togglePasswordVisibility() {
  const input = document.getElementById('appSecret');
  input.type = input.type === 'password' ? 'text' : 'password';
}

function togglePasswordVisibility2() {
  const input = document.getElementById('password');
  input.type = input.type === 'password' ? 'text' : 'password';
}

// Função para renderizar os logs
function renderLogs() {
  const logContainer = document.getElementById('logContainer');
  
  if (currentLogs.length === 0) {
    logContainer.innerHTML = '<div class="log-empty"><p>Os logs aparecerão aqui após executar o debug...</p></div>';
    return;
  }

  let html = '';
  currentLogs.forEach(line => {
    const className = getLogLineClass(line);
    html += `<div class="log-line ${className}">${escapeHtml(line)}</div>`;
  });

  logContainer.innerHTML = html;
  // Scroll para o final
  logContainer.scrollTop = logContainer.scrollHeight;
}

// Função para determinar a classe CSS da linha de log
function getLogLineClass(line) {
  if (line.includes('✅') || line.includes('✓')) return 'success';
  if (line.includes('❌') || line.includes('ERRO')) return 'error';
  if (line.includes('⚠️')) return 'warning';
  if (line.includes('📤') || line.includes('📥')) return 'info';
  if (line.includes('=====')) return 'header';
  if (line.includes('---')) return 'header';
  return '';
}

// Função para escapar caracteres HTML
function escapeHtml(text) {
  const map = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;'
  };
  return text.replace(/[&<>"']/g, m => map[m]);
}

// Função principal para executar o debug
async function executeDebug() {
  // Validar campos
  const baseUrl = document.getElementById('baseUrl').value.trim();
  const appKey = document.getElementById('appKey').value.trim();
  const appSecret = document.getElementById('appSecret').value.trim();
  const userId = document.getElementById('userId').value.trim();
  const password = document.getElementById('password').value.trim();
  const expiresIn = document.getElementById('expiresIn').value.trim();
  const targetAccount = document.getElementById('targetAccount').value.trim();

  if (!baseUrl || !appKey || !appSecret || !userId || !password || !expiresIn || !targetAccount) {
    alert('⚠️ Por favor, preencha todos os campos obrigatórios!');
    return;
  }

  // Desabilitar botão e mostrar spinner
  const executeButton = document.getElementById('executeButton');
  const loadingSpinner = document.getElementById('loadingSpinner');
  executeButton.disabled = true;
  loadingSpinner.classList.remove('hidden');

  try {
    const response = await fetch('/api/debug', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        baseUrl,
        appKey,
        appSecret,
        userId,
        password,
        expiresIn,
        targetAccount
      })
    });

    const result = await response.json();
    currentLogs = result.logs;
    renderLogs();

    if (!result.success) {
      alert(`❌ Erro no processo: ${result.error}`);
    }
  } catch (error) {
    currentLogs = [
      '========== ERRO NA CONEXÃO ==========',
      '',
      `❌ Erro: ${error.message}`,
      '',
      'Possíveis causas:',
      '- Servidor não está rodando',
      '- URL do servidor está incorreta',
      '- Problema de conectividade',
      '',
      '========== FIM ==========',
    ];
    renderLogs();
    alert(`❌ Erro na conexão: ${error.message}`);
  } finally {
    executeButton.disabled = false;
    loadingSpinner.classList.add('hidden');
  }
}

// Função para limpar logs
function clearLogs() {
  currentLogs = [];
  renderLogs();
}

// Função para copiar logs
function copyLogs() {
  if (currentLogs.length === 0) {
    alert('ℹ️ Não há logs para copiar!');
    return;
  }

  const text = currentLogs.join('\n');
  navigator.clipboard.writeText(text).then(() => {
    alert('✓ Logs copiados para a área de transferência!');
  }).catch(err => {
    alert('❌ Erro ao copiar logs: ' + err);
  });
}

// Função para baixar logs
function downloadLogs() {
  if (currentLogs.length === 0) {
    alert('ℹ️ Não há logs para baixar!');
    return;
  }

  const text = currentLogs.join('\n');
  const blob = new Blob([text], { type: 'text/plain;charset=utf-8;' });
  const link = document.createElement('a');
  const url = URL.createObjectURL(blob);

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5);
  link.setAttribute('href', url);
  link.setAttribute('download', `tracksolid-debug-${timestamp}.log`);
  link.style.visibility = 'hidden';

  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}


// Função para fazer logout
function logout() {
  sessionStorage.removeItem('authenticated');
  window.location.href = 'login.html';
}

// Inicializar quando a página carrega
document.addEventListener('DOMContentLoaded', () => {
  renderLogs();
});
