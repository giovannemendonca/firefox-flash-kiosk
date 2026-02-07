# Firefox Flash Kiosk

Container Docker que executa Firefox 53 com Adobe Flash Player, acessivel via navegador web (noVNC).

## Inicio Rapido

```bash
# Construir a imagem
docker-compose build

# Iniciar o container
docker-compose up -d

# Acessar no navegador
http://localhost:80
```

## O que este projeto faz?

Este projeto cria um ambiente isolado (container Docker) que:

1. Executa o **Firefox 53.0.3** - ultima versao com suporte nativo ao Flash
2. Inclui o **Adobe Flash Player 32** - ultima versao do plugin
3. Fornece acesso via **navegador web** usando noVNC (sem precisar instalar cliente VNC)
4. Funciona em **modo kiosk** - tela cheia, ideal para sistemas legados

## Casos de Uso

- Sistemas legados que dependem de Flash (ERPs, sistemas hospitalares, etc.)
- Aplicacoes web antigas que nao foram migradas
- Acesso a portais que ainda exigem Flash Player

---

## Estrutura do Projeto

```
firefox-flash-kiosk/
├── Dockerfile                    # Definicao da imagem Docker
├── docker-compose.yml            # Configuracao do container
├── Makefile                      # Comandos uteis (make build, make up, etc.)
│
├── config/
│   ├── firefox/
│   │   ├── autoconfig.js         # Habilita configuracao automatica do Firefox
│   │   └── firefox.cfg           # Preferencias bloqueadas do Firefox
│   │
│   ├── openbox/
│   │   └── rc.xml                # Configuracao do gerenciador de janelas
│   │
│   ├── novnc/
│   │   ├── mandatory.json        # Configuracoes obrigatorias do noVNC
│   │   └── index.html            # Pagina personalizada do noVNC
│   │
│   └── supervisor/
│       └── supervisord.conf      # Gerenciador de processos
│
├── scripts/
│   ├── container/
│   │   └── start.sh              # Script de inicializacao do container
│   │
│   └── firefox/
│       ├── kiosk.sh              # Inicia o Firefox
│       ├── helper.sh             # Aplica tela cheia (F11)
│       └── monitor.sh            # Monitora e mantem tela cheia
│
└── docs/
    └── ARQUITETURA.md            # Documentacao tecnica detalhada
```

---

## Configuracao

### Variaveis de Ambiente

Configure no arquivo `docker-compose.yml`:

| Variavel | Padrao | Descricao |
|----------|--------|-----------|
| `WIDTH` | `768` | Largura da tela em pixels |
| `HEIGHT` | `1024` | Altura da tela em pixels |
| `APPNAME` | `firefox-kiosk about:blank` | Comando a executar (Firefox + URL) |
| `VNC_PORT` | `5900` | Porta do servidor VNC interno |
| `NOVNC_PORT` | `6080` | Porta do noVNC (acesso web) |

### Exemplo de Configuracao

```yaml
version: "3.8"

services:
  flash-kiosk:
    build: .
    container_name: flash-kiosk
    environment:
      - WIDTH=1024
      - HEIGHT=768
      - APPNAME=firefox-kiosk https://meu-sistema-legado.com
    ports:
      - "80:6080"      # Acesso web via noVNC
    restart: unless-stopped
```

### Portas Expostas

| Porta | Protocolo | Descricao |
|-------|-----------|-----------|
| `6080` | HTTP | noVNC - acesso via navegador web |
| `5900` | VNC | Acesso VNC direto (cliente VNC) |

---

## Comandos

### Usando Docker Compose

```bash
# Construir a imagem
docker-compose build

# Construir sem cache (rebuild completo)
docker-compose build --no-cache

# Iniciar o container
docker-compose up -d

# Ver logs em tempo real
docker-compose logs -f

# Parar o container
docker-compose down

# Reiniciar
docker-compose restart

# Acessar shell do container
docker exec -it flash-kiosk /bin/bash
```

### Usando Makefile

```bash
make build      # Construir imagem
make up         # Iniciar container
make down       # Parar container
make restart    # Reiniciar
make logs       # Ver logs
make shell      # Acessar shell
make rebuild    # Rebuild completo (limpa cache)
make clean      # Remove container e volumes
make status     # Status dos servicos
make health     # Verificacao de saude
```

---

## Como Funciona

### Ordem de Inicializacao

```
1. start.sh           → Script principal, configura variaveis
    │
    └─→ supervisord   → Gerenciador de processos, inicia todos os servicos
         │
         ├─→ [10] xvfb            → Display virtual X11
         ├─→ [20] openbox         → Gerenciador de janelas
         ├─→ [30] x11vnc          → Servidor VNC
         ├─→ [35] novnc           → Proxy web para VNC
         ├─→ [50] app             → Firefox (apos 5s de delay)
         ├─→ [55] fullscreen-helper → Aplica F11 (apos 3s)
         └─→ [60] firefox-monitor → Monitora tela cheia
```

### Fluxo de Dados

