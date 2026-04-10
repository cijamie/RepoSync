@echo off
setlocal enabledelayedexpansion

:: 1. Dynamic Identity Detection
for /f "tokens=*" %%i in ('git rev-parse --show-toplevel 2^>nul') do set REPO_ROOT=%%i
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set BRANCH=%%i
for /f "tokens=*" %%i in ('git remote 2^>nul ^| findstr "origin"') do set REMOTE=%%i
if "%REMOTE%"=="" (for /f "tokens=*" %%i in ('git remote 2^>nul') do set REMOTE=%%i)

:: Fallback if not a git repo
if "%REPO_ROOT%"=="" (
    echo [ERROR] This folder is not a Git repository.
    pause
    exit /b 1
)

title Git Sync - %BRANCH% @ %REMOTE%
echo ================================================================
echo           UNIVERSAL REPOSITORY SYNC UTILITY
echo           Target: %BRANCH% on %REMOTE%
echo ================================================================
echo.

echo [1/7] Detecting repo state...
git status --porcelain | findstr . >nul
if %errorlevel% neq 0 goto :pull_only

echo [2/7] Changes detected - creating temp commit...
git add -A
git commit -m "TEMP: auto-staged changes before sync" || goto :pull_only

:staged
echo [3/7] Pulling from %REMOTE%/%BRANCH% with rebase...
git pull --rebase %REMOTE% %BRANCH%

if %errorlevel% neq 0 (
    echo.
    echo [CONFLICT] Resolve manually: git add . ^&^& git rebase --continue
    pause
    exit /b 1
)

echo [4/7] Removing temp commit (unstaging for custom message)...
git reset --soft HEAD~1

:pull_only
echo [5/7] Checking for final changes...
git status --porcelain | findstr . >nul
if %errorlevel% neq 0 (
    echo No changes to commit.
    goto :push
)

echo [6/7] Staging and committing...
set "msg="
set /p msg="[ENTER COMMIT MESSAGE (or leave blank for auto)]: "
if "%msg%"=="" set msg=Update %DATE% %TIME%
git add -A
git commit -m "%msg%"

:push
echo [7/7] Pushing to %REMOTE%/%BRANCH%...
git push %REMOTE% %BRANCH%

if %errorlevel% equ 0 (
    echo.
    echo [ SUCCESS - Repository synced! ]
) else (
    echo [ PUSH FAILED - Check your credentials or remote status ]
)

echo.
pause