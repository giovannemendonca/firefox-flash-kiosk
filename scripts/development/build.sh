#!/bin/bash
# Script para build da imagem Firefox Flash Kiosk

echo "========================================="
echo "Building Firefox Flash Kiosk Docker Image"
echo "========================================="
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar se docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker não está instalado!${NC}"
    exit 1
fi

# Detectar comando do Docker Compose
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✓ Usando Docker Compose v2${NC}"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓ Usando Docker Compose v1${NC}"
else
    echo -e "${YELLOW}Warning: Docker Compose não encontrado${NC}"
    echo -e "${YELLOW}Tentando build direto com Docker...${NC}"
    COMPOSE_CMD=""
fi

echo -e "${GREEN}✓ Docker encontrado${NC}"
echo ""

# Build da imagem
echo "Iniciando build da imagem..."
echo "Este processo pode levar alguns minutos..."
echo ""

if [ -n "$COMPOSE_CMD" ]; then
    $COMPOSE_CMD build
else
    docker build -t firefox-flash-kiosk .
fi

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}Build concluído com sucesso!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Para iniciar o container, execute:"
    if [ -n "$COMPOSE_CMD" ]; then
        echo -e "${YELLOW}  $COMPOSE_CMD up -d${NC}"
    else
        echo -e "${YELLOW}  docker run -d -p 8080:8080 --name firefox-flash-kiosk firefox-flash-kiosk${NC}"
    fi
    echo ""
    echo "Para ver os logs:"
    if [ -n "$COMPOSE_CMD" ]; then
        echo -e "${YELLOW}  $COMPOSE_CMD logs -f${NC}"
    else
        echo -e "${YELLOW}  docker logs -f firefox-flash-kiosk${NC}"
    fi
    echo ""
    echo "Acesse a interface em:"
    echo -e "${GREEN}  http://localhost:80${NC}"
    echo ""
    echo "Servidor HTTP para arquivos Flash:"
    echo -e "${GREEN}  http://localhost:8081/${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}Erro durante o build!${NC}"
    echo -e "${RED}=========================================${NC}"
    exit 1
fi
