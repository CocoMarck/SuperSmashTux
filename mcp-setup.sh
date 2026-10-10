#!/usr/bin/env bash
# ============================================================
#  mcp-setup.sh
#  Configura el servidor MCP de Blender para uno o varios
#  agentes de codigo, y genera su archivo de configuracion:
#
#    Claude Code -> .mcp.json
#    OpenCode    -> opencode.json
#    Codex CLI   -> .codex\config.toml
#
#  Servidor:
#    blender -> MCP oficial de Blender (uvx + add-on)
#
#  El MCP de Godot (Godot AI) no se configura aqui: es un plugin
#  en addons/godot_ai que se conecta desde su panel en el editor
#  (ver README).
#
#  Uso:
#    mcp-setup.sh                         -> menu interactivo
#    mcp-setup.sh <agentes> [blender_bin]
#
#    <agentes>: claude | opencode | codex | all
#               (o una lista separada por "+", ej: claude+codex)
#
#  Ejemplos:
#    mcp-setup.sh all
#    mcp-setup.sh opencode /opt/blender/blender
# ============================================================

set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
TARGET_CLAUDE="${PROJECT_DIR}.mcp.json"
TARGET_OPENCODE="${PROJECT_DIR}opencode.json"
TARGET_CODEX_DIR="${PROJECT_DIR}.codex"
TARGET_CODEX="${TARGET_CODEX_DIR}/config.toml"

BLENDER_EXE=""
BCOUNT=0
BEST_VER=0

BLENDER_JSON=""
BLENDER_JSON_CLAUDE=""
BLENDER_JSON_OPENCODE=""
BLENDER_JSON_CODEX=""

DO_CLAUDE=""
DO_OPENCODE=""
DO_CODEX=""

# ============================================================
#  Subrutinas (definidas antes del codigo principal para que
#  bash las conozca al momento de llamarlas)
# ============================================================

# addbcand <ruta>  -> agrega candidato de Blender sin duplicados
addbcand() {
    [ -n "$1" ] || return 0
    local i
    for i in $(seq 1 "$BCOUNT"); do
        eval "if [ \"\$BCAND_$i\" = \"$1\" ]; then return 0; fi"
    done
    BCOUNT=$((BCOUNT+1))
    eval "BCAND_$BCOUNT=\"$1\""
    echo "  [$BCOUNT] $1"
}

# scanb <carpeta>  -> busca el binario "blender" (o blender.exe)
#  recursivamente. El nombre exacto deja fuera a blender-launcher.
scanb() {
    local dir="$1" f
    [ -n "$dir" ] || return 0
    [ -d "$dir" ] || return 0
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        case "$f" in
            *blender-launcher*) continue ;;
        esac
        addbcand "$f"
    done < <(find "$dir" -type f \( -name "blender" -o -name "blender.exe" \) 2>/dev/null)
}

# verbest <ruta>  -> se queda con la version mas alta de Blender
#  "blender --version" imprime "Blender 5.2.1 LTS"; se compone un
#  entero major*100+minor para poder comparar (5.2 -> 502).
verbest() {
    [ -n "$1" ] || return 0
    local bin="$1" vstr="" vma vmi vnum
    if [[ "$bin" == flatpak* ]]; then
        vstr="$($bin --version 2>/dev/null | head -n1)"
    else
        [ -x "$bin" ] || return 0
        vstr="$("$bin" --version 2>/dev/null | head -n1)"
    fi
    [ -n "$vstr" ] || return 0
    vstr="$(echo "$vstr" | awk '{print $2}')"
    [ -n "$vstr" ] || return 0
    vma="${vstr%%.*}"
    vmi="${vstr#*.}"
    vmi="${vmi%%.*}"
    if [ -z "$vma" ]; then return 0; fi
    vnum=$((vma*100 + ${vmi:-0}))
    if [ "$vnum" -le "$BEST_VER" ]; then return 0; fi
    BEST_VER="$vnum"
    BLENDER_EXE="$bin"
}

