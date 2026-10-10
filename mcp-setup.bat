@echo off
setlocal EnableDelayedExpansion
title Setup MCP - Super Smash Tux

rem ============================================================
rem  mcp-setup.bat
rem  Configura el servidor MCP de Blender para uno o varios
rem  agentes de codigo, y genera su archivo de configuracion:
rem
rem    Claude Code -> .mcp.json
rem    OpenCode    -> opencode.json
rem    Codex CLI   -> .codex\config.toml
rem
rem  Servidor:
rem    blender -> MCP oficial de Blender (uvx + add-on)
rem
rem  El MCP de Godot (Godot AI) no se configura aqui: es un plugin
rem  en addons\godot_ai que se conecta desde su panel en el editor
rem  (ver README).
rem
rem  Uso:
rem    mcp-setup.bat                         -> menu interactivo
rem    mcp-setup.bat <agentes> [blender.exe]
rem
rem    <agentes>: claude | opencode | codex | all
rem               (o una lista separada por "+", ej: claude+codex)
rem               NOTA: no uses coma como separador - cmd.exe la trata
rem               como separador de argumentos y rompe el parseo.
rem
rem  Ejemplos:
rem    mcp-setup.bat all
rem    mcp-setup.bat opencode "D:\Blender\blender.exe"
rem ============================================================

set "PROJECT_DIR=%~dp0"
set "TARGET_CLAUDE=%PROJECT_DIR%.mcp.json"
set "TARGET_OPENCODE=%PROJECT_DIR%opencode.json"
set "TARGET_CODEX_DIR=%PROJECT_DIR%.codex"
set "TARGET_CODEX=%TARGET_CODEX_DIR%\config.toml"
set "BLENDER_EXE="
set "BCOUNT=0"
set "BEST_VER=0"

rem  Rutas ya escapadas para JSON/TOML (misma regla de escape en ambos:
rem  duplicar barras invertidas). Si quedan vacias, el servidor no se
rem  escribe para ese agente.
set "BLENDER_JSON="
set "BLENDER_JSON_CLAUDE="
set "BLENDER_JSON_OPENCODE="
set "BLENDER_JSON_CODEX="

set "DO_CLAUDE="
set "DO_OPENCODE="
set "DO_CODEX="

rem  "<" no se puede escribir directo en un echo redirigido: cmd lo toma
rem  como redireccion de entrada. Se expande tarde, via !LT!.
set LT=^<

echo.
echo === Setup MCP - Super Smash Tux ===
echo Proyecto: %PROJECT_DIR%

rem ============================================================
rem  MODO PARAMETROS (no interactivo)
rem ============================================================
set "AGENTS_RAW=%~1"
set "BLENDER_ARG=%~2"
if not defined AGENTS_RAW goto :menu_agentes

set "AGENTS_LIST=%AGENTS_RAW:+= %"
set "AGENTS_ERR="
for %%T in (%AGENTS_LIST%) do (
    set "TOKOK="
    if /i "%%T"=="all" (set "DO_CLAUDE=1" & set "DO_OPENCODE=1" & set "DO_CODEX=1" & set "TOKOK=1")
    if /i "%%T"=="claude" (set "DO_CLAUDE=1" & set "TOKOK=1")
    if /i "%%T"=="opencode" (set "DO_OPENCODE=1" & set "TOKOK=1")
    if /i "%%T"=="codex" (set "DO_CODEX=1" & set "TOKOK=1")
    if not defined TOKOK set "AGENTS_ERR=1"
)
if defined AGENTS_ERR goto :agentes_invalidos
if not defined DO_CLAUDE if not defined DO_OPENCODE if not defined DO_CODEX goto :agentes_invalidos

goto :inicio

:agentes_invalidos
echo.
echo [ERROR] Agente(s) invalido(s): "%AGENTS_RAW%"
echo         Valores validos: claude, opencode, codex, all
echo         o una lista separada por "+", ej: claude+codex
echo.
echo Uso: mcp-setup.bat ^<agentes^> [ruta_blender]
echo.
pause
endlocal
exit /b 1

rem ============================================================
rem  MENU INTERACTIVO - PASO 1: agente(s)
rem ============================================================
:menu_agentes
set /a TRIES=0

