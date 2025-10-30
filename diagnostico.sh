#!/bin/bash

# Script de diagnóstico - Tracksolid Debugger
# Executar na VM: sudo bash diagnostico.sh

echo "=========================================="
echo "DIAGNÓSTICO - TRACKSOLID DEBUGGER"
echo "=========================================="
echo ""

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Verificar DNS
echo -e "${YELLOW}[1] Verificando DNS...${NC}"
echo "Domínio: testeapi.jimibrasil.com.br"
host testeapi.jimibrasil.com.br || echo -e "${RED}DNS não resolve${NC}"
echo ""

# 2. Verificar se Nginx está rodando
echo -e "${YELLOW}[2] Verificando Nginx...${NC}"
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx está rodando${NC}"
    nginx -v
else
    echo -e "${RED}✗ Nginx NÃO está rodando${NC}"
    echo "Execute: sudo systemctl start nginx"
fi
echo ""

# 3. Verificar portas abertas
echo -e "${YELLOW}[3] Verificando portas...${NC}"
echo "Porta 80 (HTTP):"
sudo netstat -tlnp | grep :80 || echo -e "${RED}Porta 80 não está aberta${NC}"
echo ""
echo "Porta 3000 (Aplicação):"
sudo netstat -tlnp | grep :3000 || echo -e "${RED}Porta 3000 não está aberta${NC}"
echo ""

# 4. Verificar Docker container
echo -e "${YELLOW}[4] Verificando Docker container...${NC}"
if docker ps | grep tracksolid-debugger; then
    echo -e "${GREEN}✓ Container está rodando${NC}"
else
    echo -e "${RED}✗ Container NÃO está rodando${NC}"
    echo "Execute: docker-compose up -d"
fi
echo ""

# 5. Testar aplicação localmente
echo -e "${YELLOW}[5] Testando aplicação na porta 3000...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>&1)
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo -e "${GREEN}✓ Aplicação respondeu: $response${NC}"
else
    echo -e "${RED}✗ Aplicação não responde (código: $response)${NC}"
fi
echo ""

# 6. Testar Nginx proxy
echo -e "${YELLOW}[6] Testando proxy do Nginx...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: testeapi.jimibrasil.com.br" http://localhost 2>&1)
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo -e "${GREEN}✓ Nginx proxy respondeu: $response${NC}"
else
    echo -e "${RED}✗ Nginx proxy não responde (código: $response)${NC}"
fi
echo ""

# 7. Verificar configuração do Nginx
echo -e "${YELLOW}[7] Verificando configuração do Nginx...${NC}"
if [ -f /etc/nginx/sites-available/tracksolid-debugger ]; then
    echo -e "${GREEN}✓ Arquivo de configuração existe${NC}"
    if [ -L /etc/nginx/sites-enabled/tracksolid-debugger ]; then
        echo -e "${GREEN}✓ Site está habilitado${NC}"
    else
        echo -e "${RED}✗ Site NÃO está habilitado${NC}"
        echo "Execute: sudo ln -s /etc/nginx/sites-available/tracksolid-debugger /etc/nginx/sites-enabled/"
    fi
else
    echo -e "${RED}✗ Arquivo de configuração não existe${NC}"
fi

echo ""
echo "Testando sintaxe do Nginx:"
sudo nginx -t
echo ""

# 8. Verificar firewall
echo -e "${YELLOW}[8] Verificando firewall...${NC}"
if command -v ufw &> /dev/null; then
    echo "Status do UFW:"
    sudo ufw status | grep -E "80|3000"
elif command -v firewall-cmd &> /dev/null; then
    echo "Portas abertas no firewalld:"
    sudo firewall-cmd --list-ports
else
    echo "Firewall não detectado ou não configurado"
fi
echo ""

# 9. Ver últimas linhas dos logs
echo -e "${YELLOW}[9] Últimas linhas dos logs...${NC}"
echo ""
echo "=== Nginx Error Log ==="
sudo tail -20 /var/log/nginx/tracksolid-error.log 2>/dev/null || echo "Arquivo não existe"
echo ""
echo "=== Docker Container Log ==="
docker logs --tail 20 tracksolid-debugger 2>/dev/null || echo "Container não encontrado"
echo ""

# 10. Testar conectividade externa
echo -e "${YELLOW}[10] Testando acesso externo...${NC}"
response=$(curl -s -o /dev/null -w "%{http_code}" http://testeapi.jimibrasil.com.br 2>&1)
echo "Resposta externa: $response"
if [ "$response" = "200" ] || [ "$response" = "302" ]; then
    echo -e "${GREEN}✓ Site está acessível externamente${NC}"
else
    echo -e "${RED}✗ Site não está acessível externamente${NC}"
fi
echo ""

echo "=========================================="
echo "DIAGNÓSTICO CONCLUÍDO"
echo "=========================================="
echo ""
echo "SOLUÇÕES COMUNS:"
echo ""
echo "1. Container não está rodando:"
echo "   cd ~/teste_credenciais_tracksolid"
echo "   sudo docker-compose up -d"
echo ""
echo "2. Nginx não está configurado:"
echo "   sudo bash setup-nginx.sh"
echo ""
echo "3. Firewall bloqueando porta 80:"
echo "   sudo ufw allow 80/tcp"
echo "   sudo ufw allow 443/tcp"
echo ""
echo "4. Ver logs em tempo real:"
echo "   sudo tail -f /var/log/nginx/tracksolid-error.log"
echo "   docker logs -f tracksolid-debugger"
echo ""