# write_claude -> escribe .mcp.json
write_claude() {
    if [ -z "$BLENDER_JSON_CLAUDE" ]; then
        echo
        echo "[AVISO] Claude Code: nada que escribir en .mcp.json."
        return 0
    fi
    {
        echo "{"
        echo "  \"mcpServers\": {"
        # mcp[cli]<2: el pyproject oficial pide "mcp>=1.2.0" sin tope y
        # mcp 2.x renombro FastMCP, rompiendo el servidor.
        echo "    \"blender\": {"
        echo "      \"command\": \"uvx\","
        echo "      \"args\": ["
        echo "        \"--refresh\","
        echo "        \"--with\","
        echo "        \"mcp[cli]<2\","
        echo "        \"--from\","
        echo "        \"git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp\","
        echo "        \"blender-mcp\""
        echo "      ],"
        echo "      \"env\": {"
        echo "        \"BLENDER_MCP_HOST\": \"localhost\","
        echo "        \"BLENDER_MCP_PORT\": \"9876\","
        echo "        \"BLENDER_PATH\": \"$BLENDER_JSON_CLAUDE\""
        echo "      }"
        echo "    }"
        echo "  }"
        echo "}"
    } > "$TARGET_CLAUDE"
    echo "  [OK] Claude Code -> .mcp.json"
}

# write_opencode -> escribe opencode.json
write_opencode() {
    if [ -z "$BLENDER_JSON_OPENCODE" ]; then
        echo
        echo "[AVISO] OpenCode: nada que escribir en opencode.json."
        return 0
    fi
    {
        echo "{"
        echo "  \"mcp\": {"
        echo "    \"blender\": {"
        echo "      \"type\": \"local\","
        echo "      \"command\": [\"uvx\", \"--refresh\", \"--with\", \"mcp[cli]<2\", \"--from\", \"git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp\", \"blender-mcp\"],"
        echo "      \"environment\": {"
        echo "        \"BLENDER_MCP_HOST\": \"localhost\","
        echo "        \"BLENDER_MCP_PORT\": \"9876\","
        echo "        \"BLENDER_PATH\": \"$BLENDER_JSON_OPENCODE\""
        echo "      }"
        echo "    }"
        echo "  }"
        echo "}"
    } > "$TARGET_OPENCODE"
    echo "  [OK] OpenCode   -> opencode.json"
}

# write_codex -> escribe .codex/config.toml
write_codex() {
    if [ -z "$BLENDER_JSON_CODEX" ]; then
        echo
        echo "[AVISO] Codex: nada que escribir en .codex/config.toml."
        return 0
    fi
    mkdir -p "$TARGET_CODEX_DIR"
    {
        echo "# Generado por mcp-setup.sh"
        echo
        echo "[mcp_servers.blender]"
        echo "command = \"uvx\""
        echo "args = [\"--refresh\", \"--with\", \"mcp[cli]<2\", \"--from\", \"git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp\", \"blender-mcp\"]"
        echo
        echo "[mcp_servers.blender.env]"
        echo "BLENDER_MCP_HOST = \"localhost\""
        echo "BLENDER_MCP_PORT = \"9876\""
        echo "BLENDER_PATH = \"$BLENDER_JSON_CODEX\""
    } > "$TARGET_CODEX"
    echo "  [OK] Codex      -> .codex/config.toml"
    echo "       (Codex solo carga config de proyecto si esta marcado \"trusted\")"
}

# ============================================================
#  Codigo principal
# ============================================================

# En bash las rutas van con "/" asi que no hay que escapar nada,
# siendo una de las grandes simplificaciones frente al .bat original,
# que tenia que duplicar cada barra invertida para JSON/TOML.

echo
echo "=== Setup MCP - Super Smash Tux ==="
echo "Proyecto: ${PROJECT_DIR}"
echo
echo "[AVISO] Este port a .sh NO ha sido probado por humanos;"
echo "        puede que este roto en algun(os) flujo(s) (deteccion"
echo "        de bins, menu interactivo, add-on de Blender, etc.)."
echo "        Revisalo con calma antes de darle uso real."
echo
echo "        Ademas, este script NO usa sudo por diseno; instala"
echo "        uv en ~/.local/bin. Si vieras un sudo, es un error:"
echo "        reportalo, no lo ejecutes a ciegas."
echo