:menu_agentes_opciones
echo.
echo Que agente(s) deseas configurar?
echo.
echo   [1] Todos (Claude Code, OpenCode, Codex)
echo   [2] Solo Claude Code (.mcp.json)
echo   [3] Solo OpenCode    (opencode.json)
echo   [4] Solo Codex       (.codex\config.toml)
echo   [5] Salir sin cambios
echo.
set "OPCION="
set /p "OPCION=Opcion [1-5]: "
if not defined OPCION goto :opcion_agente_invalida
set OPCION=!OPCION:"=!
set "OPCION=!OPCION: =!"
if not defined OPCION goto :opcion_agente_invalida
rem  Nota: goto dentro de un bloque if (...) confunde a cmd.exe para
rem  encontrar etiquetas mas adelante en el archivo, por eso set y goto
rem  van en lineas sueltas en vez de agrupados con "&" entre parentesis.
if "!OPCION!"=="1" set "DO_CLAUDE=1"
if "!OPCION!"=="1" set "DO_OPENCODE=1"
if "!OPCION!"=="1" set "DO_CODEX=1"
if "!OPCION!"=="1" goto :inicio
if "!OPCION!"=="2" set "DO_CLAUDE=1"
if "!OPCION!"=="2" goto :inicio
if "!OPCION!"=="3" set "DO_OPENCODE=1"
if "!OPCION!"=="3" goto :inicio
if "!OPCION!"=="4" set "DO_CODEX=1"
if "!OPCION!"=="4" goto :inicio
if "!OPCION!"=="5" goto :salir

rem  El contador evita un bucle infinito cuando no hay entrada que leer
rem  (por ejemplo si el script se ejecuta con la entrada redirigida).
:opcion_agente_invalida
set /a TRIES+=1
if !TRIES! GEQ 5 goto :demasiados_intentos
echo.
echo [ERROR] Opcion invalida. Escribe un numero del 1 al 5 y pulsa Enter.
goto :menu_agentes_opciones

:demasiados_intentos
echo.
echo [FALLO] Demasiadas opciones invalidas. No se modifico ningun archivo.
echo.
pause
endlocal
exit /b 1

rem  Sin pause: al ejecutarlo con doble clic la ventana se cierra sola.
rem  Se usa "exit /b" y no "exit" para no matar una consola ya abierta
rem  desde la que se haya lanzado el script.
:salir
endlocal
exit /b 0

rem ============================================================
rem  PARTE 1 - BLENDER
rem  El MCP oficial de Blender son DOS piezas que hablan por
rem  socket TCP: el add-on dentro de Blender (puerto 9876) y el
rem  servidor "blender-mcp", que lanza el cliente MCP por stdio.
rem ============================================================
:inicio

echo.
echo === Blender MCP ===

rem ---- 1) Ruta pasada por parametro --------------------------
if "%BLENDER_ARG%"=="" goto :blender_env
if not exist "%BLENDER_ARG%" goto :blender_param_malo
set "BLENDER_EXE=%BLENDER_ARG%"
echo [OK] Ruta de Blender indicada por parametro.
goto :blender_version

:blender_param_malo
echo [AVISO] La ruta de Blender indicada no existe: %BLENDER_ARG%
goto :blender_buscar

rem ---- 2) Variable de entorno BLENDER_PATH -------------------
:blender_env
if not defined BLENDER_PATH goto :blender_buscar
if not exist "%BLENDER_PATH%" goto :blender_buscar
set "BLENDER_EXE=%BLENDER_PATH%"
echo [OK] Encontrado en la variable de entorno BLENDER_PATH.
goto :blender_version

rem ---- 3) PATH y carpetas habituales -------------------------
:blender_buscar
echo Buscando Blender...
for /f "delims=" %%F in ('where blender 2^>nul') do call :addbcand "%%F"
call :scanb "%ProgramFiles%\Blender Foundation"
call :scanb "%ProgramFiles(x86)%\Blender Foundation"
call :scanb "%ProgramFiles%\Steam\steamapps\common\Blender"
call :scanb "%ProgramFiles(x86)%\Steam\steamapps\common\Blender"
call :scanb "%LOCALAPPDATA%\Programs\Blender Foundation"
call :scanb "C:\Blender"
call :scanb "D:\Blender"
call :scanb "E:\Blender"

if %BCOUNT% EQU 0 goto :blender_no_hay

rem ---- 4) Quedarse con la version mas alta -------------------
for /l %%I in (1,1,%BCOUNT%) do call :verbest "!BCAND_%%I!"
if not defined BLENDER_EXE goto :blender_no_hay
echo [OK] Blender encontrado: !BLENDER_EXE!
goto :blender_version_ok

:blender_no_hay
echo [AVISO] No se encontro Blender. Se omite su servidor MCP.
echo         Instala Blender 5.1+ y vuelve a ejecutar este script para agregarlo.
set "BLENDER_EXE="
goto :escritura

