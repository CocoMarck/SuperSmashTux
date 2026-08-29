#!/usr/bin/env bash
# ============================================================
#  mcp-setup.sh
#  Configura los servidores MCP del proyecto para uno o varios
#  agentes de codigo, y genera su archivo de configuracion:
#
#    Claude Code -> .mcp.json
#    OpenCode    -> opencode.json
#    Codex CLI   -> .codex\config.toml
#
#  Servidores disponibles:
#    godot   -> godot-mcp (npx), necesita Node.js 18+
#    blender -> MCP oficial de Blender (uvx + add-on)
#
#  Uso:
#    mcp-setup.sh                                    -> menu interactivo
#    mcp-setup.sh <agentes> [godot_bin] [blender_bin]
#
#    <agentes>: claude | opencode | codex | all
#               (o una lista separada por "+", ej: claude+codex)
#
#  Ejemplos:
#    mcp-setup.sh all
#    mcp-setup.sh claude+codex /usr/bin/godot
#    mcp-setup.sh opencode "" /opt/blender/blender
#
#  En modo interactivo, al elegir un solo servidor el otro se
#  conserva leyendo el archivo de cada agente que ya exista, para
#  no perder configuracion. En modo parametros siempre se
#  configuran ambos servidores para el/los agente(s) indicado(s).
# ============================================================

set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
TARGET_CLAUDE="${PROJECT_DIR}.mcp.json"
TARGET_OPENCODE="${PROJECT_DIR}opencode.json"
TARGET_CODEX_DIR="${PROJECT_DIR}.codex"
TARGET_CODEX="${TARGET_CODEX_DIR}/config.toml"

GODOT_EXE=""
BLENDER_EXE=""
COUNT=0
BCOUNT=0
BEST_VER=0

GODOT_JSON=""
BLENDER_JSON=""
GODOT_JSON_CLAUDE=""
GODOT_JSON_OPENCODE=""
GODOT_JSON_CODEX=""
BLENDER_JSON_CLAUDE=""
BLENDER_JSON_OPENCODE=""
BLENDER_JSON_CODEX=""

DO_GODOT=""
DO_BLENDER=""
DO_CLAUDE=""
DO_OPENCODE=""
DO_CODEX=""

# ============================================================
#  Subrutinas (definidas antes del codigo principal para que
#  bash las conozca al momento de llamarlas)
# ============================================================

# jsonget <clave> <archivo>  -> deja en JG_VAL el valor de esa clave
#  en un archivo JSON. Juega igual que en el .bat: busca la linea que
#  contiene la clave y extrae el valor entre comillas. Deja JG_DISP con
#  el valor sin las barras de escape (irrelevante en Linux, se conserva
#  por compatibilidad con la interfaz). Quedan vacias si no esta.
jsonget() {
    JG_VAL=""
    JG_DISP=""
    local KEY="$1" FILE="$2" LINE=""
    [ -f "$FILE" ] || return 0
    LINE="$(grep -i "\"$KEY\"" "$FILE" | tail -n1)"
    [ -n "$LINE" ] || return 0
    LINE="${LINE#*: }"
    LINE="${LINE//\"/}"
    LINE="${LINE//,/}"
    [ -n "$LINE" ] || return 0
    JG_VAL="$LINE"
    JG_DISP="$JG_VAL"
}

# tomlget <clave> <archivo>  -> igual que jsonget pero para lineas
#  TOML "CLAVE = \"valor\"" (sin comillas en la clave).
tomlget() {
    JG_VAL=""
    JG_DISP=""
    local KEY="$1" FILE="$2" LINE=""
    [ -f "$FILE" ] || return 0
    LINE="$(grep -i "^$KEY =" "$FILE" | tail -n1)"
    [ -n "$LINE" ] || return 0
    LINE="${LINE#*\"}"
    LINE="${LINE//\"/}"
    [ -n "$LINE" ] || return 0
    JG_VAL="$LINE"
    JG_DISP="$JG_VAL"
}

# addcand <ruta>  -> agrega candidato de Godot sin duplicados
addcand() {
    [ -n "$1" ] || return 0
    local i
    for i in $(seq 1 "$COUNT"); do
        eval "if [ \"\$CAND_$i\" = \"$1\" ]; then return 0; fi"
    done
    COUNT=$((COUNT+1))
    eval "CAND_$COUNT=\"$1\""
    echo "  [$COUNT] $1"
}

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

