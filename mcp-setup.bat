@echo off
setlocal EnableDelayedExpansion
title Setup MCP - Super Smash Tux

rem ============================================================
rem  mcp-setup.bat
rem  Busca el ejecutable de Godot en el sistema y genera el
rem  archivo .mcp.json con la ruta encontrada en GODOT_PATH.
rem
rem  Uso:
rem    mcp-setup.bat                      -> busqueda automatica
rem    mcp-setup.bat "D:\Godot\Godot.exe" -> ruta manual
rem ============================================================

set "PROJECT_DIR=%~dp0"
set "TARGET=%PROJECT_DIR%.mcp.json"
set "GODOT_EXE="
set "COUNT=0"

echo.
echo === Setup MCP - Super Smash Tux ===
echo Proyecto: %PROJECT_DIR%
echo.

rem ---- 1) Ruta pasada por parametro -------------------------
if "%~1"=="" goto :sin_parametro
if not exist "%~1" goto :param_malo
set "GODOT_EXE=%~1"
echo [OK] Ruta indicada por parametro.
goto :write

:param_malo
echo [ERROR] La ruta indicada no existe: %~1
goto :fail

:sin_parametro
rem ---- 2) Variable de entorno GODOT_PATH ---------------------
if not defined GODOT_PATH goto :buscar
if not exist "%GODOT_PATH%" goto :buscar
set "GODOT_EXE=%GODOT_PATH%"
echo [OK] Encontrado en la variable de entorno GODOT_PATH.
goto :write

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
if not %COUNT% EQU 1 goto :menu
set "GODOT_EXE=!CAND_1!"
echo.
echo [OK] Godot encontrado: !GODOT_EXE!
goto :write

:menu
echo.
echo Se encontraron %COUNT% ejecutables de Godot:
for /l %%I in (1,1,%COUNT%) do echo   [%%I] !CAND_%%I!
echo.
set "PICK="
set /p "PICK=Numero a usar (1-%COUNT%): "
if not defined PICK goto :fail
set "GODOT_EXE=!CAND_%PICK%!"
if not defined GODOT_EXE goto :pick_malo
goto :write

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
goto :write

:ruta_mala
echo [ERROR] La ruta no existe.
goto :fail

rem ---- Escritura del .mcp.json -------------------------------
:write
if not exist "!GODOT_EXE!" goto :no_exe

rem Duplicar las barras invertidas para JSON
set "JSON_PATH=!GODOT_EXE:\=\\!"

if not exist "%TARGET%" goto :sin_backup
copy /y "%TARGET%" "%TARGET%.bak" >nul
echo Respaldo creado: .mcp.json.bak

:sin_backup
> "%TARGET%" echo {
>>"%TARGET%" echo   "mcpServers": {
>>"%TARGET%" echo     "godot": {
>>"%TARGET%" echo       "command": "npx",
>>"%TARGET%" echo       "args": ["@coding-solo/godot-mcp"],
>>"%TARGET%" echo       "env": {
>>"%TARGET%" echo         "GODOT_PATH": "!JSON_PATH!"
>>"%TARGET%" echo       }
>>"%TARGET%" echo     }
>>"%TARGET%" echo   }
>>"%TARGET%" echo }

echo.
echo [LISTO] .mcp.json generado.
echo   GODOT_PATH = !GODOT_EXE!
echo.
echo Reinicia Claude Code para que tome la configuracion del MCP.
echo.
pause
endlocal
exit /b 0

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

rem :addcand <ruta>  -> agrega candidato sin duplicados
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