rem ---- 5) Chequeo de version (el add-on pide 5.1 o mayor) ----
:blender_version
set "BEST_VER=0"
call :verbest "!BLENDER_EXE!"
if not defined BLENDER_EXE goto :blender_no_hay

:blender_version_ok
if %BEST_VER% GEQ 501 goto :blender_uv
echo [AVISO] El add-on MCP oficial necesita Blender 5.1 o superior.
echo         Version detectada demasiado vieja. Se omite el MCP de Blender.
set "BLENDER_EXE="
goto :escritura

rem ---- 6) uv: es quien lanza el servidor blender-mcp ---------
:blender_uv
where uv >nul 2>nul
if not errorlevel 1 goto :blender_uv_ok
echo.
echo [FALTA] "uv" no esta instalado. Es necesario para lanzar el servidor MCP.
choice /c SN /n /m "Instalarlo ahora con winget? [S/N]: "
if errorlevel 2 goto :blender_uv_no
winget install --id=astral-sh.uv -e --accept-source-agreements --accept-package-agreements --disable-interactivity
where uv >nul 2>nul
if not errorlevel 1 goto :blender_uv_nuevo
echo [AVISO] uv no quedo disponible en esta consola.
echo         Suele bastar con abrir una consola nueva; los archivos se generan igual.
goto :blender_addon

:blender_uv_nuevo
echo [OK] uv instalado.
goto :blender_addon

:blender_uv_no
echo [AVISO] Sin uv el servidor MCP de Blender no va a arrancar.
echo         Puedes instalarlo despues con: winget install --id=astral-sh.uv -e
goto :blender_addon

:blender_uv_ok
echo [OK] uv ya esta instalado.

rem ---- 7) Add-on MCP dentro de Blender ----------------------
rem  Se instala desde el repositorio de extensiones del Blender
rem  Lab (no desde un zip suelto) para que reciba updates solo.
:blender_addon
set "BLENDER_JSON=!BLENDER_EXE:\=\\!"
if defined DO_CLAUDE set "BLENDER_JSON_CLAUDE=!BLENDER_JSON!"
if defined DO_OPENCODE set "BLENDER_JSON_OPENCODE=!BLENDER_JSON!"
if defined DO_CODEX set "BLENDER_JSON_CODEX=!BLENDER_JSON!"
tasklist /fi "imagename eq blender.exe" 2>nul | find /i "blender.exe" >nul
if errorlevel 1 goto :blender_addon_ok
echo.
echo [AVISO] Blender esta abierto. Instalar el add-on ahora no serviria:
echo         al cerrarse, esa instancia pisa las preferencias y se pierde.
echo         Cierra Blender y vuelve a ejecutar este script.
goto :escritura

:blender_addon_ok
echo Configurando el add-on MCP en Blender...

rem El repo solo se agrega si no existe, para no duplicarlo en cada corrida.
"!BLENDER_EXE!" --command extension repo-list 2>nul | find /i "lab_blender_org:" >nul
if not errorlevel 1 goto :blender_repo_ok
"!BLENDER_EXE!" --command extension repo-add lab_blender_org --name "Blender Lab" --url "https://lab.blender.org/" >nul 2>nul
echo   Repositorio "Blender Lab" agregado.
goto :blender_sync

:blender_repo_ok
echo   Repositorio "Blender Lab" ya estaba configurado.

:blender_sync
rem  --online-mode: sin el, sync falla si el acceso en linea esta
rem  apagado en las preferencias (es lo normal en una instalacion nueva).
"!BLENDER_EXE!" --online-mode --command extension sync >nul 2>nul
"!BLENDER_EXE!" --online-mode --command extension install lab_blender_org.mcp --enable >nul 2>nul
"!BLENDER_EXE!" --command extension list 2>nul | find /i "mcp [installed]" >nul
if errorlevel 1 goto :blender_addon_fallo
echo   [OK] Add-on MCP instalado y habilitado (auto-start en localhost:9876).
goto :escritura

:blender_addon_fallo
echo   [AVISO] No se pudo confirmar la instalacion del add-on.
echo           Instalacion manual: Edit ^> Preferences ^> Get Extensions,
echo           agrega el repositorio https://lab.blender.org/ y busca "MCP".

rem ============================================================
rem  PARTE 2 - Escritura de la config de cada agente elegido
rem ============================================================
:escritura
if not defined BLENDER_JSON_CLAUDE if not defined BLENDER_JSON_OPENCODE if not defined BLENDER_JSON_CODEX goto :sin_config_que_escribir

