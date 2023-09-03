@echo off
::--------------------------------------------------------------------------------------------------------------------- 
:: AirExplorer Pro - Firewall Blocker - By Nguyen Trung Hieu @2021
::--------------------------------------------------------------------------------------------------------------------- 
:: Reset License Key:		https://airexplorer.net/store/license/ 
:: Download Offline Installer:	https://www.airexplorer.net/downloads/AirExplorer-OnlineInstaller.exe
::--------------------------------------------------------------------------------------------------------------------- 
::--------------------------------------------------------------------------------------------------------------------- 
:: BatchGotAdmin
:--------------------------------------- 
::  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
:: --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~f0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
@echo off
setlocal EnableDelayedExpansion
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )

:GETIP
for /f "tokens=1,2 delims=[]" %%a IN ('ping -4 -n 1 airexplorer.net') DO (if "%%b" NEQ "" set ip=%%b)

:KILL
taskkill /f /im AirExplorer.exe > nul 2>&1
taskkill /f /im AirExplorerCmd.exe> nul 2>&1
GOTO START

:DELETE
attrib -h -r -s -a "%AppData%\AirExplorer\license.xml" >nul
del /f  "%AppData%\AirExplorer\license*"

:START
echo.
echo. ##################################################
echo. # AirExplorer (%IP%) Firewall Blocker   #
echo. ##################################################
echo.
SET RULE_NAME="AirExplorer"
netsh advfirewall firewall show rule name=%RULE_NAME% >nul
if not ERRORLEVEL 1 (
    echo Rule %RULE_NAME% already exists. Deleting...
    netsh advfirewall firewall delete rule name=%RULE_NAME%
)
echo Rule %RULE_NAME% is Creating...
netsh advfirewall firewall add rule name=%RULE_NAME% dir=in action=block program="%ProgramFiles%\AirExplorer\AirExplorer.exe" description="Rule for AirExplorer" remoteip=%IP%
netsh advfirewall firewall add rule name=%RULE_NAME% dir=out action=block program="%ProgramFiles%\AirExplorer\AirExplorer.exe" description="Rule for AirExplorer" remoteip=%IP%
copy "%AppData%\AirExplorer\license.xml" "%AppData%\AirExplorer\license.bak" >nul 2>&1
attrib +h +r +s +a "%AppData%\AirExplorer\license.xml" >nul 2>&1
attrib +h +r +s +a "%AppData%\AirExplorer\license.bak" >nul 2>&1

:STARTUNLOCK
if not exist "%Windir%\system32\curl.exe" (GOTO END)
echo.
echo. ####################################
echo. #    Air Explorer unlock license   #
echo. ####################################
:SETUNLOCK
echo.
SET /p email="Enter email: "
SET /p code="License code: "
if %email%=="" (GOTO END)
if %code% == "" (GOTO END)
CALL :UNLOCK %email%, %code%

:UNLOCK %~1 %~2
echo.
set email=%~1
set code =%~2
set _cURL_cmd=curl -s -X POST --url https://airexplorer.net/store/license/ -d "email=%email%&code=%code%"
%_cURL_cmd%|findstr Invalid
if %ERRORLEVEL% == 0 (GOTO SETUNLOCK)
%_cURL_cmd%|findstr activate
if %ERRORLEVEL% == 0 (GOTO END)
echo.
echo. Your unlock request is being processed, you will receive an email at %email% when the license is unlocked. Check your spam folder if you can not find it.
echo.
echo. =^>Check again after 120s....
timeout /t 120 /nobreak
CALL :UNLOCK %email%, %code%

:END
timeout /t 15 /nobreak
DEL "%~f0"
EXIT