# scan <carpeta> <patron_base>  -> busca ejecutables de Godot
scan() {
    local dir="$1" pat="$2" f
    [ -n "$dir" ] || return 0
    [ -d "$dir" ] || return 0
    for f in "$dir"/$pat; do
        [ -e "$f" ] || continue
        case "$(basename "$f")" in
            *_console*) continue ;;
        esac
        [ -x "$f" ] && addcand "$f"
    done
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

# rescate_agente <NOMBRE> <archivo> <json|toml> <etiqueta>
#  Si un servidor no se va a reconfigurar en esta corrida (DO_GODOT o
#  DO_BLENDER sin definir), rescata su valor del propio archivo de ese
#  agente y lo deja en GODOT_JSON_<NOMBRE> / BLENDER_JSON_<NOMBRE>.
rescate_agente() {
    local NAME="$1" FILE="$2" FMT="$3" LABEL="$4"
    if [ -z "$DO_GODOT" ]; then
        if [ "$FMT" = "toml" ]; then tomlget "GODOT_PATH" "$FILE"; else jsonget "GODOT_PATH" "$FILE"; fi
        if [ -n "$JG_VAL" ]; then
            eval "GODOT_JSON_$NAME=\"\$JG_VAL\""
            echo "  [=] $LABEL: se conserva la configuracion de Godot existente."
        fi
    fi
    if [ -z "$DO_BLENDER" ]; then
        if [ "$FMT" = "toml" ]; then tomlget "BLENDER_PATH" "$FILE"; else jsonget "BLENDER_PATH" "$FILE"; fi
        if [ -n "$JG_VAL" ]; then
            eval "BLENDER_JSON_$NAME=\"\$JG_VAL\""
            echo "  [=] $LABEL: se conserva la configuracion de Blender existente."
        fi
    fi
}

# write_claude -> escribe .mcp.json
write_claude() {
    if [ -z "$GODOT_JSON_CLAUDE" ] && [ -z "$BLENDER_JSON_CLAUDE" ]; then
        echo
        echo "[AVISO] Claude Code: nada que escribir en .mcp.json."
        return 0
    fi
    {
        echo "{"
        echo "  \"mcpServers\": {"
        if [ -n "$GODOT_JSON_CLAUDE" ]; then
            echo "    \"godot\": {"
            echo "      \"command\": \"npx\","
            echo "      \"args\": [\"@coding-solo/godot-mcp\"],"
            echo "      \"env\": {"
            echo "        \"GODOT_PATH\": \"$GODOT_JSON_CLAUDE\""
            echo "      }"
            if [ -n "$BLENDER_JSON_CLAUDE" ]; then echo "    },"; else echo "    }"; fi
        fi
        if [ -n "$BLENDER_JSON_CLAUDE" ]; then
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
        fi
        echo "  }"
        echo "}"
    } > "$TARGET_CLAUDE"
    echo "  [OK] Claude Code -> .mcp.json"
}

# write_opencode -> escribe opencode.json
write_opencode() {
    if [ -z "$GODOT_JSON_OPENCODE" ] && [ -z "$BLENDER_JSON_OPENCODE" ]; then
        echo
        echo "[AVISO] OpenCode: nada que escribir en opencode.json."
        return 0
    fi
    {
        echo "{"
        echo "  \"mcp\": {"
        if [ -n "$GODOT_JSON_OPENCODE" ]; then
            echo "    \"godot\": {"
            echo "      \"type\": \"local\","
            echo "      \"command\": [\"npx\", \"@coding-solo/godot-mcp\"],"
            echo "      \"environment\": {"
            echo "        \"GODOT_PATH\": \"$GODOT_JSON_OPENCODE\""
            echo "      }"
            if [ -n "$BLENDER_JSON_OPENCODE" ]; then echo "    },"; else echo "    }"; fi
        fi
        if [ -n "$BLENDER_JSON_OPENCODE" ]; then
            echo "    \"blender\": {"
            echo "      \"type\": \"local\","
            echo "      \"command\": [\"uvx\", \"--refresh\", \"--with\", \"mcp[cli]<2\", \"--from\", \"git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp\", \"blender-mcp\"],"
            echo "      \"environment\": {"
            echo "        \"BLENDER_MCP_HOST\": \"localhost\","
            echo "        \"BLENDER_MCP_PORT\": \"9876\","
            echo "        \"BLENDER_PATH\": \"$BLENDER_JSON_OPENCODE\""
            echo "      }"
            echo "    }"
        fi
        echo "  }"
        echo "}"
    } > "$TARGET_OPENCODE"
    echo "  [OK] OpenCode   -> opencode.json"
}

