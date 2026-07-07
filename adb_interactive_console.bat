@echo off
setlocal enabledelayedexpansion
title Chromecast ADB Control Panel

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

:: Define default IP globally right at startup
set "ip=192.168.2.157"

:: 1. Check if ADB already sees it as a live, fully connected device right now
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

:: 2. If not instantly live, try waking it up using the last known good port
set "port=35123"
if exist "last_port.txt" (
    set /p port=<"last_port.txt"
)

adb connect %ip%:%port% > nul 2>&1
timeout /t 1 >nul

:: Confirm if that background wake-up actually succeeded
adb devices > "%temp%\adb_check.txt" 2>&1
findstr /C:"%ip%" "%temp%\adb_check.txt" >nul
if %errorlevel% equ 0 (
    findstr /I /C:"device" "%temp%\adb_check.txt" >nul
    if %errorlevel% equ 0 (
        del "%temp%\adb_check.txt"
        echo Cached connection restored successfully! Jumping straight to console...
        timeout /t 1 >nul
        goto launch_with_help
    )
)
del "%temp%\adb_check.txt"

:: If everything truly failed, clear out stale broken sessions before showing menu
adb disconnect >nul 2>&1

:mode_select
cls
echo ====================================================
echo                CHROMECAST ADB HELPER
echo ====================================================
echo --- ADB Pairing Options ---
echo.
echo  TV NAVIGATION GUIDE:
echo   Settings -^> System -^> Developer Options -^> Wireless Debugging
echo.
echo  BEFORE SELECTING AN OPTION:
echo   Look at the "Paired devices" list at the bottom of your 
echo   TV screen. If your PC is listed there, choose Option 1 or 2. 
echo   If your PC is missing, choose Option 3.
echo.
echo ----------------------------------------------------
echo  [1] Auto Connect (Quick connect using last saved port)
echo  [2] Standard Connect (Device is already paired - Manual Port)
echo  [3] Pair New Device (First time setup / Re-pairing)
echo.
set /p mode="-> Select an option (1, 2, or 3): "

if "%mode%"=="1" goto manual_auto_check
if "%mode%"=="2" goto setup
if "%mode%"=="3" goto pairing_wizard
echo [!] Invalid choice. Please type 1, 2, or 3.
timeout /t 2 >nul
goto mode_select

:manual_auto_check
cls
echo Initiating Auto Connect routine...
set "ip=192.168.2.157"
set "port=35123"
if exist "last_port.txt" (
    set /p port=<"last_port.txt"
)

echo Attempting background bridge to %ip%:%port%...
adb connect %ip%:%port% > nul 2>&1
timeout /t 1 >nul

adb devices > "%temp%\adb_manual_check.txt" 2>&1
findstr /C:"%ip%" "%temp%\adb_manual_check.txt" >nul
if %errorlevel% equ 0 (
    findstr /I /C:"device" "%temp%\adb_manual_check.txt" >nul
    if %errorlevel% equ 0 (
        del "%temp%\adb_manual_check.txt"
        echo Auto Connect successful! Dropping into console...
        timeout /t 1 >nul
        goto launch_with_help
    )
)
del "%temp%\adb_manual_check.txt"

echo.
echo ----------------------------------------------------
echo  [!] AUTO CONNECT FAILED.
echo  The saved port (%port%) is invalid or expired.
echo ----------------------------------------------------
echo.
echo  [1] Try Manual Connection (Enter a new port)
echo  [2] Return to Main Menu
echo.
:manual_fail_choice
set /p m_fail_opt="-> Select an option (1 or 2): "
if "%m_fail_opt%"=="1" goto setup
if "%m_fail_opt%"=="2" goto mode_select
echo [!] Invalid choice. Please type 1 or 2.
goto manual_fail_choice

:pairing_wizard
cls
echo ====================================================
echo                CHROMECAST ADB HELPER
echo ====================================================
echo --- ADB Pairing Wizard ---
echo.
echo  TV ACTION:
echo   Under Wireless Debugging, click:
echo   -^> "Pair device with pairing code"
echo.
echo ----------------------------------------------------
set "pair_ip=192.168.2.157"
set /p user_pair_ip="-> Confirm TV IP [%pair_ip%]: "
if not "%user_pair_ip%"=="" set "pair_ip=%user_pair_ip%"

echo.
set /p pair_port="-> Enter the 5-digit PAIRING port from the popup: "
echo.
set /p pair_code="-> Enter the 6-digit PAIRING CODE from the popup: "

echo.
echo Attempting to pair with %pair_ip%:%pair_port%...

:: Run pairing and log the output to temporary file
adb pair %pair_ip%:%pair_port% %pair_code% > "%temp%\adb_pair_status.txt" 2>&1
timeout /t 1 >nul
type "%temp%\adb_pair_status.txt"

findstr /I /C:"Successfully paired" "%temp%\adb_pair_status.txt" >nul
if %errorlevel% neq 0 (
    echo.
    echo ----------------------------------------------------
    echo  [!] PAIRING FAILED.
    echo  Please check your pairing code and pairing port.
    echo ----------------------------------------------------
    echo.
    echo Press any key to return to the main menu...
    pause >nul
    del "%temp%\adb_pair_status.txt"
    goto mode_select
)

del "%temp%\adb_pair_status.txt"

echo.
echo Pairing successful! Seamlessly connecting to console...
set "ip=%pair_ip%"
set "port=%pair_port%"

:: Save the port for future auto-connections
echo %port%>"last_port.txt"

:: Run direct connection using the authenticated port
adb connect %ip%:%port% > nul 2>&1
timeout /t 1 >nul
goto launch_with_help

