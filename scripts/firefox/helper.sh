#!/bin/bash
# ===========================================
# Forca Firefox em tela cheia (F11)
# ===========================================

export DISPLAY=:0

echo "=== Fullscreen Helper Iniciado ==="
echo "Aguardando Firefox iniciar..."

MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "Tentativa $ATTEMPT de $MAX_ATTEMPTS..."

    # Buscar janela do Firefox (varias classes possiveis)
    WINDOW_ID=$(xdotool search --name "Mozilla Firefox" 2>/dev/null | head -1)

    if [ -z "$WINDOW_ID" ]; then
        WINDOW_ID=$(xdotool search --class "Firefox" 2>/dev/null | head -1)
    fi

    if [ -z "$WINDOW_ID" ]; then
        WINDOW_ID=$(xdotool search --class "Navigator" 2>/dev/null | head -1)
    fi

    if [ -n "$WINDOW_ID" ]; then
        echo "Firefox encontrado! Window ID: $WINDOW_ID"

        # Aguardar pagina carregar
        echo "Aguardando pagina carregar..."
        sleep 5

        # Focar na janela
        echo "Focando na janela..."
        xdotool windowfocus --sync $WINDOW_ID 2>/dev/null
        xdotool windowactivate --sync $WINDOW_ID 2>/dev/null
        sleep 1

        # Enviar F11 para tela cheia
        echo "Enviando F11..."
        xdotool key --clearmodifiers F11

        echo "=== F11 enviado com sucesso! ==="
        exit 0
    fi

    sleep 2
done

echo "ERRO: Firefox nao encontrado apos $MAX_ATTEMPTS tentativas"
exit 1