# ============================================================
#  MODO PARAMETROS (no interactivo)
# ============================================================
AGENTS_RAW="${1:-}"
BLENDER_ARG="${2:-}"
if [ -n "$AGENTS_RAW" ]; then
    AGENTS_LIST="${AGENTS_RAW//+/ }"
    AGENTS_ERR=""
    for T in $AGENTS_LIST; do
        TOKOK=""
        case "$T" in
            all)      DO_CLAUDE=1; DO_OPENCODE=1; DO_CODEX=1; TOKOK=1 ;;
            claude)   DO_CLAUDE=1; TOKOK=1 ;;
            opencode) DO_OPENCODE=1; TOKOK=1 ;;
            codex)    DO_CODEX=1; TOKOK=1 ;;
        esac
        if [ -z "$TOKOK" ]; then AGENTS_ERR=1; fi
    done
    if [ -n "$AGENTS_ERR" ] || { [ -z "$DO_CLAUDE" ] && [ -z "$DO_OPENCODE" ] && [ -z "$DO_CODEX" ]; }; then
        echo
        echo "[ERROR] Agente(s) invalido(s): \"$AGENTS_RAW\""
        echo "        Valores validos: claude, opencode, codex, all"
        echo "        o una lista separada por \"+\", ej: claude+codex"
        echo
        echo "Uso: mcp-setup.sh <agentes> [ruta_blender]"
        echo
        exit 1
    fi
else
    # ============================================================
    #  MENU INTERACTIVO - PASO 1: agente(s)
    # ============================================================
    TRIES=0
    while :; do
        echo
        echo "Que agente(s) deseas configurar?"
        echo
        echo "  [1] Todos (Claude Code, OpenCode, Codex)"
        echo "  [2] Solo Claude Code (.mcp.json)"
        echo "  [3] Solo OpenCode    (opencode.json)"
        echo "  [4] Solo Codex       (.codex/config.toml)"
        echo "  [5] Salir sin cambios"
        echo
        read -rp "Opcion [1-5]: " OPCION || { echo; exit 1; }
        OPCION="${OPCION//\"/}"
        OPCION="${OPCION// }"
        case "$OPCION" in
            1) DO_CLAUDE=1; DO_OPENCODE=1; DO_CODEX=1; break ;;
            2) DO_CLAUDE=1; break ;;
            3) DO_OPENCODE=1; break ;;
            4) DO_CODEX=1; break ;;
            5) exit 0 ;;
            *)
                TRIES=$((TRIES+1))
                if [ "$TRIES" -ge 5 ]; then
                    echo
                    echo "[FALLO] Demasiadas opciones invalidas. No se modifico ningun archivo."
                    echo
                    exit 1
                fi
                echo
                echo "[ERROR] Opcion invalida. Escribe un numero del 1 al 5 y pulsa Enter."
                ;;
        esac
    done
fi

# ============================================================
#  PARTE 1 - BLENDER
#  El MCP oficial de Blender son DOS piezas que hablan por
#  socket TCP: el add-on dentro de Blender (puerto 9876) y el
#  servidor "blender-mcp", que lanza el cliente MCP por stdio.
# ============================================================
echo
echo "=== Blender MCP ==="

# ---- 1) Ruta binaria pasada por parametro ------------------
if [ -n "$BLENDER_ARG" ]; then
    if [ -x "$BLENDER_ARG" ]; then
        BLENDER_EXE="$BLENDER_ARG"
        echo "[OK] Ruta de Blender indicada por parametro."
    else
        echo "[AVISO] La ruta de Blender indicada no existe o no es ejecutable: $BLENDER_ARG"
    fi
# ---- 2) Variable de entorno BLENDER_PATH -------------------
elif [ -n "${BLENDER_PATH:-}" ] && [ -x "$BLENDER_PATH" ]; then
    BLENDER_EXE="$BLENDER_PATH"
    echo "[OK] Encontrado en la variable de entorno BLENDER_PATH."
fi

