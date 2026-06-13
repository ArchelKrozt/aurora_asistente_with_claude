# Aurora v1 — Asistente IA Cyberpunk para Linux

> Ventana flotante de escritorio para Claude CLI con estética cyberpunk, integración profunda con el sistema y soporte multi-cuenta con failover automático.

---

## Tabla de contenidos

1. [¿Qué es Aurora?](#qué-es-aurora)
2. [Requisitos](#requisitos)
3. [Instalación](#instalación)
4. [Cómo se usa](#cómo-se-usa)
5. [Funciones del sistema](#funciones-del-sistema)
6. [Comandos slash](#comandos-slash)
7. [Multi-cuenta Claude — cómo funciona y cómo vincular](#multi-cuenta-claude)
8. [Barra de compactación](#barra-de-compactación)
9. [Historial de conversaciones](#historial-de-conversaciones)
10. [Configuración](#configuración)
11. [Estructura del proyecto](#estructura-del-proyecto)
12. [Tecnologías](#tecnologías)
13. [Limitaciones v1](#limitaciones-v1)

---

## ¿Qué es Aurora?

Aurora es una **aplicación nativa de escritorio Linux** que crea una ventana flotante para interactuar con **Claude CLI** (el CLI oficial de Anthropic). No es un chat web ni una extensión del navegador: es un asistente que vive directamente en tu escritorio y se integra con él.

Fue diseñada para programadores y usuarios técnicos que usan Claude constantemente y quieren:
- Invocarla sin cambiar de ventana (hotkey global)
- Analizar lo que tienen en el portapapeles o en pantalla sin copiar y pegar manualmente
- Ejecutar comandos desde la misma interfaz
- Mantener múltiples cuentas Claude Pro activas con failover automático para nunca quedarse sin tokens

---

## Requisitos

### Sistema operativo
- **Linux** con entorno gráfico **X11** (probado en Linux Mint Cinnamon)
- **No compatible con Wayland** en esta versión — el hotkey global y la captura de pantalla usan la API de Xlib directamente

### Dependencias del sistema
```bash
sudo apt install python3 python3-venv python3-gi gir1.2-gtk-3.0 \
                 ffmpeg scrot libnotify-bin
```

| Paquete | Para qué se usa |
|---|---|
| `python3-gi` | Bindings de GTK3 para Python |
| `ffmpeg` | Captura del escritorio para el blur de ventana |
| `scrot` | Captura de pantalla para análisis con Claude |
| `libnotify-bin` | Notificaciones de escritorio (fallback) |

### Claude CLI
```bash
npm install -g @anthropic-ai/claude-code
claude login    # autenticar con tu cuenta de Claude Pro
```

### Python (se instalan automáticamente con install.sh)
- `Pillow` — aplicar blur gaussiano a la captura del escritorio
- `python-xlib` — hotkey global mediante XGrabKey
- `psutil` — estadísticas de CPU, RAM y red en tiempo real

---

## Instalación

```bash
git clone https://github.com/ArchelKrozt/aurora_asistente_with_claude.git
cd aurora-v1
bash install.sh
```

El script de instalación hace lo siguiente automáticamente:

1. Copia el script `aurora` a `~/.local/bin/aurora` con permisos de ejecución
2. Copia los SVGs a `~/.local/share/aurora/`
3. Crea un entorno virtual Python en `~/.local/share/aurora/venv/` con `--system-site-packages`
4. Instala `Pillow`, `python-xlib` y `psutil` dentro del venv
5. Instala `aurora.desktop` en `~/.config/autostart/` para que Aurora inicie con la sesión

### Iniciar manualmente (primera vez o tras actualización)
```bash
DISPLAY=:0 ~/.local/share/aurora/venv/bin/python3 ~/.local/bin/aurora &
```

### Habilitar soporte sudo (opcional, recomendado)
Aurora puede ejecutar comandos con privilegios usando `/sudo`. Requiere configurar `sudo` sin contraseña una sola vez desde la terminal:

```bash
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/aurora-$USER
sudo chmod 440 /etc/sudoers.d/aurora-$USER
```

> **¿Por qué es necesario?** El autenticador PAM (huella dactilar, contraseña gráfica) no puede ser usado desde un proceso en segundo plano. Con la entrada en `sudoers`, `sudo` funciona sin interacción.

---

## Cómo se usa

### Mostrar / ocultar Aurora
- **Hotkey global**: `Ctrl+Alt+Space` desde cualquier aplicación
- La ventana aparece en la esquina superior derecha de la pantalla principal

### Enviar un mensaje
- Escribe en el campo de texto inferior
- Presiona `Enter` para enviar
- `Shift+Enter` inserta un salto de línea sin enviar

### Header (barra superior)
| Botón | Función |
|---|---|
| **Historial** | Abre el historial de conversaciones con buscador |
| **+ Nueva** | Inicia una conversación nueva (limpia el contexto) |
| **📷** | Captura la pantalla y la envía a Claude para análisis |
| **↓** | Exporta la conversación actual como Markdown |
| **⚙** | Abre el panel de configuración |

### Barra de sysmon
Debajo del header hay una barra que muestra en tiempo real:
```
CPU 34% [███░░░░░░░]  RAM 61% [██████░░░░]  ↑ 0.1MB/s  ↓ 2.3MB/s
```
Se actualiza cada 2 segundos. Se puede desactivar en Configuración → Sistema.

### Bloques de código
Las respuestas que contienen código se muestran con:
- Fondo oscuro diferenciado y fuente monoespaciada
- Etiqueta del lenguaje detectado
- Botón **Copiar** en cada bloque individual

---

## Funciones del sistema

### Hotkey global — `Ctrl+Alt+Space`
Aurora registra esta combinación a nivel de X11 al iniciarse. Funciona desde cualquier aplicación sin necesidad de hacer clic en nada. Si otra aplicación ya usa esa combinación, el hotkey falla silenciosamente (Aurora sigue funcionando, pero sin el atajo).

### Monitor de portapapeles
Aurora escucha el evento `owner-change` del portapapeles de GTK. Cuando detectas que copiaste un texto de **80 o más caracteres** (configurable), aparece un banner en el chat preguntando si quieres analizar el contenido con Claude. Opciones:
- **Analizar** — envía el texto al chat automáticamente
- **Ignorar** — descarta el banner

### Captura de pantalla con análisis
Al presionar **📷** en el header:
1. Aurora toma una captura de pantalla completa con `scrot`
2. La codifica en base64
3. La envía a Claude CLI usando `--input-format stream-json` con un bloque de imagen
4. Claude describe, analiza o responde preguntas sobre lo que está en pantalla

Útil para: analizar errores en pantalla, pedir ayuda con una interfaz, describir un diagrama, etc.

### Drag & Drop de archivos
Arrastra uno o varios archivos directamente al área de chat:
- **Archivos de código** (`.py`, `.js`, `.ts`, `.go`, etc.) — se envía el contenido como texto
- **Imágenes** (`.png`, `.jpg`, `.webp`) — se envían como imagen para análisis visual
- **PDFs** — se extrae el texto y se envía
- Máximo **3 archivos** simultáneos por envío

### Fondo con blur real
Cuando Aurora se muestra, antes de aparecer:
1. Captura el área del escritorio donde se posicionará la ventana con `ffmpeg x11grab`
2. Aplica un **blur gaussiano** (radio 18) con PIL
3. Pinta ese bitmap como fondo de la ventana via Cairo

El resultado es un efecto de vidrio esmerilado real, sin necesidad de un compositor externo como picom.

### Animación de arranque
La primera vez que Aurora se abre cada día muestra una animación de terminal estilo cyberpunk con texto como:
```
INICIALIZANDO ENLACE NEURAL...
CARGANDO MÓDULOS DE IA...
CONEXIÓN ESTABLECIDA.
```
Se puede desactivar en Configuración → Sistema.

### Modo mini
El botón de la barra de header colapsa Aurora a una barra de solo 80px de alto mostrando únicamente el campo de input. Útil para tenerla en pantalla sin ocupar espacio.

### Notificaciones de escritorio
Cuando Aurora termina de procesar una respuesta mientras la ventana está oculta, emite una notificación de escritorio con el inicio de la respuesta. Usa `libnotify` (`GNotify`) o `notify-send` como fallback.

---

## Comandos slash

Escribe `/` en el campo de texto para activar el **autocompletado**. Aparece un popover con los comandos disponibles filtrado en tiempo real.

| Comando | Descripción |
|---|---|
| `/explica` | Explica el código o concepto seleccionado en detalle |
| `/refactor` | Propone una refactorización del código con justificación |
| `/test` | Genera tests unitarios para el código |
| `/doc` | Genera documentación (docstrings, JSDoc, etc.) |
| `/commit` | Genera un mensaje de commit convencional para los cambios |
| `/traduce` | Traduce el texto al español o al idioma solicitado |
| `/resume` | Resume el contenido en puntos clave |
| `/sql` | Genera o explica una consulta SQL |
| `/seguridad` | Analiza vulnerabilidades de seguridad en el código |
| `/debug` | Ayuda a identificar y corregir errores |
| `/run <cmd>` | Ejecuta un comando de terminal y muestra el output |
| `/sudo <cmd>` | Ejecuta un comando con privilegios de superusuario |

### `/run` — Modo terminal
```
/run ls -la
/run git status
/run npm install
/run sudo apt-get update    ← detecta el sudo automáticamente
```
Aurora ejecuta el comando, captura stdout + stderr y muestra el resultado en el chat. Si el comando contiene `sudo`, Aurora lo redirige automáticamente por la ruta privilegiada.

### `/sudo` — Modo superusuario
```
/sudo systemctl restart nginx
/sudo apt-get upgrade
/sudo chmod 755 /var/www/html
```
Ejecuta el comando con `sudo -n` (sin contraseña interactiva, requiere la configuración de sudoers explicada en la instalación). Muestra el output completo en el chat.

> **Seguridad**: Aurora pide confirmación antes de ejecutar cualquier comando de terminal, mostrando exactamente qué se va a ejecutar.

---

## Multi-cuenta Claude

Esta es una de las funciones más importantes de Aurora. Permite vincular **múltiples cuentas de Claude Pro** y usar el failover automático para nunca interrumpir una conversación por límite de tokens.

### Por qué es posible conectar múltiples cuentas

Aurora no llama a la API de Anthropic directamente — ejecuta **Claude CLI** (`claude`) como un proceso de terminal en segundo plano mediante `subprocess.Popen`. Esto es clave, porque Claude CLI guarda sus credenciales en una carpeta local del sistema (`~/.claude` por defecto) y respeta la variable de entorno `CLAUDE_CONFIG_DIR` para apuntar a una carpeta distinta.

Aurora aprovecha exactamente eso: por cada cuenta adicional crea una carpeta aislada y lanza Claude CLI apuntando a ella:

```python
# Internamente en Aurora, cada llamada a Claude se hace así:
env['CLAUDE_CONFIG_DIR'] = '/home/usuario/.local/share/aurora/accounts/account2'
subprocess.Popen(['claude', '--print', '--verbose', ...], env=env)
```

De esta forma, **cada cuenta vive en su propio directorio con sus propias credenciales**, y Aurora puede alternar entre ellas simplemente cambiando la variable de entorno antes de lanzar el proceso. No hay ningún hack ni ingeniería inversa — es el comportamiento oficial del CLI.

```
~/.local/share/aurora/accounts/
├── account1/              ← Cuenta 2 (carpeta aislada)
│   └── .credentials.json  ← token OAuth de esa cuenta
├── account2/              ← Cuenta 3
│   └── .credentials.json
└── ...
La Cuenta 1 usa ~/.claude (la instalación original del CLI)
```

### Cómo vincular una cuenta nueva

**Paso 1**: Abre Aurora → **⚙ Configuración** → pestaña **Cuentas**

**Paso 2**: Escribe un nombre para identificar la nueva cuenta (ej. `Trabajo`, `Personal 2`, `Equipo`).

**Paso 3**: Aurora genera el comando exacto que debes ejecutar en una terminal, con la carpeta destino ya calculada:
```bash
CLAUDE_CONFIG_DIR=~/.local/share/aurora/accounts/account2 claude login
```

**Paso 4**: Abre una terminal, pega ese comando y ejecútalo. Claude CLI abrirá su flujo de autenticación normal (navegador o código). Inicia sesión con la **segunda cuenta** de Claude — las credenciales quedarán guardadas en esa carpeta aislada, sin tocar tu cuenta principal en `~/.claude`.

**Paso 5**: Vuelve a Aurora y presiona **"✔ Verificar y agregar cuenta"**. Aurora lee el `.credentials.json` de esa carpeta y comprueba que el token sea válido. Si está bien, la cuenta aparece en la lista inmediatamente.

**Paso 6**: Repite para cada cuenta adicional que quieras agregar.

### Panel de cuentas
Cada cuenta muestra:
- **● Amarillo** — cuenta actualmente en uso
- **● Cyan** — cuenta disponible y activa
- **● Rojo** — cuenta agotada (en cooldown)
- **● Gris** — cuenta deshabilitada manualmente
- El **plan** (Pro, Free, etc.) leído directamente del token
- El **tiempo restante** de cooldown si está agotada (ej. `agotada 47 min`)
- Botón **Usar** para cambiar a esa cuenta manualmente
- Botón **Resetear** para quitar el cooldown anticipadamente
- Botón **✕** para eliminar la cuenta

### Failover automático
Cuando está activado (Configuración → Cuentas → "Failover automático"):

1. Aurora intenta la cuenta activa
2. Si Claude CLI responde con un error de rate limit / tokens agotados, Aurora:
   - Marca esa cuenta como `depleted_until = ahora + 1 hora`
   - Guarda ese estado en `config.json`
   - **Pasa a la siguiente cuenta disponible sin interrumpir la conversación**
   - Muestra un indicador `⚡ usando: Cuenta 2` en la barra de estado
3. La cuenta agotada se reactiva automáticamente después de 1 hora
4. Si **todas** las cuentas están agotadas, Aurora muestra el error `Todas las cuentas están agotadas`

El `session_id` de la conversación se mantiene durante el failover — Claude retiene el contexto de la conversación aunque cambie la cuenta.

### Palabras clave de rate limit detectadas
Aurora reconoce los siguientes patrones como señal de que una cuenta está agotada:
- `rate limit`
- `too many requests`
- `quota exceeded`
- `usage limit`
- `429`

---

## Barra de compactación

Cuando Claude CLI necesita compactar el contexto de la conversación (resumir mensajes anteriores para liberar espacio de contexto), Aurora muestra una **barra animada cyberpunk** en la parte superior del chat:

```
◈  COMPACTANDO MEMORIA NEURAL  ◈
[████████░░░░░░░░░░░░]
█ ░ █ ░ █ █ ░ █ ░ ░ █ █
```

- La barra hace **bouncing** de izquierda a derecha
- Los 12 bloques inferiores parpadean con **opacidad aleatoria** para simular actividad
- Se actualiza cada 60ms
- Desaparece automáticamente cuando Claude termina la compactación

Técnicamente: Aurora usa `--output-format stream-json` con `--verbose` para recibir eventos JSON de Claude CLI en tiempo real. Cuando detecta un evento cuyo `type` o `subtype` contiene `compact`, activa la barra.

---

## Historial de conversaciones

Todas las conversaciones se guardan automáticamente en:
```
~/.local/share/aurora/conversations/
├── 20260612_143022_001234.json
├── 20260612_091155_005678.json
└── ...
```

Cada archivo JSON contiene:
```json
{
  "id": "20260612_143022_001234",
  "title": "Primeros 55 caracteres del primer mensaje",
  "created": "2026-06-12T14:30:22.001234",
  "session_id": "abc123...",
  "messages": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

El `session_id` es el ID de sesión de Claude CLI. Al cargar una conversación, Aurora pasa `--resume <session_id>` al CLI para retomar el contexto de Claude (no solo el historial visual).

### Interfaz del historial
- **Buscador en tiempo real** — filtra por título mientras escribes
- **Hover sobre una conversación** → aparecen dos botones:
  - **✎ Renombrar** — abre un mini diálogo con el nombre actual pre-cargado
  - **✕ Eliminar** — pide confirmación antes de borrar permanentemente

---

## Configuración

Abre con el botón **⚙** en el header. El panel tiene 6 pestañas:

### Identidad
- Nombre del asistente (por defecto: "Aurora")
- Nombre del usuario (por defecto: "Tú")
- Avatar del asistente — imagen personalizada o ícono por defecto
- Avatar del usuario — inicial del nombre o imagen personalizada

### Personalidad
- Campo de texto libre para el **system prompt** del asistente
- Define el tono, idioma, rol y comportamiento de Claude
- Se pasa a Claude CLI con `--append-system-prompt`

### Modelo
- Selección del modelo Claude a usar:
  - Predeterminado del CLI
  - claude-sonnet-4-5, claude-opus-4-5, claude-haiku-4-5, etc.
- Se pasa con `--model` al CLI

### Apariencia
- **Color accent** — el color principal de la interfaz (amarillo, cyan, verde, etc.)
- **Opacidad de ventana** — 10% a 100% (solo aplica si no hay blur de fondo)
- **Tamaño de fuente** — del chat
- **Velocidad de animación** — caracteres por tick del typewriter
- **Mostrar timestamps** — hora en cada mensaje

### Cuentas
- Lista de cuentas vinculadas con estado en tiempo real
- Toggle de failover automático
- Sección para vincular nuevas cuentas (ver [Multi-cuenta](#multi-cuenta-claude))

### Sistema
| Opción | Descripción |
|---|---|
| Hotkey global | Activa/desactiva `Ctrl+Alt+Space` |
| Monitor de portapapeles | Activa/desactiva la detección de texto copiado |
| Mínimo de caracteres | Umbral para activar el banner del portapapeles |
| Drag & Drop | Activa/desactiva arrastrar archivos al chat |
| Stats del sistema | Muestra/oculta la barra de CPU/RAM/red |
| Notificaciones | Activa/desactiva notificaciones de escritorio |
| Animación de arranque | Muestra/oculta la animación cyberpunk al iniciar |

La configuración se guarda en `~/.local/share/aurora/config.json`.

---

## Exportar conversación

El botón **↓** en el header exporta la conversación activa como Markdown con dos opciones:
- **Copiar Markdown** — lo pone en el portapapeles
- **Guardar archivo** — abre un diálogo para guardar como `.md` con nombre automático basado en la fecha y título

Formato del archivo exportado:
```markdown
# Título de la conversación
*Exportado desde Aurora — 2026-06-12 14:30*

---

**Tú:** [mensaje del usuario]

**Aurora:** [respuesta de Claude]

---
```

---

## Estructura del proyecto

```
aurora-v1/
├── aurora              # Script principal Python (~3100 líneas)
├── aurora.svg          # Ícono de la aplicación (usado en autostart y por defecto)
├── aurora_avatar.svg   # Avatar SVG por defecto del asistente
├── aurora.desktop      # Entrada XDG para autostart al iniciar sesión
├── install.sh          # Script de instalación automatizada
├── .gitignore          # Excluye config.json, venv, conversations, accounts
└── README.md           # Este archivo
```

### Datos generados en tiempo de ejecución (NO incluidos en el repo)
```
~/.local/share/aurora/
├── config.json             # Configuración + tokens de cuentas — NO compartir
├── conversations/          # Historial de conversaciones
├── accounts/               # Directorios CLAUDE_CONFIG_DIR por cuenta
│   ├── account1/
│   │   └── .credentials.json
│   └── account2/
│       └── .credentials.json
└── venv/                   # Entorno virtual Python
```

---

## Tecnologías

| Tecnología | Uso |
|---|---|
| **Python 3** | Lenguaje principal del script |
| **GTK3 / PyGObject** | Toda la interfaz gráfica |
| **Cairo** | Ventana transparente con esquinas redondeadas y barra de compactación |
| **GdkPixbuf** | Carga y escalado de avatares e imágenes |
| **Xlib (python-xlib)** | Registro de hotkey global vía `XGrabKey` |
| **psutil** | CPU, RAM y velocidad de red en tiempo real |
| **PIL / Pillow** | Blur gaussiano de la captura de escritorio |
| **ffmpeg** | Captura de región del escritorio (`x11grab`) para blur de ventana |
| **scrot** | Captura de pantalla completa para análisis con Claude |
| **Claude CLI** | Motor de IA — se llama con `subprocess.Popen` y `--output-format stream-json` |
| **libnotify / GNotify** | Notificaciones nativas de escritorio |

---

## Limitaciones v1

- **Solo X11** — Wayland no soportado (Xlib, ffmpeg x11grab, scrot)
- **Linux Mint / Cinnamon** — probado principalmente en este entorno; otras distros pueden necesitar ajustes de dependencias
- **Claude CLI requerido** — Aurora no llama a la API de Anthropic directamente, usa el CLI
- El blur de ventana puede mostrar un frame negro en el instante de apertura si el escritorio es muy complejo
- La detección de compactación depende del protocolo `stream-json` del CLI; si Anthropic cambia el formato puede requerir actualización
- El hotkey `Ctrl+Alt+Space` puede conflictar con aplicaciones que ya lo tengan registrado (ej. algunos IDEs)

---

## Licencia

[MIT](LICENSE) — úsalo, modifícalo y distribúyelo libremente.

---

> Construido con [Claude Code](https://claude.ai/code) sobre Linux Mint.
