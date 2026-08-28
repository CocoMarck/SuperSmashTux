@echo off
setlocal EnableDelayedExpansion
title Setup MCP - Super Smash Tux

rem ============================================================
rem  mcp-setup.bat
rem  Configura los servidores MCP del proyecto para uno o varios
rem  agentes de codigo, y genera su archivo de configuracion:
rem
rem    Claude Code -> .mcp.json
rem    OpenCode    -> opencode.json
rem    Codex CLI   -> .codex\config.toml
rem
rem  Servidores disponibles:
rem    godot   -> godot-mcp (npx), necesita Node.js 18+
rem    blender -> MCP oficial de Blender (uvx + add-on)
rem
rem  Uso:
rem    mcp-setup.bat                                   -> menu interactivo
rem    mcp-setup.bat <agentes> [godot.exe] [blender.exe]
rem
rem    <agentes>: claude | opencode | codex | all
rem               (o una lista separada por "+", ej: claude+codex)
rem               NOTA: no uses coma como separador - cmd.exe la trata
rem               como separador de argumentos y rompe el parseo.
rem
rem  Ejemplos:
rem    mcp-setup.bat all
rem    mcp-setup.bat claude+codex "D:\Godot\Godot.exe"
rem    mcp-setup.bat opencode "" "D:\Blender\blender.exe"
rem
rem  En modo interactivo, al elegir un solo servidor el otro se
rem  conserva leyendo el archivo de cada agente que ya exista, para
rem  no perder configuracion. En modo parametros siempre se
rem  configuran ambos servidores para el/los agente(s) indicado(s).
rem ============================================================

set "PROJECT_DIR=%~dp0"
set "TARGET_CLAUDE=%PROJECT_DIR%.mcp.json"
set "TARGET_OPENCODE=%PROJECT_DIR%opencode.json"
set "TARGET_CODEX_DIR=%PROJECT_DIR%.codex"
set "TARGET_CODEX=%TARGET_CODEX_DIR%\config.toml"
set "GODOT_EXE="
set "BLENDER_EXE="
set "COUNT=0"
set "BCOUNT=0"
set "BEST_VER=0"

rem  Rutas ya escapadas para JSON/TOML (misma regla de escape en ambos:
rem  duplicar barras invertidas). Si quedan vacias, ese servidor no se
rem  escribe para ese agente.
set "GODOT_JSON="
set "BLENDER_JSON="
set "GODOT_JSON_CLAUDE="
set "GODOT_JSON_OPENCODE="
set "GODOT_JSON_CODEX="
set "BLENDER_JSON_CLAUDE="
set "BLENDER_JSON_OPENCODE="
set "BLENDER_JSON_CODEX="

set "DO_GODOT="
set "DO_BLENDER="
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
set "BLENDER_ARG=%~3"
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

set "DO_GODOT=1"
set "DO_BLENDER=1"
goto :inicio

:agentes_invalidos
echo.
echo [ERROR] Agente(s) invalido(s): "%AGENTS_RAW%"
echo         Valores validos: claude, opencode, codex, all
echo         o una lista separada por "+", ej: claude+codex
echo.
echo Uso: mcp-setup.bat ^<agentes^> [ruta_godot] [ruta_blender]
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
if "!OPCION!"=="1" goto :menu_servidores
if "!OPCION!"=="2" set "DO_CLAUDE=1"
if "!OPCION!"=="2" goto :menu_servidores
if "!OPCION!"=="3" set "DO_OPENCODE=1"
if "!OPCION!"=="3" goto :menu_servidores
if "!OPCION!"=="4" set "DO_CODEX=1"
if "!OPCION!"=="4" goto :menu_servidores
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

rem ============================================================
rem  MENU INTERACTIVO - PASO 2: servidor(es)
rem ============================================================
:menu_servidores
echo.
echo Estado actual:
if not defined DO_CLAUDE goto :estado_opencode
call :jsonget "GODOT_PATH" "%TARGET_CLAUDE%"
if defined JG_VAL echo   [x] Claude Code / godot    ^| !JG_DISP!
if not defined JG_VAL echo   [ ] Claude Code / godot    ^| sin configurar
call :jsonget "BLENDER_PATH" "%TARGET_CLAUDE%"
if defined JG_VAL echo   [x] Claude Code / blender  ^| !JG_DISP!
if not defined JG_VAL echo   [ ] Claude Code / blender  ^| sin configurar

