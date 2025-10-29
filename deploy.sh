#!/bin/bash

# Script de Deploy Automático - Tracksolid Debugger
# Executar na VM: sudo bash deploy.sh

set -e

echo "=========================================="
echo "DEPLOY - TRACKSOLID DEBUGGER"
echo "=========================================="
echo ""

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, execute como root (sudo)${NC}"
    exit 1
fi

# 1. Verificar se Docker está instalado
echo -e "${YELLOW}[1/7] Verificando Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker não encontrado. Instalando...${NC}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker
fi
echo -e "${GREEN}✓ Docker OK${NC}"
echo ""

# 2. Verificar se Docker Compose está instalado
echo -e "${YELLOW}[2/7] Verificando Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker Compose não encontrado. Instalando...${NC}"
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi
echo -e "${GREEN}✓ Docker Compose OK${NC}"
echo ""

# 3. Parar e remover container antigo (se existir)
echo -e "${YELLOW}[3/7] Removendo containers antigos...${NC}"
docker-compose down 2>/dev/null || true
echo -e "${GREEN}✓ Containers antigos removidos${NC}"
echo ""

# 4. Construir nova imagem
echo -e "${YELLOW}[4/7] Construindo imagem Docker...${NC}"
docker-compose build
echo -e "${GREEN}✓ Imagem construída${NC}"
echo ""

# 5. Iniciar container
echo -e "${YELLOW}[5/7] Iniciando container...${NC}"
docker-compose up -d
sleep 5
echo -e "${GREEN}✓ Container iniciado${NC}"
echo ""

# 6. Configurar Nginx
echo -e "${YELLOW}[6/7] Configurando Nginx...${NC}"

# Copiar configuração
cp nginx-config.conf /etc/nginx/sites-available/tracksolid-debugger

# Criar link simbólico (se não existir)
if [ ! -L /etc/nginx/sites-enabled/tracksolid-debugger ]; then
    ln -s /etc/nginx/sites-available/tracksolid-debugger /etc/nginx/sites-enabled/
fi

# Testar configuração
if nginx -t; then
    echo -e "${GREEN}✓ Configuração do Nginx válida${NC}"
    systemctl reload nginx
    echo -e "${GREEN}✓ Nginx recarregado${NC}"
else
    echo -e "${RED}✗ Erro na configuração do Nginx${NC}"
    exit 1
fi
echo ""

# 7. Configurar Firewall (UFW)
echo -e "${YELLOW}[7/7] Configurando Firewall...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 1313/tcp
    echo -e "${GREEN}✓ Porta 1313 liberada no UFW${NC}"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=1313/tcp
    firewall-cmd --reload
    echo -e "${GREEN}✓ Porta 1313 liberada no Firewalld${NC}"
else
    echo -e "${YELLOW}⚠ Firewall não detectado. Libere manualmente a porta 1313${NC}"
fi
echo ""

# Verificar se está rodando
echo -e "${YELLOW}Verificando status...${NC}"
if docker ps | grep -q tracksolid-debugger; then
    echo -e "${GREEN}✓ Container rodando com sucesso!${NC}"
else
    echo -e "${RED}✗ Container não está rodando!${NC}"
    echo "Logs do container:"
    docker logs tracksolid-debugger
    exit 1
fi

echo ""
echo "=========================================="
echo -e "${GREEN}DEPLOY CONCLUÍDO COM SUCESSO!${NC}"
echo "=========================================="
echo ""
echo "URL de Acesso: http://137.131.170.156:1313"
echo "Login: JimiIoT"
echo "Senha: SaoJoao2375"
echo ""
echo "Comandos úteis:"
echo "  - Ver logs: docker logs -f tracksolid-debugger"
echo "  - Parar: docker-compose down"
echo "  - Reiniciar: docker-compose restart"
echo ""