if defined DO_CLAUDE call :write_claude
if defined DO_OPENCODE call :write_opencode
if defined DO_CODEX call :write_codex

echo.
echo [LISTO] Configuracion generada.
if defined DO_CLAUDE (
    set "BD=!BLENDER_JSON_CLAUDE:\\=\!"
    if defined BLENDER_JSON_CLAUDE echo   Claude Code / blender ^| !BD!
    if not defined BLENDER_JSON_CLAUDE echo   Claude Code / blender ^| sin configurar
)
if defined DO_OPENCODE (
    set "BD=!BLENDER_JSON_OPENCODE:\\=\!"
    if defined BLENDER_JSON_OPENCODE echo   OpenCode / blender    ^| !BD!
    if not defined BLENDER_JSON_OPENCODE echo   OpenCode / blender    ^| sin configurar
)
if defined DO_CODEX (
    set "BD=!BLENDER_JSON_CODEX:\\=\!"
    if defined BLENDER_JSON_CODEX echo   Codex / blender       ^| !BD!
    if not defined BLENDER_JSON_CODEX echo   Codex / blender       ^| sin configurar
)

set "BLENDER_ANY="
if defined BLENDER_JSON_CLAUDE set "BLENDER_ANY=1"
if defined BLENDER_JSON_OPENCODE set "BLENDER_ANY=1"
if defined BLENDER_JSON_CODEX set "BLENDER_ANY=1"
echo.
if defined BLENDER_ANY echo Abre Blender antes de usar sus herramientas: el add-on levanta
if defined BLENDER_ANY echo el servidor en localhost:9876 al arrancar.
echo Reinicia tu(s) agente(s) de codigo para que tomen la configuracion del MCP.
echo.
pause
endlocal
exit /b 0

:sin_config_que_escribir
echo.
echo [FALLO] No hay ningun servidor que configurar.
echo         No se modifico ningun archivo.
echo.
pause
endlocal
exit /b 1

rem ---- Escritura por agente -----------------------------------

:write_claude
if not defined BLENDER_JSON_CLAUDE (
    echo.
    echo [AVISO] Claude Code: nada que escribir en .mcp.json.
    exit /b 0
)
> "%TARGET_CLAUDE%" echo {
>>"%TARGET_CLAUDE%" echo   "mcpServers": {
rem  --refresh   : uv vuelve a resolver el repo en cada arranque (auto-update).
rem  mcp[cli] "<"2: el pyproject oficial pide "mcp>=1.2.0" sin tope y mcp 2.x
rem                 renombro FastMCP, lo que rompe el servidor.
>>"%TARGET_CLAUDE%" echo     "blender": {
>>"%TARGET_CLAUDE%" echo       "command": "uvx",
>>"%TARGET_CLAUDE%" echo       "args": [
>>"%TARGET_CLAUDE%" echo         "--refresh",
>>"%TARGET_CLAUDE%" echo         "--with",
>>"%TARGET_CLAUDE%" echo         "mcp[cli]!LT!2",
>>"%TARGET_CLAUDE%" echo         "--from",
>>"%TARGET_CLAUDE%" echo         "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp",
>>"%TARGET_CLAUDE%" echo         "blender-mcp"
>>"%TARGET_CLAUDE%" echo       ],
>>"%TARGET_CLAUDE%" echo       "env": {
>>"%TARGET_CLAUDE%" echo         "BLENDER_MCP_HOST": "localhost",
>>"%TARGET_CLAUDE%" echo         "BLENDER_MCP_PORT": "9876",
>>"%TARGET_CLAUDE%" echo         "BLENDER_PATH": "!BLENDER_JSON_CLAUDE!"
>>"%TARGET_CLAUDE%" echo       }
>>"%TARGET_CLAUDE%" echo     }
>>"%TARGET_CLAUDE%" echo   }
>>"%TARGET_CLAUDE%" echo }
echo   [OK] Claude Code -^> .mcp.json
exit /b 0