:estado_opencode
if not defined DO_OPENCODE goto :estado_codex
call :jsonget "GODOT_PATH" "%TARGET_OPENCODE%"
if defined JG_VAL echo   [x] OpenCode / godot       ^| !JG_DISP!
if not defined JG_VAL echo   [ ] OpenCode / godot       ^| sin configurar
call :jsonget "BLENDER_PATH" "%TARGET_OPENCODE%"
if defined JG_VAL echo   [x] OpenCode / blender     ^| !JG_DISP!
if not defined JG_VAL echo   [ ] OpenCode / blender     ^| sin configurar

:estado_codex
if not defined DO_CODEX goto :estado_fin
call :tomlget "GODOT_PATH" "%TARGET_CODEX%"
if defined JG_VAL echo   [x] Codex / godot          ^| !JG_DISP!
if not defined JG_VAL echo   [ ] Codex / godot          ^| sin configurar
call :tomlget "BLENDER_PATH" "%TARGET_CODEX%"
if defined JG_VAL echo   [x] Codex / blender        ^| !JG_DISP!
if not defined JG_VAL echo   [ ] Codex / blender        ^| sin configurar

:estado_fin
set /a TRIES=0

:menu_opciones
echo.
echo Que deseas configurar?
echo.
echo   [1] Godot y Blender
echo   [2] Solo Godot     (godot-mcp, necesita Node.js 18+)
echo   [3] Solo Blender   (MCP oficial, necesita Blender 5.1+)
echo   [4] Salir sin cambios
echo.
set "OPCION="
set /p "OPCION=Opcion [1-4]: "
if not defined OPCION goto :opcion_invalida
rem  Sin comillas envolventes: "set "V=!V:"=!"" deja el valor en '"='.
set OPCION=!OPCION:"=!
set "OPCION=!OPCION: =!"
if not defined OPCION goto :opcion_invalida
if "!OPCION!"=="1" goto :modo_todo
if "!OPCION!"=="2" goto :modo_godot
if "!OPCION!"=="3" goto :modo_blender
if "!OPCION!"=="4" set "DO_CLAUDE="
if "!OPCION!"=="4" set "DO_OPENCODE="
if "!OPCION!"=="4" set "DO_CODEX="
if "!OPCION!"=="4" goto :menu_agentes

:opcion_invalida
set /a TRIES+=1
if !TRIES! GEQ 5 goto :demasiados_intentos
echo.
echo [ERROR] Opcion invalida. Escribe un numero del 1 al 4 y pulsa Enter.
goto :menu_opciones

:modo_todo
set "DO_GODOT=1"
set "DO_BLENDER=1"
goto :inicio

:modo_godot
set "DO_GODOT=1"
goto :inicio

:modo_blender
set "DO_BLENDER=1"
goto :inicio

rem  Sin pause: al ejecutarlo con doble clic la ventana se cierra sola.
rem  Se usa "exit /b" y no "exit" para no matar una consola ya abierta
rem  desde la que se haya lanzado el script.
:salir
endlocal
exit /b 0

rem ---- Lo que no se reconfigura se rescata del archivo de cada agente --
:inicio
if defined DO_CLAUDE call :rescate_agente CLAUDE "%TARGET_CLAUDE%" json "Claude Code"
if defined DO_OPENCODE call :rescate_agente OPENCODE "%TARGET_OPENCODE%" json "OpenCode"
if defined DO_CODEX call :rescate_agente CODEX "%TARGET_CODEX%" toml "Codex"

rem ============================================================
rem  PARTE 1 - GODOT
rem ============================================================
:parte_godot
if not defined DO_GODOT goto :parte_blender

echo.
echo === Godot MCP ===

rem ---- 1) Ruta pasada por parametro -------------------------
if "%~2"=="" goto :sin_parametro
if not exist "%~2" goto :param_malo
set "GODOT_EXE=%~2"
echo [OK] Ruta de Godot indicada por parametro.
goto :godot_listo

:param_malo
echo [ERROR] La ruta indicada no existe: %~2
goto :error_fatal

:sin_parametro
rem ---- 2) Variable de entorno GODOT_PATH ---------------------
if not defined GODOT_PATH goto :buscar
if not exist "%GODOT_PATH%" goto :buscar
set "GODOT_EXE=%GODOT_PATH%"
echo [OK] Encontrado en la variable de entorno GODOT_PATH.
goto :godot_listo