# write_codex -> escribe .codex/config.toml
write_codex() {
    if [ -z "$GODOT_JSON_CODEX" ] && [ -z "$BLENDER_JSON_CODEX" ]; then
        echo
        echo "[AVISO] Codex: nada que escribir en .codex/config.toml."
        return 0
    fi
    mkdir -p "$TARGET_CODEX_DIR"
    {
        echo "# Generado por mcp-setup.sh"
        if [ -n "$GODOT_JSON_CODEX" ]; then
            echo
            echo "[mcp_servers.godot]"
            echo "command = \"npx\""
            echo "args = [\"@coding-solo/godot-mcp\"]"
            echo
            echo "[mcp_servers.godot.env]"
            echo "GODOT_PATH = \"$GODOT_JSON_CODEX\""
        fi
        if [ -n "$BLENDER_JSON_CODEX" ]; then
            echo
            echo "[mcp_servers.blender]"
            echo "command = \"uvx\""
            echo "args = [\"--refresh\", \"--with\", \"mcp[cli]<2\", \"--from\", \"git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp\", \"blender-mcp\"]"
            echo
            echo "[mcp_servers.blender.env]"
            echo "BLENDER_MCP_HOST = \"localhost\""
            echo "BLENDER_MCP_PORT = \"9876\""
            echo "BLENDER_PATH = \"$BLENDER_JSON_CODEX\""
        fi
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
BLENDER_ARG="${3:-}"
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
        echo "Uso: mcp-setup.sh <agentes> [ruta_godot] [ruta_blender]"
        echo
        exit 1
    fi
    DO_GODOT=1
    DO_BLENDER=1
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

    # ============================================================
    #  MENU INTERACTIVO - PASO 2: servidor(es)
    # ============================================================
    echo
    echo "Estado actual:"
    if [ -n "$DO_CLAUDE" ]; then
        jsonget "GODOT_PATH" "$TARGET_CLAUDE"
        if [ -n "$JG_VAL" ]; then echo "  [x] Claude Code / godot    | $JG_DISP"; else echo "  [ ] Claude Code / godot    | sin configurar"; fi
        jsonget "BLENDER_PATH" "$TARGET_CLAUDE"
        if [ -n "$JG_VAL" ]; then echo "  [x] Claude Code / blender  | $JG_DISP"; else echo "  [ ] Claude Code / blender  | sin configurar"; fi
    fi
    if [ -n "$DO_OPENCODE" ]; then
        jsonget "GODOT_PATH" "$TARGET_OPENCODE"
        if [ -n "$JG_VAL" ]; then echo "  [x] OpenCode / godot       | $JG_DISP"; else echo "  [ ] OpenCode / godot       | sin configurar"; fi
        jsonget "BLENDER_PATH" "$TARGET_OPENCODE"
        if [ -n "$JG_VAL" ]; then echo "  [x] OpenCode / blender     | $JG_DISP"; else echo "  [ ] OpenCode / blender     | sin configurar"; fi
    fi
    if [ -n "$DO_CODEX" ]; then
        tomlget "GODOT_PATH" "$TARGET_CODEX"
        if [ -n "$JG_VAL" ]; then echo "  [x] Codex / godot          | $JG_DISP"; else echo "  [ ] Codex / godot          | sin configurar"; fi
        tomlget "BLENDER_PATH" "$TARGET_CODEX"
        if [ -n "$JG_VAL" ]; then echo "  [x] Codex / blender        | $JG_DISP"; else echo "  [ ] Codex / blender        | sin configurar"; fi
    fi

    TRIES=0
    while :; do
        echo
        echo "Que deseas configurar?"
        echo
        echo "  [1] Godot y Blender"
        echo "  [2] Solo Godot     (godot-mcp, necesita Node.js 18+)"
        echo "  [3] Solo Blender   (MCP oficial, necesita Blender 5.1+)"
        echo "  [4] Salir sin cambios"
        echo
        read -rp "Opcion [1-4]: " OPCION || { echo; exit 1; }
        OPCION="${OPCION//\"/}"
        OPCION="${OPCION// }"
        case "$OPCION" in
            1) DO_GODOT=1; DO_BLENDER=1; break ;;
            2) DO_GODOT=1; break ;;
            3) DO_BLENDER=1; break ;;
            4) DO_CLAUDE=""; DO_OPENCODE=""; DO_CODEX=""; break ;;
            *)
                TRIES=$((TRIES+1))
                if [ "$TRIES" -ge 5 ]; then
                    echo
                    echo "[FALLO] Demasiadas opciones invalidas. No se modifico ningun archivo."
                    echo
                    exit 1
                fi
                echo
                echo "[ERROR] Opcion invalida. Escribe un numero del 1 al 4 y pulsa Enter."
                ;;
        esac
    done
    if [ -z "$DO_CLAUDE" ] && [ -z "$DO_OPENCODE" ] && [ -z "$DO_CODEX" ]; then
        exit 0
    fi
