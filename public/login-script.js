// Credenciais
const VALID_USERNAME = 'JimiIoT';
const VALID_PASSWORD = 'SaoJoao2375';

// Verificar se já está logado ao carregar a página
window.addEventListener('DOMContentLoaded', () => {
  const isAuthenticated = sessionStorage.getItem('authenticated');
  if (isAuthenticated === 'true') {
    window.location.href = 'index.html';
  }
});

function handleLogin(event) {
  event.preventDefault();
  
  const username = document.getElementById('username').value;
  const password = document.getElementById('password').value;
  const errorMessage = document.getElementById('errorMessage');
  
  // Validar credenciais
  if (username === VALID_USERNAME && password === VALID_PASSWORD) {
    // Login bem-sucedido
    sessionStorage.setItem('authenticated', 'true');
    window.location.href = 'index.html';
  } else {
    // Login falhou
    errorMessage.textContent = 'Usuário ou senha incorretos!';
    errorMessage.classList.add('show');
    
    // Limpar mensagem de erro após 3 segundos
    setTimeout(() => {
      errorMessage.classList.remove('show');
    }, 3000);
    
    // Limpar campo de senha
    document.getElementById('password').value = '';
  }
}
