# ============================================
# STAGE 1: Builder - baixa e prepara artefatos
# ============================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget bzip2 git dos2unix ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clonar noVNC + websockify (sem .git para economizar espaco)
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc && \
    rm -rf /opt/novnc/.git && \
    git clone --depth 1 https://github.com/novnc/websockify.git /opt/novnc/utils/websockify && \
    rm -rf /opt/novnc/utils/websockify/.git && \
    ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# Baixar e extrair Firefox 53.0.3 (ultima versao com suporte a Flash)
RUN wget -P /tmp https://ftp.mozilla.org/pub/firefox/releases/53.0.3/linux-x86_64/en-US/firefox-53.0.3.tar.bz2 && \
    tar -C / -xjf /tmp/firefox-53.0.3.tar.bz2 && \
    mkdir -p /firefox/defaults/pref && \
    rm -rf /tmp/*

# Flash Player - baixar SOMENTE o plugin NPAPI (libflashplayer.so)
RUN mkdir -p /usr/lib/mozilla/plugins && \
    wget -O /tmp/flashplayer.tar.gz \
    https://archive.org/download/flashplayerarchive/pub/flashplayer/installers/archive/fp_32.0.0.371_archive.zip/32_0_r0_371_debug%2Fflashplayer32_0r0_371_linux_debug.x86_64.tar.gz && \
    tar -C /usr/lib/mozilla/plugins -zxf /tmp/flashplayer.tar.gz libflashplayer.so && \
    rm -rf /tmp/*

# Copiar e preparar scripts (dos2unix + chmod)
COPY scripts/container/start.sh /start.sh
COPY scripts/firefox/kiosk.sh /usr/local/bin/firefox-kiosk
COPY scripts/firefox/helper.sh /usr/local/bin/fullscreen-helper
COPY scripts/firefox/monitor.sh /usr/local/bin/firefox-monitor
COPY config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN dos2unix /start.sh \
    /usr/local/bin/firefox-kiosk \
    /usr/local/bin/fullscreen-helper \
    /usr/local/bin/firefox-monitor \
    /etc/supervisor/conf.d/supervisord.conf && \
    chmod +x /start.sh \
    /usr/local/bin/firefox-kiosk \
    /usr/local/bin/fullscreen-helper \
    /usr/local/bin/firefox-monitor

# ============================================
# STAGE 2: Runtime - imagem final enxuta
# ============================================
FROM ubuntu:22.04

LABEL maintainer="flash-kiosk"
LABEL description="Firefox with Flash Player - Direct access via noVNC"

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    WIDTH=768 \
    HEIGHT=1024 \
    HOME=/config

# Instalar SOMENTE pacotes de runtime
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates fonts-liberation fonts-dejavu \
    xfonts-base xfonts-75dpi xfonts-100dpi \
    xvfb x11vnc openbox dbus-x11 wmctrl xdotool \
    supervisor netcat python3 \
    libcurl4 libgtk-3-0 libgtk2.0-0 libdbus-glib-1-2 \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/* /usr/share/locale/*

# Criar diretorios
RUN mkdir -p /config /tmp/.X11-unix /etc/xdg/openbox && \
    chmod 1777 /tmp/.X11-unix

# Copiar artefatos do builder
COPY --from=builder /opt/novnc /opt/novnc
COPY --from=builder /firefox /firefox
COPY --from=builder /usr/lib/mozilla/plugins/libflashplayer.so /usr/lib/mozilla/plugins/libflashplayer.so

# Criar symlink do Firefox
RUN ln -s /firefox/firefox /usr/bin/firefox

# Copiar scripts ja preparados (dos2unix + chmod aplicados no builder)
COPY --from=builder /start.sh /start.sh
COPY --from=builder /usr/local/bin/firefox-kiosk /usr/local/bin/firefox-kiosk
COPY --from=builder /usr/local/bin/fullscreen-helper /usr/local/bin/fullscreen-helper
COPY --from=builder /usr/local/bin/firefox-monitor /usr/local/bin/firefox-monitor
COPY --from=builder /etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copiar configuracoes
COPY config/firefox/autoconfig.js /firefox/defaults/pref/autoconfig.js
COPY config/firefox/firefox.cfg /firefox/firefox.cfg
COPY config/openbox/rc.xml /etc/xdg/openbox/rc.xml
COPY config/novnc/mandatory.json /opt/novnc/mandatory.json

# Portas expostas
# 6080 = noVNC (acesso web)
# 5900 = VNC direto
EXPOSE 6080 5900

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD netcat -z localhost 5900 || exit 1

CMD ["/start.sh"]