# ---- 3) PATH y carpetas habituales -------------------------
if [ -z "$BLENDER_EXE" ]; then
    echo "Buscando Blender..."
    b="$(command -v blender 2>/dev/null)"
    [ -n "$b" ] && addbcand "$b"

    scanb "/usr/local/bin"
    scanb "/usr/bin"
    scanb "/opt/Blender"
    scanb "/opt"
    scanb "$HOME/Blender"
    scanb "$HOME/.local/bin"
    scanb "$HOME/Downloads"

    if command -v snap >/dev/null 2>&1; then
        [ -x /snap/bin/blender ] && addbcand /snap/bin/blender
    fi
    if command -v flatpak >/dev/null 2>&1; then
        fp="$(flatpak list --app --columns=application 2>/dev/null | grep -i '^org.blender.Blender' | head -n1)"
        [ -n "$fp" ] && addbcand "flatpak run $fp"
    fi

    if [ "$BCOUNT" -eq 0 ]; then
        echo "[AVISO] No se encontro Blender. Se omite su servidor MCP."
        echo "        Instala Blender 5.1+ y vuelve a ejecutar este script para agregarlo."
        BLENDER_EXE=""
    else
        # ---- 4) Quedarse con la version mas alta -----------
        for i in $(seq 1 "$BCOUNT"); do
            eval "verbest \"\$BCAND_$i\""
        done
        if [ -z "$BLENDER_EXE" ]; then
            echo "[AVISO] No se encontro Blender. Se omite su servidor MCP."
            echo "        Instala Blender 5.1+ y vuelve a ejecutar este script para agregarlo."
        else
            echo "[OK] Blender encontrado: $BLENDER_EXE"
        fi
    fi
fi

# ---- 5) Chequeo de version (el add-on pide 5.1 o mayor) ----
if [ -n "$BLENDER_EXE" ]; then
    BEST_VER=0
    verbest "$BLENDER_EXE"
    if [ -z "$BLENDER_EXE" ]; then
        echo "[AVISO] No se encontro Blender. Se omite su servidor MCP."
    elif [ "$BEST_VER" -lt 501 ]; then
        echo "[AVISO] El add-on MCP oficial necesita Blender 5.1 o superior."
        echo "        Version detectada demasiado vieja. Se omite el MCP de Blender."
        BLENDER_EXE=""
    fi
fi

# ---- 6) uv: es quien lanza el servidor blender-mcp ---------
if [ -n "$BLENDER_EXE" ]; then
    if command -v uv >/dev/null 2>&1; then
        echo "[OK] uv ya esta instalado."
    else
        echo
        echo "[FALTA] \"uv\" no esta instalado. Es necesario para lanzar el servidor MCP."
        while :; do
            read -rp "Instalarlo ahora en ~/.local/bin (sin sudo)? [S/N]: " YN
            case "${YN:-}" in
                s|S|y|Y) YN=y; break ;;
                n|N) YN=n; break ;;
                *) echo "[ERROR] Responde S o N." ;;
            esac
        done
        if [ "$YN" = "n" ]; then
            echo "[AVISO] Sin uv el servidor MCP de Blender no va a arrancar."
            echo "        Puedes instalarlo despues con: curl -LsSf https://astral.sh/uv/install.sh | sh"
        else
            echo "Instalando uv en ~/.local/bin..."
            if curl -LsSf https://astral.sh/uv/install.sh | sh; then
                if command -v uv >/dev/null 2>&1; then
                    echo "[OK] uv instalado."
                else
                    echo "[OK] uv instalado. Abre una consola nueva para que quede en el PATH;"
                    echo "    los archivos se generan igual."
                fi
            else
                echo "[AVISO] Error al instalar uv."
                echo "        Instalalo despues con: curl -LsSf https://astral.sh/uv/install.sh | sh"
                echo "        o con tu gestor de paquetes (sin sudo si es necesario)."
            fi
        fi
    fi
fi

