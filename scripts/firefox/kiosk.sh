#!/bin/bash
# ===========================================
# Firefox Kiosk - Apenas inicia o Firefox
# Configuracoes estao em: config/firefox/prefs.js
# ===========================================

export DISPLAY=:0

echo "Aguardando servidor X..."
sleep 3

# URL passada como parametro
URL="$1"
if [ -z "$URL" ]; then
    URL="about:blank"
fi

echo "==================================="
echo "Iniciando Firefox"
echo "URL: $URL"
echo "==================================="

# Iniciar Firefox (fullscreen-helper vai aplicar F11 automaticamente)
exec /firefox/firefox \
    --no-remote \
    --new-window \
    "$URL"
