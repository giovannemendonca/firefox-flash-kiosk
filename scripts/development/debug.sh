#!/bin/bash
# Script de diagnóstico para verificar o que está no container

echo "=========================================="
echo "DIAGNÓSTICO DO CONTAINER"
echo "=========================================="
echo ""

echo "1. Verificando scripts do Firefox:"
echo "-----------------------------------"
ls -la /usr/local/bin/ | grep firefox
echo ""

echo "2. Verificando se firefox-fullscreen existe:"
echo "-------------------------------------------"
if [ -f /usr/local/bin/firefox-fullscreen ]; then
    echo "✅ firefox-fullscreen existe"
    ls -la /usr/local/bin/firefox-fullscreen
else
    echo "❌ firefox-fullscreen NÃO EXISTE"
fi
echo ""

echo "3. Verificando se firefox-kiosk existe:"
echo "--------------------------------------"
if [ -f /usr/local/bin/firefox-kiosk ]; then
    echo "✅ firefox-kiosk existe"
    ls -la /usr/local/bin/firefox-kiosk
else
    echo "❌ firefox-kiosk NÃO EXISTE"
fi
echo ""

echo "4. Verificando Firefox:"
echo "----------------------"
which firefox
ls -la /firefox/firefox 2>/dev/null || echo "Firefox não encontrado em /firefox/firefox"
echo ""

echo "5. PATH atual:"
echo "-------------"
echo $PATH
echo ""

echo "6. Tentando executar firefox-fullscreen:"
echo "---------------------------------------"
/usr/local/bin/firefox-fullscreen --help 2>&1 | head -5
echo ""

echo "7. Variáveis de ambiente:"
echo "------------------------"
echo "WIDTH=$WIDTH"
echo "HEIGHT=$HEIGHT"
echo "DISPLAY=$DISPLAY"
echo "APPNAME=$APPNAME"
echo ""

echo "=========================================="