:write_opencode
if not defined BLENDER_JSON_OPENCODE (
    echo.
    echo [AVISO] OpenCode: nada que escribir en opencode.json.
    exit /b 0
)
> "%TARGET_OPENCODE%" echo {
>>"%TARGET_OPENCODE%" echo   "mcp": {
>>"%TARGET_OPENCODE%" echo     "blender": {
>>"%TARGET_OPENCODE%" echo       "type": "local",
>>"%TARGET_OPENCODE%" echo       "command": ["uvx", "--refresh", "--with", "mcp[cli]!LT!2", "--from", "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp", "blender-mcp"],
>>"%TARGET_OPENCODE%" echo       "environment": {
>>"%TARGET_OPENCODE%" echo         "BLENDER_MCP_HOST": "localhost",
>>"%TARGET_OPENCODE%" echo         "BLENDER_MCP_PORT": "9876",
>>"%TARGET_OPENCODE%" echo         "BLENDER_PATH": "!BLENDER_JSON_OPENCODE!"
>>"%TARGET_OPENCODE%" echo       }
>>"%TARGET_OPENCODE%" echo     }
>>"%TARGET_OPENCODE%" echo   }
>>"%TARGET_OPENCODE%" echo }
echo   [OK] OpenCode   -^> opencode.json
exit /b 0

:write_codex
if not defined BLENDER_JSON_CODEX (
    echo.
    echo [AVISO] Codex: nada que escribir en .codex\config.toml.
    exit /b 0
)
if not exist "%TARGET_CODEX_DIR%" mkdir "%TARGET_CODEX_DIR%"
> "%TARGET_CODEX%" echo # Generado por mcp-setup.bat
>>"%TARGET_CODEX%" echo.
>>"%TARGET_CODEX%" echo [mcp_servers.blender]
>>"%TARGET_CODEX%" echo command = "uvx"
>>"%TARGET_CODEX%" echo args = ["--refresh", "--with", "mcp[cli]!LT!2", "--from", "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp", "blender-mcp"]
>>"%TARGET_CODEX%" echo.
>>"%TARGET_CODEX%" echo [mcp_servers.blender.env]
>>"%TARGET_CODEX%" echo BLENDER_MCP_HOST = "localhost"
>>"%TARGET_CODEX%" echo BLENDER_MCP_PORT = "9876"
>>"%TARGET_CODEX%" echo BLENDER_PATH = "!BLENDER_JSON_CODEX!"
echo   [OK] Codex      -^> .codex\config.toml
echo        (Codex solo carga config de proyecto si esta marcado "trusted")
exit /b 0

rem ---- Subrutinas -------------------------------------------

rem :scanb <carpeta>  -> busca blender.exe recursivamente
rem  El nombre exacto deja fuera a blender-launcher.exe, que no
rem  acepta los argumentos --command.
:scanb
if "%~1"=="" exit /b 0
if not exist "%~1" exit /b 0
for /f "delims=" %%F in ('dir /b /s /a-d "%~1\blender.exe" 2^>nul') do call :addbcand "%%F"
exit /b 0

rem :addbcand <ruta>  -> agrega candidato de Blender sin duplicados
:addbcand
if "%~1"=="" exit /b 0
if not exist "%~1" exit /b 0
set "DUP="
for /l %%I in (1,1,%BCOUNT%) do if /i "!BCAND_%%I!"=="%~1" set "DUP=1"
if defined DUP exit /b 0
set /a BCOUNT+=1
set "BCAND_!BCOUNT!=%~1"
echo   [!BCOUNT!] %~1
exit /b 0

rem :verbest <ruta>  -> se queda con la version mas alta de Blender
rem  "blender --version" imprime "Blender 5.2.1 LTS"; se compone un
rem  entero major*100+minor para poder comparar (5.2 -> 502).
:verbest
if "%~1"=="" exit /b 0
set "VTMP=%TEMP%\ssx_blender_ver.txt"
"%~1" --version > "!VTMP!" 2>nul
if not exist "!VTMP!" exit /b 0
rem  Se lee desde archivo y no con for /f sobre el comando: una ruta
rem  con espacios rompe el parser de cmd ("C:\Program" no se reconoce).
set "VSTR="
for /f "usebackq tokens=1,2 delims= " %%A in ("!VTMP!") do if /i "%%A"=="Blender" if not defined VSTR set "VSTR=%%B"
del "!VTMP!" >nul 2>nul
if not defined VSTR exit /b 0
set "VMAJ="
set "VMIN="
for /f "tokens=1,2 delims=." %%A in ("!VSTR!") do set "VMAJ=%%A" & set "VMIN=%%B"
if not defined VMAJ exit /b 0
if not defined VMIN set "VMIN=0"
set /a VNUM=VMAJ*100+VMIN
if not defined VNUM exit /b 0
if !VNUM! LEQ !BEST_VER! exit /b 0
set "BEST_VER=!VNUM!"
set "BLENDER_EXE=%~1"
exit /b 0
