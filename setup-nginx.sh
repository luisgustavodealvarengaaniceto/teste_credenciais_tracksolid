#!/bin/bash

# Script para configurar Nginx - Tracksolid Debugger
# Domínio: testeapi.jimibrasil.com.br
# Executar na VM Ubuntu: sudo bash setup-nginx.sh

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="testeapi.jimibrasil.com.br"
VM_IP="137.131.170.156"
APP_PORT="3000"

echo "=========================================="
echo "CONFIGURAR NGINX - TRACKSOLID DEBUGGER"
echo "=========================================="
echo ""
echo "Domínio: $SUBDOMAIN"
echo "IP da VM: $VM_IP"
echo "Porta da aplicação: $APP_PORT"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Execute como root: sudo bash setup-nginx.sh${NC}"
    exit 1
fi

# 1. Verificar se Nginx está instalado
echo -e "${YELLOW}[1/6] Verificando Nginx...${NC}"
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Nginx não encontrado. Instalando...${NC}"
    apt update
    apt install nginx -y
    systemctl start nginx
    systemctl enable nginx
fi
echo -e "${GREEN}✓ Nginx instalado${NC}"
echo ""

# 2. Testar DNS
echo -e "${YELLOW}[2/6] Testando DNS...${NC}"
if host "$SUBDOMAIN" | grep -q "$VM_IP"; then
    echo -e "${GREEN}✓ DNS configurado corretamente!${NC}"
else
    echo -e "${RED}✗ DNS não está apontando para $VM_IP${NC}"
    echo ""
    echo "Configure o DNS primeiro:"
    echo "  Tipo: A"
    echo "  Nome: testeapi"
    echo "  Valor: $VM_IP"
    echo ""
    read -p "Deseja continuar mesmo assim? (s/N): " resposta
    if [[ ! "$resposta" =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi
echo ""

# 3. Criar configuração do Nginx
echo -e "${YELLOW}[3/6] Criando configuração do Nginx...${NC}"
cat > /etc/nginx/sites-available/tracksolid-debugger << 'EOF'
server {
    listen 80;
    listen [::]:80;
    
    server_name testeapi.jimibrasil.com.br;

    access_log /var/log/nginx/tracksolid-access.log;
    error_log /var/log/nginx/tracksolid-error.log;

    # Timeouts
    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    send_timeout 300;

    # Proxy para o container Docker
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
    }

    # Tamanho máximo de upload
    client_max_body_size 10M;
}
EOF

echo -e "${GREEN}✓ Arquivo de configuração criado${NC}"
echo ""

# 4. Ativar site
echo -e "${YELLOW}[4/6] Ativando site no Nginx...${NC}"
rm -f /etc/nginx/sites-enabled/tracksolid-debugger
ln -s /etc/nginx/sites-available/tracksolid-debugger /etc/nginx/sites-enabled/
echo -e "${GREEN}✓ Site ativado${NC}"
echo ""

# 5. Testar configuração
echo -e "${YELLOW}[5/6] Testando configuração do Nginx...${NC}"
if nginx -t; then
    echo -e "${GREEN}✓ Configuração válida${NC}"
else
    echo -e "${RED}✗ Erro na configuração do Nginx${NC}"
    exit 1
fi
echo ""

# 6. Recarregar Nginx
echo -e "${YELLOW}[6/6] Recarregando Nginx...${NC}"
systemctl reload nginx
echo -e "${GREEN}✓ Nginx recarregado${NC}"
echo ""

# Verificar se aplicação está rodando
echo -e "${YELLOW}Verificando aplicação...${NC}"
if curl -s http://localhost:$APP_PORT > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Aplicação está respondendo na porta $APP_PORT${NC}"
else
    echo -e "${RED}✗ Aplicação não está respondendo na porta $APP_PORT${NC}"
    echo -e "${YELLOW}Certifique-se de que o container Docker está rodando:${NC}"
    echo "  docker ps | grep tracksolid-debugger"
    echo "  docker-compose up -d"
fi
echo ""

echo "=========================================="
echo -e "${GREEN}CONFIGURAÇÃO CONCLUÍDA!${NC}"
echo "=========================================="
echo ""
echo "Acesso HTTP: http://$SUBDOMAIN"
echo "Login: JimiIoT"
echo "Senha: SaoJoao2375"
echo ""
echo "PRÓXIMOS PASSOS:"
echo ""
echo "1. Testar no navegador:"
echo "   http://$SUBDOMAIN"
echo ""
echo "2. (Recomendado) Adicionar HTTPS com Let's Encrypt:"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo "   sudo certbot --nginx -d $SUBDOMAIN"
echo ""
echo "3. Ver logs do Nginx:"
echo "   sudo tail -f /var/log/nginx/tracksolid-access.log"
echo "   sudo tail -f /var/log/nginx/tracksolid-error.log"
echo ""
echo "4. Ver logs do container:"
echo "   docker logs -f tracksolid-debugger"
echo ""
