@echo off
Setlocal EnableDelayedExpansion

if "%1"=="install" goto addappinit
if "%1"=="uninstall" goto delappinit

>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
  echo Requesting administrative privileges...
  goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

echo ---------------------------------------------
echo Checking machine
echo ---------------------------------------------
reg query HKLM\Hardware\Description\System\CentralProcessor\0 | Find /i "x86" >nul
if not errorlevel 1 (
  echo You appear to be running this installation on a 32bit machine.
  echo This NTVDMx64 is only meant to be used on an x64 machine, please use 
  echo NTVDM shipped with your windows installation instead.
  echo Installation aborted
  goto fini
)

for /F "skip=2 tokens=3" %%r in ('reg query HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\State /v UEFISecureBootEnabled') do if "%%r"=="0x1" (
  echo It seems that your machine has secure boot feature enabled.
  echo This prevents our AppInit_DLL loader from working properly and 
  echo therefore prevents start of NTVDM.
  echo Please disabe secure boot in BIOS, reboot and try again
  start https://msdn.microsoft.com/en-us/windows/hardware/commercialize/manufacture/desktop/disabling-secure-boot
  goto fini
)

cls
echo ---------------------------------------------
echo Installing, please wait...
echo ---------------------------------------------
echo Please check for completion-message from installer in taskbar.
rundll32.exe advpack.dll,LaunchINFSection %CD%\ntvdmx64.inf
goto fini

:addappinit
set AppInit=
for /F "skip=2 tokens=2*" %%r in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs') do set AppInit=%AppInit%%%s
echo %AppInit% | findstr /I /C:ldntvdm.dll >nul
if not "%AppInit%"=="" set AppInit=%AppInit% 
if errorlevel 1 reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /f /d "%AppInit% ldntvdm.dll"
set AppInit=
goto fini

:delappinit
set AppInit=
for /F "skip=2 tokens=2*" %%r in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs') do (
  for %%t in (%%s) do if not "%%t"=="ldntvdm.dll" set AppInit=!AppInit!%%t 
)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /f /d "%AppInit%"
set AppInit=
goto fini

:fini