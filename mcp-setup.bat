@echo off
setlocal EnableDelayedExpansion
title Setup MCP - Super Smash Tux

rem ============================================================
rem  mcp-setup.bat
rem  Configura los servidores MCP del proyecto y genera el
rem  archivo .mcp.json.
rem
rem    godot   -> godot-mcp (npx), necesita Node.js 18+
rem    blender -> MCP oficial de Blender (uvx + add-on)
rem
rem  Uso:
rem    mcp-setup.bat                          -> menu interactivo
rem    mcp-setup.bat "D:\Godot\Godot.exe"     -> ruta de Godot manual
rem    mcp-setup.bat "godot.exe" "blender.exe"-> ambas rutas manuales
rem
rem  Con rutas por parametro se omite el menu y se configura todo.
rem  Al elegir un solo servidor, el otro se conserva leyendo el
rem  .mcp.json que ya exista, para no perder configuracion.
rem ============================================================

set "PROJECT_DIR=%~dp0"
set "TARGET=%PROJECT_DIR%.mcp.json"
set "GODOT_EXE="
set "BLENDER_EXE="
set "BLENDER_ARG=%~2"
set "COUNT=0"
set "BCOUNT=0"
set "BEST_VER=0"

rem  Rutas ya escapadas para JSON. Si quedan vacias, ese servidor
rem  no se escribe en el archivo.
set "GODOT_JSON="
set "BLENDER_JSON="

set "DO_GODOT="
set "DO_BLENDER="

rem  "<" no se puede escribir directo en un echo redirigido: cmd lo toma
rem  como redireccion de entrada. Se expande tarde, via !LT!.
set LT=^<

echo.
echo === Setup MCP - Super Smash Tux ===
echo Proyecto: %PROJECT_DIR%

rem ============================================================
rem  MENU
rem ============================================================

rem Con parametros se asume modo no interactivo: configurar todo.
if not "%~1"=="" goto :modo_todo

echo.
echo Estado actual:
call :jsonget "GODOT_PATH"
if defined JG_VAL echo   [x] godot    ^| !JG_DISP!
if not defined JG_VAL echo   [ ] godot    ^| sin configurar
call :jsonget "BLENDER_PATH"
if defined JG_VAL echo   [x] blender  ^| !JG_DISP!
if not defined JG_VAL echo   [ ] blender  ^| sin configurar

rem  Se usa set /p y no choice: choice solo acepta las teclas de /c,
rem  descarta cualquier otra y hace sonar un pitido sin dejar escribir.
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
if "!OPCION!"=="4" goto :salir

rem  El contador evita un bucle infinito cuando no hay entrada que leer
rem  (por ejemplo si el script se ejecuta con la entrada redirigida):
rem  ahi set /p retorna sin definir nada y siempre caeria aca.
:opcion_invalida
set /a TRIES+=1
if !TRIES! GEQ 5 goto :demasiados_intentos
echo.
echo [ERROR] Opcion invalida. Escribe un numero del 1 al 4 y pulsa Enter.
goto :menu_opciones

:demasiados_intentos
echo.
echo [FALLO] Demasiadas opciones invalidas. No se modifico el archivo .mcp.json.
echo.
pause
endlocal
exit /b 1

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

rem ---- Lo que no se reconfigura se rescata del archivo actual --
:inicio
if defined DO_GODOT goto :rescate_blender
call :jsonget "GODOT_PATH"
if not defined JG_VAL goto :rescate_blender
set "GODOT_JSON=!JG_VAL!"
echo.
echo [=] Se conserva la configuracion de Godot existente.

:rescate_blender
if defined DO_BLENDER goto :parte_godot
call :jsonget "BLENDER_PATH"
if not defined JG_VAL goto :parte_godot
set "BLENDER_JSON=!JG_VAL!"
echo [=] Se conserva la configuracion de Blender existente.

rem ============================================================
rem  PARTE 1 - GODOT
rem ============================================================
:parte_godot
if not defined DO_GODOT goto :parte_blender

echo.
echo === Godot MCP ===

rem ---- 1) Ruta pasada por parametro -------------------------
if "%~1"=="" goto :sin_parametro
if not exist "%~1" goto :param_malo
set "GODOT_EXE=%~1"
echo [OK] Ruta de Godot indicada por parametro.
goto :godot_listo

:param_malo
echo [ERROR] La ruta indicada no existe: %~1
goto :fail

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
if not defined PICK goto :fail
set "GODOT_EXE=!CAND_%PICK%!"
if not defined GODOT_EXE goto :pick_malo
goto :godot_listo

:pick_malo
echo [ERROR] Opcion invalida.
goto :fail

rem ---- Entrada manual ---------------------------------------
:manual
echo.
echo No se pudo detectar Godot automaticamente.
set "GODOT_EXE="
set /p "GODOT_EXE=Escribe la ruta completa al ejecutable de Godot: "
if not defined GODOT_EXE goto :fail
set "GODOT_EXE=!GODOT_EXE:"=!"
if not exist "!GODOT_EXE!" goto :ruta_mala
goto :godot_listo

:ruta_mala
echo [ERROR] La ruta no existe.
goto :fail

:godot_listo
if not exist "!GODOT_EXE!" goto :no_exe
rem Duplicar las barras invertidas para JSON
set "GODOT_JSON=!GODOT_EXE:\=\\!"