fi

# ---- Lo que no se reconfigura se rescata del archivo de cada agente --
if [ -n "$DO_CLAUDE" ]; then rescate_agente CLAUDE "$TARGET_CLAUDE" json "Claude Code"; fi
if [ -n "$DO_OPENCODE" ]; then rescate_agente OPENCODE "$TARGET_OPENCODE" json "OpenCode"; fi
if [ -n "$DO_CODEX" ]; then rescate_agente CODEX "$TARGET_CODEX" toml "Codex"; fi

# ============================================================
#  PARTE 1 - GODOT
# ============================================================
if [ -n "$DO_GODOT" ]; then

    echo
    echo "=== Godot MCP ==="

    # ---- 1) Ruta binaria pasada por parametro ------------------
    if [ -n "${2:-}" ]; then
        if [ -x "${2}" ]; then
            GODOT_EXE="${2}"
            echo "[OK] Ruta de Godot indicada por parametro."
        else
            echo "[ERROR] La ruta indicada no existe o no es ejecutable: ${2}"
            echo
            echo "[FALLO] No se genero la configuracion."
            echo
            exit 1
        fi
    # ---- 2) Variable de entorno GODOT_PATH ---------------------
    elif [ -n "${GODOT_PATH:-}" ] && [ -x "$GODOT_PATH" ]; then
        GODOT_EXE="$GODOT_PATH"
        echo "[OK] Encontrado en la variable de entorno GODOT_PATH."
    else
        # ---- 3) Godot dentro del PATH --------------------------
        echo "Buscando Godot en el PATH..."
        for name in godot godot4; do
            cand="$(command -v "$name" 2>/dev/null)"
            [ -n "$cand" ] && addcand "$cand"
        done

        # ---- 4) Carpetas habituales en Linux --------------------
        echo "Buscando en carpetas habituales..."
        scan "/usr/local/bin" "Godot*"
        scan "/usr/bin" "Godot*"
        scan "/opt" "Godot*"
        scan "$HOME/Godot" "Godot*"
        scan "$HOME/.local/bin" "Godot*"
        scan "$HOME/.godot" "Godot*"
        scan "$HOME/Downloads" "Godot*"
        scan "$HOME/Documents" "Godot*"

        # Snap / Flatpak solo si estan disponibles
        if command -v snap >/dev/null 2>&1; then
            for p in /snap/bin/godot /snap/bin/godot4; do
                [ -x "$p" ] && addcand "$p"
            done
        fi
        if command -v flatpak >/dev/null 2>&1; then
            fp="$(flatpak list --app --columns=application 2>/dev/null | grep -i '^org.godotengine' | head -n1)"
            [ -n "$fp" ] && addcand "flatpak run $fp"
        fi

        # AppImages dentro del HOME (no ejecutar, solo candidato)
        for app in "$HOME"/Godot*.AppImage "$HOME"/Downloads/Godot*.AppImage; do
            [ -e "$app" ] && addcand "$app"
        done

        if [ "$COUNT" -eq 0 ]; then
            # ---- 5) Entrada manual -----------------------------
            echo
            echo "No se pudo detectar Godot automaticamente."
            read -rp "Escribe la ruta completa al ejecutable de Godot: " ME
            ME="${ME//\"/}"
            if [ -z "$ME" ]; then
                echo
                echo "[FALLO] No se genero la configuracion."
                echo
                exit 1
            fi
            if [ ! -x "$ME" ]; then
                echo "[ERROR] La ruta no existe o no es ejecutable: $ME"
                echo
                echo "[FALLO] No se genero la configuracion."
                echo
                exit 1
            fi
            GODOT_EXE="$ME"
        elif [ "$COUNT" -eq 1 ]; then
            GODOT_EXE="$CAND_1"
            echo
            echo "[OK] Godot encontrado: $GODOT_EXE"
        else
            # ---- 6) Seleccion cuando hay varios resultados ------
            echo
            echo "Se encontraron $COUNT ejecutables de Godot:"
            for i in $(seq 1 "$COUNT"); do
                eval "echo \"  [$i] \$CAND_$i\""
            done
            echo
            while :; do
                read -rp "Numero a usar (1-$COUNT): " PICK || { echo; exit 1; }
                if [ -n "$PICK" ] && eval "[ -n \"\$CAND_$PICK\" ]"; then
                    eval "GODOT_EXE=\"\$CAND_$PICK\""
                    break
                fi
                echo "[ERROR] Opcion invalida."
            done
        fi
    fi

    if [ ! -x "$GODOT_EXE" ]; then
        echo "[ERROR] El ejecutable no existe o no es ejecutable: $GODOT_EXE"
        echo
        echo "[FALLO] No se genero la configuracion."
        echo
        exit 1
    fi
    # Las rutas Linux van con "/", no hace falta escapar nada.
    GODOT_JSON="$GODOT_EXE"
    [ -n "$DO_CLAUDE" ] && GODOT_JSON_CLAUDE="$GODOT_JSON"
    [ -n "$DO_OPENCODE" ] && GODOT_JSON_OPENCODE="$GODOT_JSON"
    [ -n "$DO_CODEX" ] && GODOT_JSON_CODEX="$GODOT_JSON"
