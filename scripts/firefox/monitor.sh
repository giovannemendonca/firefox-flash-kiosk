#!/bin/bash
# ===========================================
# Monitora Firefox e mantem em tela cheia
# Verifica a cada 30 segundos
# ===========================================

export DISPLAY=:0

echo "Monitor do Firefox iniciado..."

while true; do
    sleep 30

    WINDOW_ID=$(xdotool search --class firefox 2>/dev/null | head -1)

    if [ -n "$WINDOW_ID" ]; then
        # Obter resolucao do display
        DISPLAY_INFO=$(xdpyinfo 2>/dev/null | grep dimensions | awk '{print $2}')
        DISPLAY_WIDTH=$(echo $DISPLAY_INFO | cut -d'x' -f1)
        DISPLAY_HEIGHT=$(echo $DISPLAY_INFO | cut -d'x' -f2)

        # Obter tamanho atual da janela
        GEOMETRY=$(xdotool getwindowgeometry $WINDOW_ID 2>/dev/null | grep Geometry | awk '{print $2}')
        WINDOW_WIDTH=$(echo $GEOMETRY | cut -d'x' -f1)
        WINDOW_HEIGHT=$(echo $GEOMETRY | cut -d'x' -f2)

        # Se nao esta em tela cheia, corrigir
        if [ "$WINDOW_WIDTH" != "$DISPLAY_WIDTH" ] || [ "$WINDOW_HEIGHT" != "$DISPLAY_HEIGHT" ]; then
            echo "Corrigindo tela cheia..."
            xdotool windowactivate $WINDOW_ID
            xdotool key --window $WINDOW_ID F11
        fi
    fi
done