:buscar
rem ---- 3) Godot dentro del PATH ------------------------------
echo Buscando Godot en el PATH...
for /f "delims=" %%F in ('where godot 2^>nul') do call :addcand "%%F"
for /f "delims=" %%F in ('where godot4 2^>nul') do call :addcand "%%F"

rem ---- 4) Carpetas habituales de instalacion -----------------
echo Buscando en carpetas habituales...
call :scan "%LOCALAPPDATA%\Programs"
call :scan "%LOCALAPPDATA%\Godot"
call :scan "%ProgramFiles%\Godot"
call :scan "%ProgramFiles(x86)%\Godot"
call :scan "%ProgramFiles%\Steam\steamapps\common\Godot Engine"
call :scan "%ProgramFiles(x86)%\Steam\steamapps\common\Godot Engine"
call :scan "%USERPROFILE%\Downloads"
call :scan "%USERPROFILE%\Documents\Godot"
call :scan "C:\Godot"
call :scan "D:\Godot"
call :scan "E:\Godot"

if not %COUNT% EQU 0 goto :elegir

rem ---- 5) Busqueda profunda opcional ------------------------
echo.
echo No se encontro Godot en las rutas habituales.
choice /c SN /n /m "Buscar en todos los discos? Puede tardar varios minutos [S/N]: "
if errorlevel 2 goto :manual
for /f "skip=1 delims=" %%D in ('wmic logicaldisk where "drivetype=3" get deviceid 2^>nul') do call :scandrive "%%D"
if %COUNT% EQU 0 goto :manual

:elegir
rem ---- 6) Seleccion cuando hay varios resultados -------------
if not %COUNT% EQU 1 goto :menu_godot
set "GODOT_EXE=!CAND_1!"
echo.
echo [OK] Godot encontrado: !GODOT_EXE!
goto :godot_listo

:menu_godot
echo.
echo Se encontraron %COUNT% ejecutables de Godot:
for /l %%I in (1,1,%COUNT%) do echo   [%%I] !CAND_%%I!
echo.
set "PICK="
set /p "PICK=Numero a usar (1-%COUNT%): "
if not defined PICK goto :error_fatal
set "GODOT_EXE=!CAND_%PICK%!"
if not defined GODOT_EXE goto :pick_malo
goto :godot_listo

:pick_malo
echo [ERROR] Opcion invalida.
goto :error_fatal

rem ---- Entrada manual ---------------------------------------
:manual
echo.
echo No se pudo detectar Godot automaticamente.
set "GODOT_EXE="
set /p "GODOT_EXE=Escribe la ruta completa al ejecutable de Godot: "
if not defined GODOT_EXE goto :error_fatal
set "GODOT_EXE=!GODOT_EXE:"=!"
if not exist "!GODOT_EXE!" goto :ruta_mala
goto :godot_listo

:ruta_mala
echo [ERROR] La ruta no existe.
goto :error_fatal

:godot_listo
if not exist "!GODOT_EXE!" goto :godot_no_exe
rem Duplicar las barras invertidas para JSON/TOML
set "GODOT_JSON=!GODOT_EXE:\=\\!"
if defined DO_CLAUDE set "GODOT_JSON_CLAUDE=!GODOT_JSON!"
if defined DO_OPENCODE set "GODOT_JSON_OPENCODE=!GODOT_JSON!"
if defined DO_CODEX set "GODOT_JSON_CODEX=!GODOT_JSON!"

rem ============================================================
rem  PARTE 2 - BLENDER
rem  El MCP oficial de Blender son DOS piezas que hablan por
rem  socket TCP: el add-on dentro de Blender (puerto 9876) y el
rem  servidor "blender-mcp", que lanza el cliente MCP por stdio.
rem ============================================================
:parte_blender
if not defined DO_BLENDER goto :escritura

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
"!BLENDER_EXE!" --command extension sync >nul 2>nul
"!BLENDER_EXE!" --command extension install lab_blender_org.mcp --enable >nul 2>nul
"!BLENDER_EXE!" --command extension list 2>nul | find /i "mcp [installed]" >nul
if errorlevel 1 goto :blender_addon_fallo
echo   [OK] Add-on MCP instalado y habilitado (auto-start en localhost:9876).
goto :escritura

:blender_addon_fallo
echo   [AVISO] No se pudo confirmar la instalacion del add-on.
echo           Instalacion manual: Edit ^> Preferences ^> Get Extensions,
echo           agrega el repositorio https://lab.blender.org/ y busca "MCP".

