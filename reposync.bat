@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: REPOSYNC - The Ultimate Git Sync Utility (v2.2)
:: MIT License - Copyright (c) 2026 cijamie
:: ================================================================

:: 1. Enable ANSI Escape Codes (Windows 10+)
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
if not defined ESC set "ESC= "

set "G=%ESC%[92m"  & :: Green
set "R=%ESC%[91m"  & :: Red
set "C=%ESC%[96m"  & :: Cyan
set "Y=%ESC%[93m"  & :: Yellow
set "M=%ESC%[95m"  & :: Magenta
set "W=%ESC%[0m"   & :: White/Reset
set "B=%ESC%[5m"   & :: Blink (may not work in all terminals)

:: 2. Argument Parsing
set "ARG1=%~1"
set "IS_DRY=0"
if /i "%ARG1%"=="--dry" set "IS_DRY=1"
if /i "%ARG1%"=="-d" set "IS_DRY=1"

:: 3. Pre-Check: Is Git installed?
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo %R%[ERROR]%W% Git is not installed or not in your PATH.
    pause
    exit /b 1
)

:: 4. Dynamic Identity Detection
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%i"
if "%REPO_ROOT%"=="" (
    echo %R%[ERROR]%W% This folder is not a Git repository.
    pause
    exit /b 1
)

:: Try to detect upstream tracking branch
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref @{u} 2^>nul') do set "UPSTREAM=%%i"
if defined UPSTREAM (
    for /f "tokens=1 delims=/" %%a in ("%UPSTREAM%") do set "REMOTE=%%a"
    for /f "tokens=1,* delims=/" %%a in ("%UPSTREAM%") do set "BRANCH=%%b"
) else (
    for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set "BRANCH=%%i"
    for /f "tokens=*" %%i in ('git remote 2^>nul ^| findstr "origin"') do set "REMOTE=%%i"
    if "!REMOTE!"=="" (for /f "tokens=*" %%i in ('git remote 2^>nul') do set "REMOTE=%%i")
)

title RepoSync v2.2 - %BRANCH% @ %REMOTE%
echo %C%================================================================%W%
echo           %G%REPOSYNC v2.2 - ELITE SYNC UTILITY%W%
echo           Target: %Y%%BRANCH%%W% on %Y%%REMOTE%%W%
echo %C%================================================================%W%

:: 5. Production Branch Warning
set "IS_PROD=0"
if /i "%BRANCH%"=="main" set "IS_PROD=1"
if /i "%BRANCH%"=="master" set "IS_PROD=1"
if /i "%BRANCH%"=="prod" set "IS_PROD=1"

if %IS_PROD% equ 1 (
    echo %R%%B%[WARNING]%W% You are on a %R%PRODUCTION%W% branch (%Y%%BRANCH%%W%).
    echo           Please triple-check your changes.
    echo.
)

if %IS_DRY% equ 1 (
    echo %M%[DRY-RUN MODE]%W% No changes will be applied.
    echo.
)

:: 6. Self-Healing: Check for "Stale" States
if exist "%REPO_ROOT%\.git\rebase-merge" (
    echo %R%[ALERT]%W% A previous rebase was interrupted.
    if %IS_DRY% equ 0 (
        set /p fix="Resolve and continue? (y/n): "
        if /i "!fix!"=="y" (
            git rebase --continue
        ) else (
            echo %Y%[ABORT]%W% Resolve manually with 'git rebase --abort'.
            pause
            exit /b 1
        )
    ) else (
        echo %M%[DRY]%W% Would suggest resolving rebase.
    )
)

:: Check for existing "TEMP" commit from previous failed run
git log -1 --pretty=format:%%s | findstr "TEMP: RepoSync auto-save" >nul
if %errorlevel% equ 0 (
    echo %Y%[RECOVERY]%W% Found a leftover 'TEMP' commit. 
    if %IS_DRY% equ 0 (
        echo      Removing it safely...
        git reset --soft HEAD~1
    ) else (
        echo %M%[DRY]%W% Would remove TEMP commit.
    )
)

:: 7. Pre-flight Connection Check
echo [%C%0/7%W%] Verifying remote connectivity...
git ls-remote --exit-code %REMOTE% >nul 2>&1
if %errorlevel% neq 0 (
    echo %R%[ERROR]%W% Remote '%REMOTE%' is unreachable. Check internet/credentials.
    pause
    exit /b 1
)

:: 8. Sync Logic
echo [%C%1/7%W%] Detecting repo state...
git status --porcelain | findstr . >nul
if %errorlevel% neq 0 (
    echo      No local changes detected.
    goto :pull_only
)

echo [%C%2/7%W%] %Y%Changes detected%W% - creating temp commit...
if %IS_DRY% equ 0 (
    git add -A
    git commit -m "TEMP: RepoSync auto-save" || goto :pull_only
) else (
    echo %M%[DRY]%W% Would create temp commit.
)

:staged
echo [%C%3/7%W%] Pulling from %REMOTE%/%BRANCH% (rebase)...
if %IS_DRY% equ 0 (
    git pull --rebase %REMOTE% %BRANCH%
    if !errorlevel! neq 0 (
        echo.
        echo %R%[CONFLICT]%W% Resolve manually: %Y%git add . ^&^& git rebase --continue%W%
        pause
        exit /b 1
    )
) else (
    echo %M%[DRY]%W% Would pull with rebase.
)

echo [%C%4/7%W%] Removing temp commit...
if %IS_DRY% equ 0 (
    git reset --soft HEAD~1
) else (
    echo %M%[DRY]%W% Would remove temp commit.
)

:pull_only
echo [%C%5/7%W%] Checking for final changes...
git status --porcelain | findstr . >nul
if %errorlevel% neq 0 (
    echo      No changes to commit.
    goto :push
)

:: 9. Change Summary & Final Commit
echo.
echo %G%[ CHANGELOG SUMMARY ]%W%
git status --short
echo.

echo [%C%6/7%W%] %G%Ready to commit%W%...
set "msg=%ARG1%"
if /i "%msg%"=="--dry" set "msg="
if /i "%msg%"=="-d" set "msg="

if not defined msg (
    set /p msg="[%G%ENTER COMMIT MESSAGE%W% (blank for auto)]: "
) else (
    echo      Using argument: %Y%!msg!%W%
)

:: Robust ISO-8601 Timestamp
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "TS=%%i"
if "%msg%"=="" set "msg=Update %TS%"

if %IS_DRY% equ 0 (
    git add -A
    git commit -m "!msg!"
) else (
    echo %M%[DRY]%W% Would commit: !msg!
)

:push
echo [%C%7/7%W%] Pushing to %REMOTE%/%BRANCH%...
if %IS_DRY% equ 0 (
    git push %REMOTE% %BRANCH%
    if !errorlevel! equ 0 (
        echo.
        echo %G%[ SUCCESS - Repository synced! ]%W%
    ) else (
        echo %R%[ PUSH FAILED ]%W% Check remote status or permissions.
    )
) else (
    echo %M%[DRY]%W% Would push to %REMOTE%/%BRANCH%.
)

echo.
pause
