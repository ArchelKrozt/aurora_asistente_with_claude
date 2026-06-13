#!/bin/bash
# ╔══════════════════════════════════════════════╗
# ║       Aurora v1 — Script de instalación      ║
# ╚══════════════════════════════════════════════╝
set -e

AURORA_DIR="$HOME/.local/share/aurora"
BIN_DIR="$HOME/.local/bin"
AUTOSTART_DIR="$HOME/.config/autostart"
VENV="$AURORA_DIR/venv"

echo ""
echo "  ◈ Instalando Aurora v1..."
echo ""

# 1. Crear directorios
mkdir -p "$AURORA_DIR" "$BIN_DIR" "$AUTOSTART_DIR"

# 2. Copiar archivos
cp aurora "$BIN_DIR/aurora"
chmod +x "$BIN_DIR/aurora"
cp aurora.svg aurora_avatar.svg "$AURORA_DIR/"

# 3. Crear entorno virtual Python
if [ ! -d "$VENV" ]; then
  echo "  ◈ Creando entorno virtual Python..."
  python3 -m venv --system-site-packages "$VENV"
fi

# 4. Instalar dependencias Python
echo "  ◈ Instalando dependencias Python..."
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet Pillow python-xlib psutil

# 5. Verificar dependencias del sistema
echo "  ◈ Verificando dependencias del sistema..."
MISSING=()
command -v ffmpeg   &>/dev/null || MISSING+=("ffmpeg")
command -v scrot    &>/dev/null || MISSING+=("scrot")
command -v claude   &>/dev/null || MISSING+=("claude (Claude CLI)")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo ""
  echo "  ⚠  Dependencias no encontradas: ${MISSING[*]}"
  echo "     Instala con: sudo apt install ffmpeg scrot"
  echo "     Claude CLI:  npm install -g @anthropic-ai/claude-code"
  echo ""
fi

# 6. Autostart
cp aurora.desktop "$AUTOSTART_DIR/aurora.desktop"
sed -i "s|Exec=.*|Exec=$VENV/bin/python3 $BIN_DIR/aurora|g" "$AUTOSTART_DIR/aurora.desktop"

# 7. (Opcional) NOPASSWD para comandos /sudo
echo ""
echo "  ◈ Para usar /sudo dentro de Aurora, ejecuta UNA VEZ:"
echo "     echo \"$USER ALL=(ALL) NOPASSWD: ALL\" | sudo tee /etc/sudoers.d/aurora-$USER && sudo chmod 440 /etc/sudoers.d/aurora-$USER"
echo ""

echo "  ✔ Aurora instalada correctamente."
echo "  ✔ Inicia con:  $VENV/bin/python3 $BIN_DIR/aurora &"
echo "  ✔ O reinicia sesión para el autostart."
echo ""