```
Usuario (Navegador)
    │
    │ HTTP :6080
    ▼
  noVNC (WebSocket → VNC)
    │
    │ VNC :5900
    ▼
  x11vnc
    │
    │ X11 :0
    ▼
  Xvfb (Display Virtual)
    │
    ▼
  Openbox (Window Manager)
    │
    ▼
  Firefox 53 + Flash Player
```

---

## Arquivos Detalhados

### Dockerfile

O Dockerfile constroi a imagem com:

1. **Base**: Ubuntu 22.04
2. **Dependencias**: X11, VNC, supervisor, fontes
3. **Firefox 53.0.3**: Baixado do arquivo oficial da Mozilla
4. **Flash Player 32**: Plugin NPAPI e standalone
5. **noVNC**: Cliente VNC web
6. **Scripts**: Configuracao e inicializacao

### config/firefox/firefox.cfg

Configuracoes **bloqueadas** do Firefox (usuario nao pode alterar):

- Desabilita verificacao de navegador padrao
- Desabilita atualizacoes automaticas
- Habilita Flash Player
- Configura tela cheia sem avisos
- Desabilita telemetria e servicos desnecessarios

### config/firefox/autoconfig.js

Arquivo obrigatorio que habilita o sistema de autoconfig do Firefox:

```javascript
pref("general.config.filename", "firefox.cfg");
pref("general.config.obscure_value", 0);
```

### config/openbox/rc.xml

Configuracao do gerenciador de janelas Openbox:

- Remove bordas das janelas
- Forca janelas em tela cheia
- Configura foco automatico

### config/novnc/mandatory.json

Configuracoes **obrigatorias** do noVNC (usuario nao pode alterar):

```json
{
  "autoconnect": true,
  "resize": "remote",
  "clip": true,
  "view_clip": true,
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

| Parametro | Valor | Descricao |
|-----------|-------|-----------|
| `autoconnect` | `true` | Conecta automaticamente ao VNC ao abrir a pagina |
| `resize` | `"remote"` | Redimensiona o display remoto para caber na janela |
| `clip` | `true` | Recorta a visualizacao para o tamanho da janela |
| `reconnect` | `true` | Reconecta automaticamente em caso de desconexao |
| `reconnect_delay` | `1000` | Tempo (ms) para tentar reconectar |
| `keep_device_awake` | `true` | Mantem o dispositivo cliente ativo |
| `quality` | `8` | Qualidade da imagem (0-9, maior = melhor) |
| `compression` | `4` | Nivel de compressao (0-9, maior = mais comprimido) |

### config/novnc/index.html

Pagina personalizada do cliente noVNC, copiada para dentro do container substituindo a pagina padrao. Customizacoes incluem:

- Forca drag viewport ativo apos conexao (para navegacao mobile)
- Oculta o logo noVNC, botao de settings e botao de disconnect
- Oculta botoes de extra keys e drag (interface limpa para kiosk)

### config/supervisor/supervisord.conf

Gerenciador de processos que:

- Inicia todos os servicos na ordem correta
- Reinicia servicos que falham
- Gerencia logs

### scripts/firefox/kiosk.sh

Inicia o Firefox com a URL configurada:

```bash
exec /firefox/firefox --no-remote --new-window "$URL"
```

### scripts/firefox/helper.sh

Aplica modo tela cheia (F11) automaticamente:

1. Aguarda Firefox iniciar
2. Encontra a janela do Firefox
3. Envia tecla F11

### scripts/firefox/monitor.sh

Monitora e corrige a tela cheia:

1. Verifica a cada 30 segundos
2. Se Firefox saiu da tela cheia, reenvia F11

---

## Solucao de Problemas

### Firefox nao inicia em tela cheia

Verifique os logs do fullscreen-helper:

```bash
docker exec flash-kiosk cat /var/log/supervisor/fullscreen.log
```

### Flash Player nao funciona

1. Verifique se o plugin esta instalado:
```bash
docker exec flash-kiosk ls -la /usr/lib/mozilla/plugins/
```

2. Acesse `about:plugins` no Firefox para verificar

### Tela preta ou sem conexao

1. Verifique se o container esta rodando:
```bash
docker-compose ps
```

2. Verifique os logs:
```bash
docker-compose logs -f
```

3. Verifique o status dos servicos:
```bash
docker exec flash-kiosk supervisorctl status
```

### Alterar a URL de acesso

Edite `docker-compose.yml`:

```yaml
environment:
  - APPNAME=firefox-kiosk https://nova-url.com
```

Reinicie o container:

```bash
docker-compose down && docker-compose up -d
```

---

## Seguranca

**ATENCAO**: Este container executa software descontinuado (Flash Player) com vulnerabilidades conhecidas.

Recomendacoes:

- Use apenas em redes isoladas
- Nao exponha para a internet
- Acesse apenas sites confiaveis
- Considere migrar sistemas legados

---

## Licenca

Este projeto e fornecido "como esta" para fins de compatibilidade com sistemas legados.

- Firefox: Mozilla Public License
- Flash Player: Adobe (descontinuado)
- noVNC: MPL 2.0