rem ============================================================
rem  PARTE 3 - Escritura de la config de cada agente elegido
rem ============================================================
:escritura
if not defined GODOT_JSON_CLAUDE if not defined GODOT_JSON_OPENCODE if not defined GODOT_JSON_CODEX if not defined BLENDER_JSON_CLAUDE if not defined BLENDER_JSON_OPENCODE if not defined BLENDER_JSON_CODEX goto :sin_config_que_escribir

if defined DO_CLAUDE call :write_claude
if defined DO_OPENCODE call :write_opencode
if defined DO_CODEX call :write_codex

echo.
echo [LISTO] Configuracion generada.
if defined DO_CLAUDE (
    set "GD=!GODOT_JSON_CLAUDE:\\=\!"
    set "BD=!BLENDER_JSON_CLAUDE:\\=\!"
    if defined GODOT_JSON_CLAUDE echo   Claude Code / godot   ^| !GD!
    if not defined GODOT_JSON_CLAUDE echo   Claude Code / godot   ^| sin configurar
    if defined BLENDER_JSON_CLAUDE echo   Claude Code / blender ^| !BD!
    if not defined BLENDER_JSON_CLAUDE echo   Claude Code / blender ^| sin configurar
)
if defined DO_OPENCODE (
    set "GD=!GODOT_JSON_OPENCODE:\\=\!"
    set "BD=!BLENDER_JSON_OPENCODE:\\=\!"
    if defined GODOT_JSON_OPENCODE echo   OpenCode / godot      ^| !GD!
    if not defined GODOT_JSON_OPENCODE echo   OpenCode / godot      ^| sin configurar
    if defined BLENDER_JSON_OPENCODE echo   OpenCode / blender    ^| !BD!
    if not defined BLENDER_JSON_OPENCODE echo   OpenCode / blender    ^| sin configurar
)
if defined DO_CODEX (
    set "GD=!GODOT_JSON_CODEX:\\=\!"
    set "BD=!BLENDER_JSON_CODEX:\\=\!"
    if defined GODOT_JSON_CODEX echo   Codex / godot         ^| !GD!
    if not defined GODOT_JSON_CODEX echo   Codex / godot         ^| sin configurar
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

:godot_no_exe
echo [ERROR] El ejecutable no existe: !GODOT_EXE!

:error_fatal
echo.
echo [FALLO] No se genero la configuracion.
echo.
pause
endlocal
exit /b 1

rem ---- Escritura por agente -----------------------------------

:write_claude
if not defined GODOT_JSON_CLAUDE if not defined BLENDER_JSON_CLAUDE (
    echo.
    echo [AVISO] Claude Code: nada que escribir en .mcp.json.
    exit /b 0
)
> "%TARGET_CLAUDE%" echo {
>>"%TARGET_CLAUDE%" echo   "mcpServers": {
if not defined GODOT_JSON_CLAUDE goto :wc_blender

>>"%TARGET_CLAUDE%" echo     "godot": {
>>"%TARGET_CLAUDE%" echo       "command": "npx",
>>"%TARGET_CLAUDE%" echo       "args": ["@coding-solo/godot-mcp"],
>>"%TARGET_CLAUDE%" echo       "env": {
>>"%TARGET_CLAUDE%" echo         "GODOT_PATH": "!GODOT_JSON_CLAUDE!"
>>"%TARGET_CLAUDE%" echo       }
if defined BLENDER_JSON_CLAUDE goto :wc_coma
>>"%TARGET_CLAUDE%" echo     }
goto :wc_cierre

:wc_coma
>>"%TARGET_CLAUDE%" echo     },

:wc_blender
if not defined BLENDER_JSON_CLAUDE goto :wc_cierre
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

:wc_cierre
>>"%TARGET_CLAUDE%" echo   }
>>"%TARGET_CLAUDE%" echo }
echo   [OK] Claude Code -^> .mcp.json
exit /b 0

