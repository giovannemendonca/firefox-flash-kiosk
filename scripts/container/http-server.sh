#!/bin/bash
# Simple HTTP server para servir arquivos Flash
# O Flash Player standalone precisa de um servidor HTTP para carregar arquivos

echo "Starting HTTP server on port 80 for Flash content..."
cd /flash
exec /bin/busybox httpd -f -p 80 -h /flash
