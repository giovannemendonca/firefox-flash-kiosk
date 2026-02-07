#!/bin/bash
# Script de deploy para servidor
# Uso: ./deploy.sh [versão]
# Exemplo: ./deploy.sh latest
# Exemplo: ./deploy.sh 2.0

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
DOCKER_USER="${DOCKER_USER:-seu-usuario}"
IMAGE_NAME="${IMAGE_NAME:-firefox-flash-kiosk}"
VERSION="${1:-latest}"
COMPOSE_FILE="docker-compose.yml"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}🚀 Deploy Firefox Flash Kiosk${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Versão: ${YELLOW}${VERSION}${NC}"
echo -e "Imagem: ${YELLOW}${DOCKER_USER}/${IMAGE_NAME}:${VERSION}${NC}"
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não está instalado!${NC}"
    echo "Instale com: curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose não está instalado!${NC}"
    exit 1
fi

# Usar docker-compose ou docker compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

echo -e "${YELLOW}📦 Pulling image from Docker Hub...${NC}"
docker pull ${DOCKER_USER}/${IMAGE_NAME}:${VERSION}

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao fazer pull da imagem!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Image pulled successfully${NC}"
echo ""

# Parar container existente
if [ "$(docker ps -q -f name=firefox-flash-kiosk)" ]; then
    echo -e "${YELLOW}⏸️  Stopping existing container...${NC}"
    $COMPOSE_CMD down
    echo -e "${GREEN}✓ Container stopped${NC}"
    echo ""
fi

# Iniciar novo container
echo -e "${YELLOW}▶️  Starting container...${NC}"
$COMPOSE_CMD up -d

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao iniciar container!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Container started${NC}"
echo ""

# Aguardar serviços inicializarem
echo -e "${YELLOW}⏳ Waiting for services to start...${NC}"
sleep 10

# Verificar status
echo -e "${YELLOW}📊 Container status:${NC}"
$COMPOSE_CMD ps

echo ""

# Verificar saúde dos serviços
echo -e "${YELLOW}🏥 Checking service health...${NC}"
if docker exec firefox-flash-kiosk supervisorctl status &> /dev/null; then
    docker exec firefox-flash-kiosk supervisorctl status
    echo ""
fi

# Informações de acesso
IP=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Deploy concluído com sucesso!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "🌐 Acesso:"
echo -e "   Local:  ${YELLOW}http://localhost:80${NC}"
echo -e "   Rede:   ${YELLOW}http://${IP}:80${NC}"
echo ""
echo -e "🔐 Credenciais:"
echo -e "   Usuário: ${YELLOW}admin${NC}"
echo -e "   Senha:   ${YELLOW}admin${NC}"
echo ""
echo -e "📝 Ver logs:"
echo -e "   ${YELLOW}${COMPOSE_CMD} logs -f${NC}"
echo ""
echo -e "🔄 Reiniciar:"
echo -e "   ${YELLOW}${COMPOSE_CMD} restart${NC}"
echo ""
echo -e "⏹️  Parar:"
echo -e "   ${YELLOW}${COMPOSE_CMD} down${NC}"
echo ""