:write_opencode
if not defined GODOT_JSON_OPENCODE if not defined BLENDER_JSON_OPENCODE (
    echo.
    echo [AVISO] OpenCode: nada que escribir en opencode.json.
    exit /b 0
)
> "%TARGET_OPENCODE%" echo {
>>"%TARGET_OPENCODE%" echo   "mcp": {
if not defined GODOT_JSON_OPENCODE goto :wo_blender

>>"%TARGET_OPENCODE%" echo     "godot": {
>>"%TARGET_OPENCODE%" echo       "type": "local",
>>"%TARGET_OPENCODE%" echo       "command": ["npx", "@coding-solo/godot-mcp"],
>>"%TARGET_OPENCODE%" echo       "environment": {
>>"%TARGET_OPENCODE%" echo         "GODOT_PATH": "!GODOT_JSON_OPENCODE!"
>>"%TARGET_OPENCODE%" echo       }
if defined BLENDER_JSON_OPENCODE goto :wo_coma
>>"%TARGET_OPENCODE%" echo     }
goto :wo_cierre

:wo_coma
>>"%TARGET_OPENCODE%" echo     },

:wo_blender
if not defined BLENDER_JSON_OPENCODE goto :wo_cierre
>>"%TARGET_OPENCODE%" echo     "blender": {
>>"%TARGET_OPENCODE%" echo       "type": "local",
>>"%TARGET_OPENCODE%" echo       "command": ["uvx", "--refresh", "--with", "mcp[cli]!LT!2", "--from", "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp", "blender-mcp"],
>>"%TARGET_OPENCODE%" echo       "environment": {
>>"%TARGET_OPENCODE%" echo         "BLENDER_MCP_HOST": "localhost",
>>"%TARGET_OPENCODE%" echo         "BLENDER_MCP_PORT": "9876",
>>"%TARGET_OPENCODE%" echo         "BLENDER_PATH": "!BLENDER_JSON_OPENCODE!"
>>"%TARGET_OPENCODE%" echo       }
>>"%TARGET_OPENCODE%" echo     }

:wo_cierre
>>"%TARGET_OPENCODE%" echo   }
>>"%TARGET_OPENCODE%" echo }
echo   [OK] OpenCode   -^> opencode.json
exit /b 0

:write_codex
if not defined GODOT_JSON_CODEX if not defined BLENDER_JSON_CODEX (
    echo.
    echo [AVISO] Codex: nada que escribir en .codex\config.toml.
    exit /b 0
)
if not exist "%TARGET_CODEX_DIR%" mkdir "%TARGET_CODEX_DIR%"
> "%TARGET_CODEX%" echo # Generado por mcp-setup.bat
if not defined GODOT_JSON_CODEX goto :wx_blender

>>"%TARGET_CODEX%" echo.
>>"%TARGET_CODEX%" echo [mcp_servers.godot]
>>"%TARGET_CODEX%" echo command = "npx"
>>"%TARGET_CODEX%" echo args = ["@coding-solo/godot-mcp"]
>>"%TARGET_CODEX%" echo.
>>"%TARGET_CODEX%" echo [mcp_servers.godot.env]
>>"%TARGET_CODEX%" echo GODOT_PATH = "!GODOT_JSON_CODEX!"

:wx_blender
if not defined BLENDER_JSON_CODEX goto :wx_cierre
>>"%TARGET_CODEX%" echo.
>>"%TARGET_CODEX%" echo [mcp_servers.blender]
>>"%TARGET_CODEX%" echo command = "uvx"
>>"%TARGET_CODEX%" echo args = ["--refresh", "--with", "mcp[cli]!LT!2", "--from", "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp", "blender-mcp"]
>>"%TARGET_CODEX%" echo.
>>"%TARGET_CODEX%" echo [mcp_servers.blender.env]
>>"%TARGET_CODEX%" echo BLENDER_MCP_HOST = "localhost"
>>"%TARGET_CODEX%" echo BLENDER_MCP_PORT = "9876"
>>"%TARGET_CODEX%" echo BLENDER_PATH = "!BLENDER_JSON_CODEX!"

:wx_cierre
echo   [OK] Codex      -^> .codex\config.toml
echo        (Codex solo carga config de proyecto si esta marcado "trusted")
exit /b 0

rem ---- Subrutinas -------------------------------------------

