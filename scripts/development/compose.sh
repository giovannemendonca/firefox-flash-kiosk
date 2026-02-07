#!/bin/bash
# Universal Docker Compose wrapper
# Detecta automaticamente se usa 'docker compose' (v2) ou 'docker-compose' (v1)

# Detectar qual comando usar
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ ERRO: Docker Compose não está instalado!"
    echo ""
    echo "Instale uma das versões:"
    echo "  Docker Compose v2: https://docs.docker.com/compose/install/"
    echo "  Docker Compose v1: pip install docker-compose"
    exit 1
fi

# Exportar para uso em outros scripts
export COMPOSE_CMD

# Se chamado diretamente, executar comando passado
if [ $# -gt 0 ]; then
    $COMPOSE_CMD "$@"
fi
