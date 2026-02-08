# Arquitetura Tecnica - Firefox Flash Kiosk

Documentacao tecnica completa do projeto.

---

## Indice

1. [Visao Geral](#visao-geral)
2. [Componentes](#componentes)
3. [Fluxo de Inicializacao](#fluxo-de-inicializacao)
4. [Arquivos de Configuracao](#arquivos-de-configuracao)
5. [Scripts](#scripts)
6. [Variaveis de Ambiente](#variaveis-de-ambiente)
7. [Rede e Portas](#rede-e-portas)
8. [Logs e Debug](#logs-e-debug)

---

## Visao Geral

### Objetivo

Fornecer um ambiente containerizado para executar aplicacoes web que dependem do Adobe Flash Player, acessivel via navegador web moderno.

### Tecnologias

| Componente | Versao | Funcao |
|------------|--------|--------|
| Ubuntu | 22.04 | Sistema base |
| Firefox | 53.0.3 | Navegador com suporte NPAPI |
| Flash Player | 32.0.0.371 | Plugin Flash (ultima versao) |
| Xvfb | - | Display virtual X11 |
| x11vnc | - | Servidor VNC |
| noVNC | latest | Cliente VNC web |
| Openbox | - | Gerenciador de janelas |
| Supervisor | - | Gerenciador de processos |

### Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                         CONTAINER DOCKER                         │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                      SUPERVISOR                           │   │
│  │                   (Gerenciador de Processos)              │   │
│  │                                                          │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │   │
│  │  │  Xvfb   │  │ Openbox │  │ x11vnc  │  │  noVNC  │     │   │
│  │  │ :0      │  │         │  │ :5900   │  │ :6080   │     │   │
│  │  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘     │   │
│  │       │            │            │            │           │   │
│  │       └────────────┴────────────┘            │           │   │
│  │                    │                         │           │   │
│  │              X11 Display :0                  │           │   │
│  │                    │                         │           │   │
│  │  ┌─────────────────┴─────────────────┐      │           │   │
│  │  │           FIREFOX 53              │      │           │   │
│  │  │      + Flash Player Plugin        │      │           │   │
│  │  └───────────────────────────────────┘      │           │   │
│  │                                              │           │   │
│  │  ┌──────────────────┐                        │           │   │
│  │  │ fullscreen-helper│                        │           │   │
│  │  │ firefox-monitor  │                        │           │   │
│  │  └──────────────────┘                        │           │   │
│  │                                              │           │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                       │              │
                       │ :5900        │ :6080
                       ▼              ▼
                  VNC Direto     noVNC Web
```

---

## Componentes

### 1. Xvfb (X Virtual Framebuffer)

**Funcao**: Cria um display X11 virtual na memoria.

**Configuracao**:
```bash
/usr/bin/Xvfb :0 -screen 0 ${WIDTH}x${HEIGHT}x24
```

**Parametros**:
- `:0` - Numero do display
- `-screen 0` - Tela 0
- `${WIDTH}x${HEIGHT}x24` - Resolucao e profundidade de cor (24 bits)

### 2. Openbox (Window Manager)

**Funcao**: Gerenciador de janelas minimalista.

**Arquivo de configuracao**: `/etc/xdg/openbox/rc.xml`

**Recursos**:
- Remove bordas das janelas do Firefox
- Forca maximizacao e tela cheia
- Posiciona janelas em 0,0

### 3. x11vnc (VNC Server)

**Funcao**: Exporta o display X11 via protocolo VNC.

**Configuracao**:
```bash
/usr/bin/x11vnc -display :0 -forever -shared -rfbport 5900 -nopw -noxdamage
```

**Parametros**:
- `-display :0` - Display a exportar
- `-forever` - Nao encerra apos desconexao
- `-shared` - Permite multiplas conexoes
- `-rfbport 5900` - Porta VNC
- `-nopw` - Sem senha
- `-noxdamage` - Desabilita extensao DAMAGE (compatibilidade)

### 4. noVNC (Web VNC Client)

**Funcao**: Proxy WebSocket que permite acessar VNC via navegador.

**Configuracao**:
```bash
/opt/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 6080
```

**Arquivos personalizados copiados para o container**:
- `/opt/novnc/mandatory.json` - Configuracoes obrigatorias (autoconnect, resize, etc.)
- `/opt/novnc/index.html` - Pagina customizada (interface limpa para kiosk)

**Fluxo**:
1. Usuario acessa `http://host:6080`
2. noVNC carrega `index.html` customizado
3. `mandatory.json` aplica configuracoes obrigatorias (autoconnect, scale local, etc.)
4. WebSocket conecta automaticamente ao x11vnc local
5. Imagem e transmitida e escalada no navegador para caber na tela do cliente

### 5. Firefox 53.0.3

**Funcao**: Navegador com suporte nativo a plugins NPAPI (Flash).

**Por que versao 53?**
- Ultima versao com suporte completo a NPAPI
- Firefox 52 ESR foi a ultima ESR com suporte
- Versao 53 ainda funciona com Flash

**Localizacao**: `/firefox/firefox`

**Configuracoes**:
- `/firefox/defaults/pref/autoconfig.js` - Habilita autoconfig
- `/firefox/firefox.cfg` - Preferencias bloqueadas

### 6. Flash Player 32.0.0.371

**Funcao**: Plugin para executar conteudo Flash.

**Componentes instalados**:
- `/usr/lib/mozilla/plugins/libflashplayer.so` - Plugin NPAPI
- `/usr/bin/flashplayer` - Standalone player
- `/usr/bin/flashplayerdebugger` - Debug player

### 7. Supervisor

**Funcao**: Gerenciador de processos que inicia e monitora todos os servicos.

**Arquivo**: `/etc/supervisor/conf.d/supervisord.conf`

**Recursos**:
- Inicia processos em ordem (priority)
- Reinicia processos que falham (autorestart)
- Gerencia logs

---

## Fluxo de Inicializacao

### Sequencia Completa

```
Container Start
     │
     ▼
┌─────────────────┐
│    start.sh     │  1. Configura variaveis de ambiente
│                 │  2. Cria diretorios
│                 │  3. Inicia supervisord
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   supervisord   │  Gerenciador de processos
└────────┬────────┘
         │
         ├──────────────────────────────────────────────┐
         │                                              │
         ▼ [priority=10]                                │
┌─────────────────┐                                     │
│      Xvfb       │  Display virtual X11 :0             │
└────────┬────────┘                                     │
         │                                              │
         ▼ [priority=20, startsecs=3]                   │
┌─────────────────┐                                     │
│    Openbox      │  Gerenciador de janelas             │
└────────┬────────┘                                     │
         │                                              │
         ▼ [priority=30, startsecs=3]                   │
┌─────────────────┐                                     │
│    x11vnc       │  Servidor VNC                       │
└────────┬────────┘                                     │
         │                                              │
         ▼ [priority=35, startsecs=3]                   │
┌─────────────────┐                                     │
│     noVNC       │  Proxy WebSocket                    │
└────────┬────────┘                                     │
         │                                              │
         ▼ [priority=50, sleep 5]                       │
┌─────────────────┐                                     │
│    Firefox      │  Navegador + Flash                  │
│   (kiosk.sh)    │                                     │
└────────┬────────┘                                     │
         │                                              │
         ▼ [priority=55, sleep 3]                       │
┌─────────────────┐                                     │
│ fullscreen-     │  Envia F11 para Firefox             │
│ helper          │                                     │
└────────┬────────┘                                     │
         │                                              │
         ▼ [priority=60, startsecs=5]                   │
┌─────────────────┐                                     │
│ firefox-monitor │  Monitora tela cheia                │
└─────────────────┘                                     │
                                                        │
◄───────────────────────────────────────────────────────┘
```

### Tempos de Inicializacao

| Servico | Delay | Tempo Total |
|---------|-------|-------------|
| Xvfb | 0s | ~1s |
| Openbox | startsecs=3 | ~4s |
| x11vnc | startsecs=3 | ~4s |
| noVNC | startsecs=3 | ~4s |
| Firefox | sleep 5 | ~8s |
| fullscreen-helper | sleep 3 + deteccao | ~15s |
| firefox-monitor | startsecs=5 | ~10s |

**Tempo total ate tela cheia**: ~15-20 segundos

---

## Arquivos de Configuracao

### /firefox/defaults/pref/autoconfig.js

```javascript
// Habilita o arquivo de configuracao personalizado
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
```

**Funcao**: Instrui o Firefox a carregar `firefox.cfg` na inicializacao.

### /firefox/firefox.cfg

```javascript
// IMPORTANTE: Primeira linha deve ser comentario

// Desabilitar verificacao de navegador padrao
lockPref("browser.shell.checkDefaultBrowser", false);
lockPref("browser.shell.skipDefaultBrowserCheck", true);

// Desabilitar atualizacoes
lockPref("app.update.enabled", false);
lockPref("app.update.auto", false);

// Flash Player - ATIVADO
lockPref("plugin.state.flash", 2);
lockPref("plugin.default.state", 2);

// Tela cheia sem avisos
lockPref("full-screen-api.approval-required", false);
lockPref("full-screen-api.warning.timeout", 0);

// ... outras configuracoes
```

**Tipos de preferencias**:
- `pref()` - Valor padrao, usuario pode alterar
- `defaultPref()` - Valor padrao
- `lockPref()` - Valor bloqueado, usuario NAO pode alterar
- `user_pref()` - Valor do usuario (nao usar em autoconfig)

### /opt/novnc/mandatory.json

```json
{
  "autoconnect": true,
  "resize": "scale",
  "clip": false,
  "view_clip": false,
  "shared": false,
  "view_only": false,
  "reconnect": true,
  "reconnect_delay": 1000,
  "show_dot": false,
  "bell": false,
  "keep_device_awake": true,
  "quality": 8,
  "compression": 4
}
```

**Funcao**: Define configuracoes obrigatorias do noVNC que o usuario nao pode alterar pela interface.

**Parametros**:
- `autoconnect: true` - Conecta automaticamente ao VNC, sem necessidade de clicar "Connect"
- `resize: "scale"` - Escala a imagem no navegador (client-side) para caber na janela, sem alterar a resolucao do Xvfb
- `clip: false` / `view_clip: false` - Desativados para permitir que o scale funcione (clip e scale sao mutuamente exclusivos)
- `shared: false` - Apenas uma conexao por vez
- `reconnect: true` / `reconnect_delay: 1000` - Reconecta automaticamente em 1 segundo
- `keep_device_awake: true` - Impede que dispositivos moveis entrem em modo de espera
- `quality: 8` - Alta qualidade de imagem (escala 0-9)
- `compression: 4` - Compressao moderada (escala 0-9)

### /opt/novnc/index.html

**Funcao**: Pagina personalizada do cliente noVNC que substitui a pagina padrao.

**Customizacoes aplicadas**:
- Forca `scaleViewport = true` e `clipViewport = false` apos conexao (garante scaling correto)
- Oculta logo noVNC (`display: none` no `.noVNC_logo`)
- Oculta botao de configuracoes (`display: none` no `#noVNC_settings_button`)
- Oculta botao de desconectar (`display: none` no `#noVNC_disconnect_button`)
- Oculta botoes de extra keys, clipboard, fullscreen e drag (interface limpa para modo kiosk)

**Motivo**: Em modo kiosk, o usuario final nao deve ter acesso a configuracoes, desconexao ou controles avancados do noVNC.

### /etc/xdg/openbox/rc.xml

```xml
<applications>
  <application class="firefox" name="firefox">
    <decor>no</decor>           <!-- Sem bordas -->
    <maximized>yes</maximized>  <!-- Maximizado -->
    <fullscreen>yes</fullscreen><!-- Tela cheia -->
    <position force="yes">
      <x>0</x>
      <y>0</y>
    </position>
    <focus>yes</focus>
    <layer>above</layer>
  </application>
</applications>
```

**Funcao**: Configura como Openbox trata janelas do Firefox.

### /etc/supervisor/conf.d/supervisord.conf

```ini
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisor/supervisord.log

[program:xvfb]
priority=10
command=/usr/bin/Xvfb :0 -screen 0 %(ENV_WIDTH)sx%(ENV_HEIGHT)sx24
autorestart=true

[program:app]
priority=50
command=/bin/bash -c "sleep 5 && %(ENV_APPNAME)s"
environment=DISPLAY=":0"
autorestart=true

# ... outros programas
```

**Parametros importantes**:
- `priority` - Ordem de inicializacao (menor = primeiro)
- `autorestart` - Reiniciar se falhar
- `startsecs` - Segundos para considerar "iniciado"
- `%(ENV_VAR)s` - Substitui por variavel de ambiente

---

## Scripts

### /start.sh

```bash
#!/bin/bash
set -e

# Valores padrao
export WIDTH="${WIDTH:-1280}"
export HEIGHT="${HEIGHT:-720}"
export VNC_PORT="${VNC_PORT:-5900}"
export NOVNC_PORT="${NOVNC_PORT:-6080}"
export APPNAME="${APPNAME:-firefox-kiosk about:blank}"

# Criar diretorios
mkdir -p /var/log/supervisor

# Iniciar supervisor
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
```

**Funcao**: Ponto de entrada do container.

### /usr/local/bin/firefox-kiosk

```bash
#!/bin/bash
export DISPLAY=:0

URL="$1"
if [ -z "$URL" ]; then
    URL="about:blank"
fi

exec /firefox/firefox --no-remote --new-window "$URL"
```

**Funcao**: Inicia Firefox com URL especificada.

**Parametros do Firefox**:
- `--no-remote` - Nao conecta a instancia existente
- `--new-window` - Abre nova janela

### /usr/local/bin/fullscreen-helper

```bash
#!/bin/bash
export DISPLAY=:0

# Aguarda Firefox iniciar
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    WINDOW_ID=$(xdotool search --name "Mozilla Firefox" | head -1)

    if [ -n "$WINDOW_ID" ]; then
        sleep 5  # Aguarda pagina carregar
        xdotool windowfocus --sync $WINDOW_ID
        xdotool key --clearmodifiers F11
        exit 0
    fi

    sleep 2
done
```

**Funcao**: Encontra janela do Firefox e envia F11.

**Ferramentas usadas**:
- `xdotool search` - Encontra janelas por nome/classe
- `xdotool windowfocus` - Foca na janela
- `xdotool key F11` - Envia tecla F11

### /usr/local/bin/firefox-monitor

```bash
#!/bin/bash
export DISPLAY=:0

while true; do
    sleep 30

    WINDOW_ID=$(xdotool search --class firefox | head -1)

    if [ -n "$WINDOW_ID" ]; then
        # Verifica se esta em tela cheia
        GEOMETRY=$(xdotool getwindowgeometry $WINDOW_ID)

        # Se nao esta, reenvia F11
        if [ tamanho != display ]; then
            xdotool key --window $WINDOW_ID F11
        fi
    fi
done
```

**Funcao**: Monitora e corrige tela cheia a cada 30 segundos.

---

## Variaveis de Ambiente

### Definidas no Dockerfile (valores padrao)

```dockerfile
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:0
ENV VNC_PORT=5900
ENV NOVNC_PORT=6080
ENV WIDTH=768
ENV HEIGHT=1024
ENV HOME=/config
```

### Sobrescritas no docker-compose.yml

```yaml
environment:
  - WIDTH=1024
  - HEIGHT=768
  - APPNAME=firefox-kiosk https://exemplo.com
```

### Referencia Completa

| Variavel | Padrao | Usado em | Descricao |
|----------|--------|----------|-----------|
| `DISPLAY` | `:0` | Todos X11 | Display X11 |
| `WIDTH` | `768` | Xvfb, scripts | Largura em pixels |
| `HEIGHT` | `1024` | Xvfb, scripts | Altura em pixels |
| `VNC_PORT` | `5900` | x11vnc, noVNC | Porta VNC interna |
| `NOVNC_PORT` | `6080` | noVNC | Porta web noVNC |
| `APPNAME` | `firefox-kiosk about:blank` | supervisor | Comando a executar |
| `HOME` | `/config` | Firefox | Diretorio home |

---

## Rede e Portas

### Mapeamento de Portas

```yaml
ports:
  - "80:6080"    # noVNC (acesso web)
  - "5900:5900"  # VNC direto (opcional)
```

### Fluxo de Rede

```
Internet/LAN
     │
     ├─── :80 ──────► noVNC (:6080) ──► x11vnc (:5900) ──► Xvfb (:0)
     │
     └─── :5900 ────► x11vnc (:5900) ──► Xvfb (:0)  [opcional]
```

### Protocolos

| Porta | Protocolo | Seguranca |
|-------|-----------|-----------|
| 6080 | HTTP + WebSocket | Sem criptografia |
| 5900 | RFB (VNC) | Sem criptografia |

**Nota**: Para producao, considere usar proxy reverso com HTTPS.

---

## Logs e Debug

### Localizacao dos Logs

```
/var/log/supervisor/
├── supervisord.log      # Log principal do supervisor
├── xvfb.log            # Display virtual
├── xvfb-error.log
├── openbox.log         # Window manager
├── openbox-error.log
├── x11vnc.log          # Servidor VNC
├── x11vnc-error.log
├── novnc.log           # Proxy web
├── novnc-error.log
├── app.log             # Firefox
├── app-error.log
├── fullscreen.log      # Helper F11
├── fullscreen-error.log
├── firefox-monitor.log # Monitor
└── firefox-monitor-error.log
```

### Comandos de Debug

```bash
# Ver todos os logs
docker exec flash-kiosk cat /var/log/supervisor/supervisord.log

# Ver log especifico
docker exec flash-kiosk cat /var/log/supervisor/fullscreen.log

# Status dos servicos
docker exec flash-kiosk supervisorctl status

# Reiniciar servico especifico
docker exec flash-kiosk supervisorctl restart app

# Acessar shell
docker exec -it flash-kiosk /bin/bash

# Ver processos
docker exec flash-kiosk ps aux

# Testar xdotool
docker exec flash-kiosk xdotool search --name "Mozilla Firefox"
```

### Problemas Comuns

| Sintoma | Causa Provavel | Solucao |
|---------|----------------|---------|
| Tela preta | Xvfb nao iniciou | Verificar log xvfb |
| "Connection refused" | noVNC/x11vnc falhou | Verificar logs |
| Flash nao funciona | Plugin nao carregado | Verificar about:plugins |
| Barra aparece | F11 nao enviado | Verificar fullscreen.log |
| Lento | Resolucao muito alta | Reduzir WIDTH/HEIGHT |

---

## Customizacao

### Adicionar Extensoes ao Firefox

Coloque arquivos `.xpi` em um volume e instale manualmente ou via autoconfig.

### Mudar Pagina Inicial

```yaml
environment:
  - APPNAME=firefox-kiosk https://minha-pagina.com
```

### Aumentar Resolucao

```yaml
environment:
  - WIDTH=1920
  - HEIGHT=1080
```

**Nota**: Resolucoes maiores consomem mais memoria e banda.

---

## Consideracoes de Seguranca

### Riscos

1. **Flash Player descontinuado**: Vulnerabilidades conhecidas nao serao corrigidas
2. **Firefox desatualizado**: Versao 53 tem falhas de seguranca
3. **VNC sem criptografia**: Dados trafegam em texto plano
4. **Container como root**: Processos rodam como root

### Mitigacoes Recomendadas

1. **Rede isolada**: Nao exponha para internet
2. **Proxy reverso**: Use HTTPS na frente do noVNC
3. **Firewall**: Restrinja acesso por IP
4. **Atualizacoes**: Mantenha imagem base atualizada
5. **Monitoramento**: Monitore acessos e comportamento

---

## Referencias

- [Firefox Release Notes 53](https://www.mozilla.org/en-US/firefox/53.0/releasenotes/)
- [Adobe Flash Player Archive](https://www.adobe.com/products/flashplayer/end-of-life.html)
- [noVNC Documentation](https://novnc.com/info.html)
- [Supervisor Documentation](http://supervisord.org/)
- [Openbox Documentation](http://openbox.org/wiki/Main_Page)
- [xdotool Manual](https://www.semicomplete.com/projects/xdotool/)