rem :rescate_agente <NOMBRE> <archivo> <json|toml> <etiqueta>
rem  Si un servidor no se va a reconfigurar en esta corrida (DO_GODOT o
rem  DO_BLENDER sin definir), rescata su valor del propio archivo de ese
rem  agente y lo deja en GODOT_JSON_<NOMBRE> / BLENDER_JSON_<NOMBRE>.
:rescate_agente
set "RA_NAME=%~1"
set "RA_FILE=%~2"
set "RA_FMT=%~3"
set "RA_LABEL=%~4"
if defined DO_GODOT goto :ra_blender
if /i "%RA_FMT%"=="toml" goto :ra_godot_toml
call :jsonget "GODOT_PATH" "%RA_FILE%"
goto :ra_godot_val
:ra_godot_toml
call :tomlget "GODOT_PATH" "%RA_FILE%"
:ra_godot_val
if not defined JG_VAL goto :ra_blender
set "GODOT_JSON_%RA_NAME%=!JG_VAL!"
echo   [=] %RA_LABEL%: se conserva la configuracion de Godot existente.

:ra_blender
if defined DO_BLENDER exit /b 0
if /i "%RA_FMT%"=="toml" goto :ra_blender_toml
call :jsonget "BLENDER_PATH" "%RA_FILE%"
goto :ra_blender_val
:ra_blender_toml
call :tomlget "BLENDER_PATH" "%RA_FILE%"
:ra_blender_val
if not defined JG_VAL exit /b 0
set "BLENDER_JSON_%RA_NAME%=!JG_VAL!"
echo   [=] %RA_LABEL%: se conserva la configuracion de Blender existente.
exit /b 0

rem :jsonget <clave> <archivo>  -> deja en JG_VAL el valor de esa clave
rem  en un archivo JSON, ya escapado para JSON, y en JG_DISP el mismo
rem  valor con las barras sin duplicar, para mostrarlo en pantalla.
rem  Ambas quedan vacias si la clave no esta o el archivo no existe.
:jsonget
set "JG_VAL="
set "JG_DISP="
set "JG_LINE="
set "JG_FILE=%~2"
if not exist "%JG_FILE%" exit /b 0
for /f "delims=" %%L in ('findstr /i /c:"%~1" "%JG_FILE%" 2^>nul') do set "JG_LINE=%%L"
if not defined JG_LINE exit /b 0
set "JG_LINE=!JG_LINE:*: =!"
set JG_LINE=!JG_LINE:"=!
set "JG_LINE=!JG_LINE:,=!"
if not defined JG_LINE exit /b 0
set "JG_VAL=!JG_LINE!"
set "JG_DISP=!JG_VAL:\\=\!"
exit /b 0

rem :tomlget <clave> <archivo>  -> igual que :jsonget pero para lineas
rem  TOML "CLAVE = "valor"" (sin comillas en la clave).
:tomlget
set "JG_VAL="
set "JG_DISP="
set "JG_LINE="
set "JG_FILE=%~2"
if not exist "%JG_FILE%" exit /b 0
for /f "delims=" %%L in ('findstr /i /c:"%~1 =" "%JG_FILE%" 2^>nul') do set "JG_LINE=%%L"
if not defined JG_LINE exit /b 0
rem  "*= =" (dos "=") no es una sustitucion valida en cmd.exe: se corta
rem  en el primer "=" y deja el resto literal. Se corta en la comilla
rem  de apertura del valor en su lugar (misma idea, sin ese problema).
set JG_LINE=!JG_LINE:*"=!
set JG_LINE=!JG_LINE:"=!
if not defined JG_LINE exit /b 0
set "JG_VAL=!JG_LINE!"
set "JG_DISP=!JG_VAL:\\=\!"
exit /b 0

rem :scandrive <letra:>  -> escanea una unidad completa
:scandrive
set "DRV=%~1"
set "DRV=!DRV: =!"
if "!DRV!"=="" exit /b 0
echo   Explorando !DRV!\ ...
call :scan "!DRV!\"
exit /b 0

rem :scan <carpeta>  -> busca Godot*.exe recursivamente
:scan
if "%~1"=="" exit /b 0
if not exist "%~1" exit /b 0
for /f "delims=" %%F in ('dir /b /s /a-d "%~1\Godot*.exe" 2^>nul ^| findstr /i /v "_console"') do call :addcand "%%F"
exit /b 0

rem :addcand <ruta>  -> agrega candidato de Godot sin duplicados
:addcand
if "%~1"=="" exit /b 0
if not exist "%~1" exit /b 0
set "DUP="
for /l %%I in (1,1,%COUNT%) do if /i "!CAND_%%I!"=="%~1" set "DUP=1"
if defined DUP exit /b 0
set /a COUNT+=1
set "CAND_!COUNT!=%~1"
echo   [!COUNT!] %~1
exit /b 0

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