fi

# ============================================================
#  PARTE 2 - BLENDER
#  El MCP oficial de Blender son DOS piezas que hablan por
#  socket TCP: el add-on dentro de Blender (puerto 9876) y el
#  servidor "blender-mcp", que lanza el cliente MCP por stdio.
# ============================================================
if [ -n "$DO_BLENDER" ]; then

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
        if [[ "$BLENDER_EXE" != flatpak* ]] && pgrep -f "blender" >/dev/null 2>&1; then
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
            "$BLENDER_EXE" --command extension sync >/dev/null 2>&1
            "$BLENDER_EXE" --command extension install lab_blender_org.mcp --enable >/dev/null 2>&1
            if "$BLENDER_EXE" --command extension list 2>/dev/null | grep -q "mcp \[installed\]"; then
                echo "  [OK] Add-on MCP instalado y habilitado (auto-start en localhost:9876)."
            else
                echo "  [AVISO] No se pudo confirmar la instalacion del add-on."
                echo "          Instalacion manual: Edit > Preferences > Get Extensions,"
                echo "          agrega el repositorio https://lab.blender.org/ y busca \"MCP\"."
            fi
        fi
    fi
fi

# ============================================================
#  PARTE 3 - Escritura de la config de cada agente elegido
# ============================================================
if [ -z "$GODOT_JSON_CLAUDE" ] && [ -z "$GODOT_JSON_OPENCODE" ] && [ -z "$GODOT_JSON_CODEX" ] \
   && [ -z "$BLENDER_JSON_CLAUDE" ] && [ -z "$BLENDER_JSON_OPENCODE" ] && [ -z "$BLENDER_JSON_CODEX" ]; then
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
    if [ -n "$GODOT_JSON_CLAUDE" ]; then echo "  Claude Code / godot   | $GODOT_JSON_CLAUDE"; else echo "  Claude Code / godot   | sin configurar"; fi
    if [ -n "$BLENDER_JSON_CLAUDE" ]; then echo "  Claude Code / blender | $BLENDER_JSON_CLAUDE"; else echo "  Claude Code / blender | sin configurar"; fi
fi
if [ -n "$DO_OPENCODE" ]; then
    if [ -n "$GODOT_JSON_OPENCODE" ]; then echo "  OpenCode / godot      | $GODOT_JSON_OPENCODE"; else echo "  OpenCode / godot      | sin configurar"; fi
    if [ -n "$BLENDER_JSON_OPENCODE" ]; then echo "  OpenCode / blender    | $BLENDER_JSON_OPENCODE"; else echo "  OpenCode / blender    | sin configurar"; fi
fi
if [ -n "$DO_CODEX" ]; then
    if [ -n "$GODOT_JSON_CODEX" ]; then echo "  Codex / godot         | $GODOT_JSON_CODEX"; else echo "  Codex / godot         | sin configurar"; fi
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