rem ============================================================
rem  PARTE 2 - BLENDER
rem  El MCP oficial de Blender son DOS piezas que hablan por
rem  socket TCP: el add-on dentro de Blender (puerto 9876) y el
rem  servidor "blender-mcp", que lanza el cliente MCP por stdio.
rem ============================================================
:parte_blender
if not defined DO_BLENDER goto :write

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
goto :write

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
goto :write

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
echo         Suele bastar con abrir una consola nueva; el .mcp.json se genera igual.
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
tasklist /fi "imagename eq blender.exe" 2>nul | find /i "blender.exe" >nul
if errorlevel 1 goto :blender_addon_ok
echo.
echo [AVISO] Blender esta abierto. Instalar el add-on ahora no serviria:
echo         al cerrarse, esa instancia pisa las preferencias y se pierde.
echo         Cierra Blender y vuelve a ejecutar este script.
goto :write

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
goto :write

:blender_addon_fallo
echo   [AVISO] No se pudo confirmar la instalacion del add-on.
echo           Instalacion manual: Edit ^> Preferences ^> Get Extensions,
echo           agrega el repositorio https://lab.blender.org/ y busca "MCP".

rem ============================================================
rem  PARTE 3 - Escritura del .mcp.json
rem ============================================================
:write
if not defined GODOT_JSON if not defined BLENDER_JSON goto :nada_que_escribir

> "%TARGET%" echo {
>>"%TARGET%" echo   "mcpServers": {
if not defined GODOT_JSON goto :write_blender

>>"%TARGET%" echo     "godot": {
>>"%TARGET%" echo       "command": "npx",
>>"%TARGET%" echo       "args": ["@coding-solo/godot-mcp"],
>>"%TARGET%" echo       "env": {
>>"%TARGET%" echo         "GODOT_PATH": "!GODOT_JSON!"
>>"%TARGET%" echo       }
if defined BLENDER_JSON goto :write_coma
>>"%TARGET%" echo     }
goto :write_cierre

:write_coma
>>"%TARGET%" echo     },

:write_blender
if not defined BLENDER_JSON goto :write_cierre
rem  --refresh   : uv vuelve a resolver el repo en cada arranque (auto-update).
rem  mcp[cli] "<"2: el pyproject oficial pide "mcp>=1.2.0" sin tope y mcp 2.x
rem                 renombro FastMCP, lo que rompe el servidor.
>>"%TARGET%" echo     "blender": {
>>"%TARGET%" echo       "command": "uvx",
>>"%TARGET%" echo       "args": [
>>"%TARGET%" echo         "--refresh",
>>"%TARGET%" echo         "--with",
>>"%TARGET%" echo         "mcp[cli]!LT!2",
>>"%TARGET%" echo         "--from",
>>"%TARGET%" echo         "git+https://projects.blender.org/lab/blender_mcp.git#subdirectory=mcp",
>>"%TARGET%" echo         "blender-mcp"
>>"%TARGET%" echo       ],
>>"%TARGET%" echo       "env": {
>>"%TARGET%" echo         "BLENDER_MCP_HOST": "localhost",
>>"%TARGET%" echo         "BLENDER_MCP_PORT": "9876",
>>"%TARGET%" echo         "BLENDER_PATH": "!BLENDER_JSON!"
>>"%TARGET%" echo       }
>>"%TARGET%" echo     }

:write_cierre
>>"%TARGET%" echo   }
>>"%TARGET%" echo }

rem  En pantalla se muestran las rutas reales, no las escapadas del JSON.
set "GODOT_DISP=!GODOT_JSON:\\=\!"
set "BLENDER_DISP=!BLENDER_JSON:\\=\!"

echo.
echo [LISTO] .mcp.json generado.
if defined GODOT_JSON echo   godot    ^| !GODOT_DISP!
if not defined GODOT_JSON echo   godot    ^| sin configurar
if defined BLENDER_JSON echo   blender  ^| !BLENDER_DISP!
if not defined BLENDER_JSON echo   blender  ^| sin configurar
echo.
if defined BLENDER_JSON echo Abre Blender antes de usar sus herramientas: el add-on levanta
if defined BLENDER_JSON echo el servidor en localhost:9876 al arrancar.
echo Reinicia tu agente de codigo para que tome la configuracion del MCP.
echo.
pause
endlocal
exit /b 0

:nada_que_escribir
echo.
echo [FALLO] No hay ningun servidor que configurar.
echo         No se modifico el archivo .mcp.json.
echo.
pause
endlocal
exit /b 1

:no_exe
echo [ERROR] El ejecutable no existe: !GODOT_EXE!

:fail
echo.
echo [FALLO] No se genero el archivo .mcp.json.
echo.
pause
endlocal
exit /b 1

rem ---- Subrutinas -------------------------------------------

rem :jsonget <clave>  -> deja en JG_VAL el valor de esa clave del
rem  .mcp.json actual, ya escapado para JSON, y en JG_DISP el mismo
rem  valor con las barras sin duplicar, para mostrarlo en pantalla.
rem  Ambas quedan vacias si la clave no esta.
:jsonget
set "JG_VAL="
set "JG_DISP="
set "JG_LINE="
if not exist "%TARGET%" exit /b 0
for /f "delims=" %%L in ('findstr /i /c:"%~1" "%TARGET%" 2^>nul') do set "JG_LINE=%%L"
if not defined JG_LINE exit /b 0
set "JG_LINE=!JG_LINE:*: =!"
set JG_LINE=!JG_LINE:"=!
set "JG_LINE=!JG_LINE:,=!"
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
