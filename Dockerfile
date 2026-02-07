FROM ubuntu:22.04

LABEL maintainer="flash-kiosk"
LABEL description="Firefox with Flash Player - Direct access via noVNC"

# ===========================================
# VARIAVEIS DE AMBIENTE PADRAO
# Podem ser sobrescritas no docker-compose.yml
# ===========================================
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    WIDTH=768 \
    HEIGHT=1024 \
    HOME=/config

# Instalar dependencias
RUN apt-get update && \
    apt-get install -y \
    ca-certificates fonts-liberation fonts-dejavu \
    xfonts-base xfonts-75dpi xfonts-100dpi \
    xvfb x11vnc openbox dbus-x11 wmctrl xdotool x11-apps \
    curl wget supervisor netcat bzip2 python3 python3-numpy \
    libcurl4 libgtk-3-0 libgtk2.0-0 libdbus-glib-1-2 dos2unix git \
    && rm -rf /var/lib/apt/lists/*

# Instalar noVNC (acesso via navegador)
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc && \
    git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify && \
    ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# Instalar Firefox 53.0.3 (ultima versao com suporte a Flash)
RUN wget -P /tmp https://ftp.mozilla.org/pub/firefox/releases/53.0.3/linux-x86_64/en-US/firefox-53.0.3.tar.bz2 && \
    tar -C / -xjf /tmp/firefox-53.0.3.tar.bz2 && \
    ln -s /firefox/firefox /usr/bin/firefox && \
    mkdir -p /firefox/defaults/pref && \
    rm -rf /tmp/*

# Instalar Flash Player
RUN mkdir -p /player /usr/lib/mozilla/plugins && \
    wget -P /tmp https://fpdownload.macromedia.com/pub/flashplayer/updaters/32/flash_player_sa_linux.x86_64.tar.gz && \
    wget -P /tmp https://fpdownload.macromedia.com/pub/flashplayer/updaters/32/flash_player_sa_linux_debug.x86_64.tar.gz && \
    tar -C /player -zxf /tmp/flash_player_sa_linux.x86_64.tar.gz flashplayer && \
    tar -C /player -zxf /tmp/flash_player_sa_linux_debug.x86_64.tar.gz flashplayerdebugger && \
    wget -O /tmp/flashplayer.tar.gz \
    https://archive.org/download/flashplayerarchive/pub/flashplayer/installers/archive/fp_32.0.0.371_archive.zip/32_0_r0_371_debug%2Fflashplayer32_0r0_371_linux_debug.x86_64.tar.gz && \
    tar -C / -zxf /tmp/flashplayer.tar.gz usr 2>/dev/null || true && \
    tar -C /usr/lib/mozilla/plugins -zxf /tmp/flashplayer.tar.gz libflashplayer.so && \
    ln -s /player/flashplayer /usr/bin/flashplayer && \
    ln -s /player/flashplayerdebugger /usr/bin/flashplayerdebugger && \
    rm -rf /tmp/*

# Criar diretorios
RUN mkdir -p /config /tmp/.X11-unix /etc/xdg/openbox && \
    chmod 1777 /tmp/.X11-unix

# Copiar configuracoes do Firefox (autoconfig para bloquear preferencias)
# autoconfig.js vai em defaults/pref/ - habilita o sistema de autoconfig
# firefox.cfg vai na raiz do firefox - contem as preferencias bloqueadas
COPY config/firefox/autoconfig.js /firefox/defaults/pref/autoconfig.js
COPY config/firefox/firefox.cfg /firefox/firefox.cfg

# Copiar outras configuracoes
COPY config/openbox/rc.xml /etc/xdg/openbox/rc.xml
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copiar scripts
COPY scripts/container/start.sh /start.sh
COPY scripts/firefox/kiosk.sh /usr/local/bin/firefox-kiosk
COPY scripts/firefox/helper.sh /usr/local/bin/fullscreen-helper
COPY scripts/firefox/monitor.sh /usr/local/bin/firefox-monitor

# Converter line endings (Windows -> Linux) e dar permissao
RUN dos2unix /start.sh \
    /usr/local/bin/firefox-kiosk \
    /usr/local/bin/fullscreen-helper \
    /usr/local/bin/firefox-monitor \
    /etc/supervisor/conf.d/supervisord.conf && \
    chmod +x /start.sh \
    /usr/local/bin/firefox-kiosk \
    /usr/local/bin/fullscreen-helper \
    /usr/local/bin/firefox-monitor

# Portas expostas
# 6080 = noVNC (acesso web)
# 5900 = VNC direto
EXPOSE 6080 5900

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD netcat -z localhost 5900 || exit 1

CMD ["/start.sh"]
