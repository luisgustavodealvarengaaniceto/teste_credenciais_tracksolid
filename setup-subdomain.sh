#!/bin/bash

# Script para configurar subdomínio - Tracksolid Debugger
# Uso: sudo bash setup-subdomain.sh seu-subdominio.com.br

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar se subdomínio foi fornecido
if [ -z "$1" ]; then
    echo -e "${RED}Erro: Você deve fornecer o subdomínio!${NC}"
    echo ""
    echo "Uso: sudo bash setup-subdomain.sh jimibrasil.apitest.com.br"
    echo ""
    exit 1
fi

SUBDOMAIN=$1

echo "=========================================="
echo "CONFIGURAR SUBDOMÍNIO"
echo "=========================================="
echo ""
echo "Subdomínio: $SUBDOMAIN"
echo "IP: 137.131.170.156"
echo ""

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Execute como root (sudo)${NC}"
    exit 1
fi

# 1. Testar DNS
echo -e "${YELLOW}[1/5] Testando DNS...${NC}"
if host "$SUBDOMAIN" | grep -q "137.131.170.156"; then
    echo -e "${GREEN}✓ DNS resolvido corretamente!${NC}"
else
    echo -e "${RED}✗ DNS não resolvido!${NC}"
    echo ""
    echo "Configure o DNS primeiro:"
    echo "  Tipo: A"
    echo "  Nome: ${SUBDOMAIN%%.*}"
    echo "  Valor: 137.131.170.156"
    echo ""
    echo "Aguarde a propagação (5-15 min) e execute novamente."
    exit 1
fi
echo ""

# 2. Criar configuração do Nginx
echo -e "${YELLOW}[2/5] Criando configuração do Nginx...${NC}"
cat > /tmp/tracksolid-nginx.conf << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name $SUBDOMAIN;

    access_log /var/log/nginx/tracksolid-debugger-access.log;
    error_log /var/log/nginx/tracksolid-debugger-error.log;

    proxy_connect_timeout 300;
    proxy_send_timeout 300;
    proxy_read_timeout 300;
    send_timeout 300;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;
    }

    client_max_body_size 10M;
}
EOF

sudo cp /tmp/tracksolid-nginx.conf /etc/nginx/sites-available/tracksolid-debugger
echo -e "${GREEN}✓ Configuração criada${NC}"
echo ""

# 3. Ativar configuração
echo -e "${YELLOW}[3/5] Ativando configuração...${NC}"
sudo rm -f /etc/nginx/sites-enabled/tracksolid-debugger
sudo ln -s /etc/nginx/sites-available/tracksolid-debugger /etc/nginx/sites-enabled/
echo -e "${GREEN}✓ Configuração ativada${NC}"
echo ""

# 4. Testar e recarregar Nginx
echo -e "${YELLOW}[4/5] Testando e recarregando Nginx...${NC}"
if sudo nginx -t; then
    echo -e "${GREEN}✓ Configuração válida${NC}"
    sudo systemctl reload nginx
    echo -e "${GREEN}✓ Nginx recarregado${NC}"
else
    echo -e "${RED}✗ Erro na configuração${NC}"
    exit 1
fi
echo ""

# 5. Testar acesso
echo -e "${YELLOW}[5/5] Testando acesso...${NC}"
sleep 2
if curl -s -o /dev/null -w "%{http_code}" "http://$SUBDOMAIN" | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Acesso HTTP funcionando!${NC}"
else
    echo -e "${YELLOW}⚠ Não foi possível testar o acesso${NC}"
fi
echo ""

echo "=========================================="
echo -e "${GREEN}CONFIGURAÇÃO CONCLUÍDA!${NC}"
echo "=========================================="
echo ""
echo "Acesso: http://$SUBDOMAIN"
echo "Login: JimiIoT"
echo "Senha: SaoJoao2375"
echo ""
echo "PRÓXIMOS PASSOS:"
echo ""
echo "1. Testar no navegador:"
echo "   http://$SUBDOMAIN"
echo ""
echo "2. (Opcional) Adicionar HTTPS:"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo "   sudo certbot --nginx -d $SUBDOMAIN"
echo ""
echo "3. (Opcional) Fechar porta 1313:"
echo "   sudo ufw deny 1313/tcp"
echo ""
