#!/bin/bash
# ===========================================
# Script de inicializacao do container
# Variaveis definidas no docker-compose.yml
# ===========================================

set -e

# Valores padrao (sobrescritos pelo docker-compose.yml)
export WIDTH="${WIDTH:-1280}"
export HEIGHT="${HEIGHT:-720}"
export VNC_PORT="${VNC_PORT:-5900}"
export NOVNC_PORT="${NOVNC_PORT:-6080}"
export APPNAME="${APPNAME:-firefox-kiosk about:blank}"

echo "=========================================="
echo "Firefox + Flash Player"
echo "=========================================="
echo "Display: ${WIDTH}x${HEIGHT}"
echo "URL: ${APPNAME}"
echo "Acesso: http://localhost:${NOVNC_PORT}"
echo "=========================================="

# Criar diretorios necessarios
mkdir -p /var/log/supervisor
chmod 1777 /tmp/.X11-unix 2>/dev/null || true

# Iniciar supervisor (gerencia todos os processos)
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