:setup
cls
echo ====================================================
echo                CHROMECAST ADB HELPER
echo ====================================================
echo --- Connect to Already Paired Device ---
echo.
echo  TV NAVIGATION PATH:
echo   Settings - System - Developer Options - Wireless Debugging
echo   -^> Look at "IP address ^& Port" on the main toggle screen
echo.
echo ----------------------------------------------------

:: 1. Handle the IP Address
set "ip=192.168.2.157"
echo Default IP: %ip%
set /p user_ip="-> Press ENTER to accept default, or type a new IP: "
if not "%user_ip%"=="" set "ip=%user_ip%"

echo.

:: 2. Handle the Port
set "port="
:port_input
set /p port="-> Enter the 5-digit port from your TV (e.g., 35123): "

if "%port%"=="" (
    echo [!] Port cannot be blank. Please look at your TV screen.
    goto port_input
)

echo.
echo ====================================================
echo  CONFIRM CONNECTION DETAILS:
echo  Target Device: %ip%:%port%
echo ====================================================
echo.
echo  Press any key to initiate connection...
pause >nul

echo.
echo Connecting to %ip%:%port%...

:: Run connection directly to terminal window display
adb connect %ip%:%port%
timeout /t 1 >nul

:: Direct hardware verification check via adb devices list
adb devices > "%temp%\adb_status.txt" 2>&1

:: Check if our IP exists in the device output list AND it says "device"
findstr /C:"%ip%:%port%" "%temp%\adb_status.txt" >nul
if %errorlevel% equ 0 (
    findstr /I /C:"device" "%temp%\adb_status.txt" >nul
    if %errorlevel% equ 0 (
        goto connection_success
    )
)

echo.
echo ----------------------------------------------------
echo  [!] CONNECTION FAILED.
echo  The Chromecast refused the link or the port expired.
echo ----------------------------------------------------
echo.
echo  [1] Retry Connection (Return to device setup)
echo  [2] Go to Pairing Options (Main Menu)
echo.
del "%temp%\adb_status.txt"

:fail_choice
set /p fail_opt="-> Select an option (1 or 2): "
if "%fail_opt%"=="1" goto setup
if "%fail_opt%"=="2" goto mode_select
echo [!] Invalid choice. Please type 1 or 2.
goto fail_choice

:connection_success
del "%temp%\adb_status.txt"

:: Save this successful port to use next time the file runs
echo %port%>"last_port.txt"

echo.
echo Connection successful! Moving to console...
timeout /t 1 >nul
goto launch_with_help

:launch_with_help
cls
echo ====================================================
echo             CHROMECAST ADB INTERACTIVE CONSOLE
echo ====================================================
echo        (type "help" to show helper menu)
echo.
goto inline_help

:clear_screen
echo ====================================================
echo             CHROMECAST ADB INTERACTIVE CONSOLE
echo ====================================================
echo        (type "help" to show helper menu)
echo.
goto cmdloop

:inline_help
echo ====================================================
echo  CONNECTED TO: %ip%:%port%
echo ====================================================
echo  BAKED-IN SHORTCUTS:
echo   help    - Show this helper menu
echo   clear   - Wipe the terminal history clean
echo   status  - Check ADB connection array summary
echo   ver     - Check running local ADB server version
echo   reboot  - Remotely reboot target Android TV device
echo   apps    - Fast array audit of sideloaded user apps
echo   sysapps - Fast array audit of deep system core apps
echo   install - Safely push an APK archive into the device
echo   disc    - Disconnect ADB connection (Stay in Console)
echo   recon   - Restart connection process (Change IP/Port)
echo   opts    - Return to Pairing Options Page
echo   exit    - Disconnect ADB connection and close terminal
echo ====================================================
echo  * Type any standard ADB command directly below.
echo ====================================================
echo.
goto cmdloop

:cmdloop
set "usercmd="
set /p usercmd="ADB-Console> "

:: Intercept empty entries or custom shortcuts
if "%usercmd%"=="" goto cmdloop
if /i "%usercmd%"=="help" echo. & goto inline_help
if /i "%usercmd%"=="clear" cls & goto clear_screen
if /i "%usercmd%"=="status" echo. & adb devices & echo. & goto cmdloop
if /i "%usercmd%"=="ver" echo. & adb version & echo. & goto cmdloop
if /i "%usercmd%"=="reboot" echo. & adb reboot & echo. & goto cmdloop
if /i "%usercmd%"=="apps" echo. & adb shell pm list packages -3 & echo. & goto cmdloop
if /i "%usercmd%"=="sysapps" echo. & adb shell pm list packages -s & echo. & goto cmdloop
if /i "%usercmd%"=="install" goto do_install
if /i "%usercmd%"=="recon" goto reconnect
if /i "%usercmd%"=="opts" goto go_options
if /i "%usercmd%"=="disc" goto just_disconnect
if /i "%usercmd%"=="exit" goto full_exit

:: If it's not a shortcut, process it as a raw terminal command
echo.
%usercmd%
echo.
goto cmdloop

:do_install
echo.
set /p "apkpath=-> Drag & drop APK file here: "
set "apkpath=%apkpath:"=%"
echo Installing "%apkpath%"...
echo.
adb install "%apkpath%"
echo.
goto cmdloop

:just_disconnect
echo.
echo Severing ADB connection...
adb disconnect
echo Bridge disconnected. Ready for manual commands or 'recon'.
echo.
goto cmdloop

:reconnect
echo.
echo Tearing down current bridge...
adb disconnect
echo Heading back to configuration wizard...
timeout /t 1 >nul
goto setup

:go_options
echo.
echo Tearing down current bridge...
adb disconnect
echo Heading back to Pairing Options menu...
timeout /t 1 >nul
goto mode_select

:full_exit
echo.
echo Disconnecting bridge...
adb disconnect
echo Exiting safely.
timeout /t 1 >nul
exit