# ---- 7) Add-on MCP dentro de Blender ----------------------
if [ -n "$BLENDER_EXE" ]; then
    BLENDER_JSON="$BLENDER_EXE"
    [ -n "$DO_CLAUDE" ] && BLENDER_JSON_CLAUDE="$BLENDER_JSON"
    [ -n "$DO_OPENCODE" ] && BLENDER_JSON_OPENCODE="$BLENDER_JSON"
    [ -n "$DO_CODEX" ] && BLENDER_JSON_CODEX="$BLENDER_JSON"

    # Se omite la verificacion de "Blender abierto" cuando se
    # resuelve via flatpak, ya que no se puede inspeccionar el
    # binario directamente.
    if [[ "$BLENDER_EXE" != flatpak* ]] && pgrep -x blender >/dev/null 2>&1; then
        echo
        echo "[AVISO] Hay procesos de Blender abiertos. Instalar el add-on ahora no serviria:"
        echo "        al cerrarse, esa instancia pisa las preferencias y se pierde."
        echo "        Cierra Blender y vuelve a ejecutar este script."
    else
        echo "Configurando el add-on MCP en Blender..."
        # El repo solo se agrega si no existe, para no duplicarlo en cada corrida.
        if "$BLENDER_EXE" --command extension repo-list 2>/dev/null | grep -q "lab_blender_org:"; then
            echo "  Repositorio \"Blender Lab\" ya estaba configurado."
        else
            "$BLENDER_EXE" --command extension repo-add lab_blender_org --name "Blender Lab" --url "https://lab.blender.org/" >/dev/null 2>&1
            echo "  Repositorio \"Blender Lab\" agregado."
        fi
        # --online-mode: sin el, sync falla si el acceso en linea esta
        # apagado en las preferencias (es lo normal en una instalacion nueva).
        "$BLENDER_EXE" --online-mode --command extension sync >/dev/null 2>&1
        "$BLENDER_EXE" --online-mode --command extension install lab_blender_org.mcp --enable >/dev/null 2>&1
        if "$BLENDER_EXE" --command extension list 2>/dev/null | grep -q "mcp \[installed\]"; then
            echo "  [OK] Add-on MCP instalado y habilitado (auto-start en localhost:9876)."
        else
            echo "  [AVISO] No se pudo confirmar la instalacion del add-on."
            echo "          Instalacion manual: Edit > Preferences > Get Extensions,"
            echo "          agrega el repositorio https://lab.blender.org/ y busca \"MCP\"."
        fi
    fi
fi

# ============================================================
#  PARTE 2 - Escritura de la config de cada agente elegido
# ============================================================
if [ -z "$BLENDER_JSON_CLAUDE" ] && [ -z "$BLENDER_JSON_OPENCODE" ] && [ -z "$BLENDER_JSON_CODEX" ]; then
    echo
    echo "[FALLO] No hay ningun servidor que configurar."
    echo "        No se modifico ningun archivo."
    echo
    exit 1
fi

[ -n "$DO_CLAUDE" ] && write_claude
[ -n "$DO_OPENCODE" ] && write_opencode
[ -n "$DO_CODEX" ] && write_codex

echo
echo "[LISTO] Configuracion generada."
if [ -n "$DO_CLAUDE" ]; then
    if [ -n "$BLENDER_JSON_CLAUDE" ]; then echo "  Claude Code / blender | $BLENDER_JSON_CLAUDE"; else echo "  Claude Code / blender | sin configurar"; fi
fi
if [ -n "$DO_OPENCODE" ]; then
    if [ -n "$BLENDER_JSON_OPENCODE" ]; then echo "  OpenCode / blender    | $BLENDER_JSON_OPENCODE"; else echo "  OpenCode / blender    | sin configurar"; fi
fi
if [ -n "$DO_CODEX" ]; then
    if [ -n "$BLENDER_JSON_CODEX" ]; then echo "  Codex / blender       | $BLENDER_JSON_CODEX"; else echo "  Codex / blender       | sin configurar"; fi
fi

BLENDER_ANY=""
[ -n "$BLENDER_JSON_CLAUDE" ] && BLENDER_ANY=1
[ -n "$BLENDER_JSON_OPENCODE" ] && BLENDER_ANY=1
[ -n "$BLENDER_JSON_CODEX" ] && BLENDER_ANY=1
echo
if [ -n "$BLENDER_ANY" ]; then
    echo "Abre Blender antes de usar sus herramientas: el add-on levanta"
    echo "el servidor en localhost:9876 al arrancar."
fi
echo "Reinicia tu(s) agente(s) de codigo para que tomen la configuracion del MCP."
echo
exit 0
