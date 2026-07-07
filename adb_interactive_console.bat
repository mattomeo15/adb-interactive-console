@echo off
setlocal enabledelayedexpansion
title ADB Interactive Console

:: Force the script to look inside its own folder for adb.exe
cd /d "%~dp0"

:auto_check
cls
echo Checking for active or cached connection...

if not exist "adb.exe" (
    echo [ERROR] adb.exe was not found in this folder!
    echo Please place this script in your SDK Platform-Tools folder.
    echo.
    pause
    exit /b
)

:: Define default IP globally
set "ip=192.168.2.157"

:: 1. Check if ADB already sees it as a live, fully connected device
adb devices > "%temp%\adb_check.txt" 2>&1
findstr /C:"%ip%" "%temp%\adb_check.txt" >nul
if %errorlevel% equ 0 (
    findstr /I /C:"device" "%temp%\adb_check.txt" >nul
    if %errorlevel% equ 0 (
        for /f "tokens=2 delims=:" %%A in ('findstr /C:"%ip%" "%temp%\adb_check.txt"') do (
            for /f "tokens=1 delims=	 " %%B in ("%%A") do set "port=%%B"
        )
        del "%temp%\adb_check.txt"
        echo Active connection detected! Jumping straight to console...
        timeout /t 1 >nul
        goto launch_with_help
    )
)
del "%temp%\adb_check.txt"

:: 2. Try waking it up using the last known port
set "port=35123"
if exist "last_port.txt" (
    set /p port=<"last_port.txt"
)

adb connect %ip%:%port% > nul 2>&1
timeout /t 1 >nul

:: Confirm if wake-up succeeded
adb devices > "%temp%\adb_check.txt" 2>&1
findstr /C:"%ip%" "%temp%\adb_check.txt" >nul
if %errorlevel% equ 0 (
    findstr /I /C:"device" "%temp%\adb_check.txt" >nul
    if %errorlevel% equ 0 (
        del "%temp%\adb_check.txt"
        echo Cached connection restored! Jumping to console...
        timeout /t 1 >nul
        goto launch_with_help
    )
)
del "%temp%\adb_check.txt"

adb disconnect >nul 2>&1

:mode_select
cls
echo ====================================================
echo                ADB INTERACTIVE CONSOLE
echo ====================================================
echo  [1] Auto Connect (Last saved port)
echo  [2] Standard Connect (Manual Port)
echo  [3] Pair New Device
echo.
set /p mode="-> Select an option (1, 2, or 3): "

if "%mode%"=="1" goto manual_auto_check
if "%mode%"=="2" goto setup
if "%mode%"=="3" goto pairing_wizard
goto mode_select

:manual_auto_check
set "ip=192.168.2.157"
set "port=35123"
if exist "last_port.txt" (set /p port=<"last_port.txt")
adb connect %ip%:%port% > nul 2>&1
timeout /t 1 >nul
goto launch_with_help

:pairing_wizard
cls
echo --- ADB Pairing Wizard ---
set "pair_ip=192.168.2.157"
set /p user_pair_ip="-> Confirm Device IP [%pair_ip%]: "
if not "%user_pair_ip%"=="" set "pair_ip=%user_pair_ip%"
set /p pair_port="-> Enter 5-digit PAIRING port: "
set /p pair_code="-> Enter 6-digit PAIRING CODE: "
adb pair %pair_ip%:%pair_port% %pair_code%
echo Pairing successful!
set "ip=%pair_ip%"
set "port=%pair_port%"
echo %port%>"last_port.txt"
adb connect %ip%:%port% > nul 2>&1
goto launch_with_help

:setup
cls
echo --- Connect to Device ---
set "ip=192.168.2.157"
set /p user_ip="-> IP [%ip%]: "
if not "%user_ip%"=="" set "ip=%user_ip%"
set /p port="-> Port: "
adb connect %ip%:%port%
echo %port%>"last_port.txt"
goto launch_with_help

:launch_with_help
cls
echo ====================================================
echo          ADB INTERACTIVE CONSOLE - CONNECTED
echo ====================================================
goto inline_help

:inline_help
echo  CONNECTED TO: %ip%:%port%
echo  --------------------------------------------------
echo  help    - Show this menu         reboot  - Restart
echo  clear   - Wipe history           apps    - List user apps
echo  status  - Check status           sysapps - List system apps
echo  ver     - Show ADB version       install - Install APK
echo  disc    - Disconnect             recon   - Reconnect
echo  opts    - Pairing Menu           exit    - Close
echo  --------------------------------------------------
goto cmdloop

:cmdloop
set "usercmd="
set /p usercmd="ADB-Console> "
if "%usercmd%"=="" goto cmdloop
if /i "%usercmd%"=="help" goto inline_help
if /i "%usercmd%"=="clear" cls & goto inline_help
if /i "%usercmd%"=="status" (adb devices & goto cmdloop)
if /i "%usercmd%"=="ver" (adb version & goto cmdloop)
if /i "%usercmd%"=="reboot" (adb reboot & goto cmdloop)
if /i "%usercmd%"=="apps" (adb shell pm list packages -3 & goto cmdloop)
if /i "%usercmd%"=="sysapps" (adb shell pm list packages -s & goto cmdloop)
if /i "%usercmd%"=="install" goto do_install
if /i "%usercmd%"=="recon" goto setup
if /i "%usercmd%"=="opts" goto mode_select
if /i "%usercmd%"=="disc" (adb disconnect & goto cmdloop)
if /i "%usercmd%"=="exit" (adb disconnect & exit)
echo.
%usercmd%
echo.
goto cmdloop

:do_install
set /p "apkpath=-> Drag & drop APK file here: "
set "apkpath=%apkpath:"=%"
echo Installing "%apkpath%"...
adb install "%apkpath%"
goto cmdloop