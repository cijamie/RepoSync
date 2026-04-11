@echo off
setlocal enabledelayedexpansion

:: ================================================================
:: REPOSYNC - The Ultimate Git Sync Utility (v2.4.0)
:: "Foolproof Edition" - Auto-Recovery & Divergence Handling
:: MIT License - Copyright (c) 2026 cijamie
:: ================================================================

:: 1. Setup Colors (Simplified for Compatibility)
set "G=" & set "R=" & set "C=" & set "Y=" & set "M=" & set "W=" & set "B="
for /f "tokens=2 delims==" %%a in ('set ^| findstr /I "ESC" 2^>nul') do set "ESC=%%a"
if not defined ESC (
    for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"
)
if not defined ESC (
    for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
)
if defined ESC (
    set "G=%ESC%[92m" & set "R=%ESC%[91m" & set "C=%ESC%[96m" & set "Y=%ESC%[93m" & set "M=%ESC%[95m" & set "W=%ESC%[0m" & set "B=%ESC%[5m"
)

:: 2. Argument Parsing
set "ARG1=%~1"
set "IS_DRY=0"
if /i "%ARG1%"=="--dry" (set "IS_DRY=1")
if /i "%ARG1%"=="-d" (set "IS_DRY=1")

:: 3. Pre-Checks
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo %R%[ERROR]%W% Git is not installed or not in PATH.
    goto :error_exit
)

for /f "tokens=*" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "REPO_ROOT=%%i"
if "%REPO_ROOT%"=="" (
    echo %R%[ERROR]%W% Not a Git repository.
    goto :error_exit
)
cd /d "%REPO_ROOT%"

:: 4. Git Identity Check
git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo %R%[ERROR]%W% Git user.name is not set. 
    echo Please run: git config --global user.name "Your Name"
    goto :error_exit
)
git config user.email >nul 2>&1
if %errorlevel% neq 0 (
    echo %R%[ERROR]%W% Git user.email is not set.
    echo Please run: git config --global user.email "you@example.com"
    goto :error_exit
)

:: 5. Index Lock Detection
if not exist ".git\index.lock" goto :skip_index_lock
echo %Y%[ALERT]%W% Git index is locked (.git\index.lock).
echo This usually means another Git process (like VS Code or an IDE) is running.
set /p "FIX_LOCK=Force unlock by deleting the lock file? (y/N): "
if /i "!FIX_LOCK!"=="y" (
    del ".git\index.lock" >nul 2>&1
    echo %G%[FIXED]%W% Index unlocked.
)
if /i not "!FIX_LOCK!"=="y" (
    goto :error_exit
)
:skip_index_lock

:: 6. Active Operation Check
set "ONGOING="
if exist ".git\MERGE_HEAD" set "ONGOING=Merge"
if exist ".git\CHERRY_PICK_HEAD" set "ONGOING=Cherry-pick"
if exist ".git\REVERT_HEAD" set "ONGOING=Revert"
if exist ".git\BISECT_LOG" set "ONGOING=Bisect"
if defined ONGOING (
    echo %R%[ALERT]%W% A %ONGOING% operation is currently in progress.
    echo Please finish or abort it before running RepoSync.
    goto :error_exit
)

:: 7. Detached HEAD Check
git symbolic-ref -q HEAD >nul 2>&1
if %errorlevel% neq 0 (
    echo %R%[ERROR]%W% You are in a 'Detached HEAD' state.
    echo RepoSync requires an active branch to sync safely.
    goto :error_exit
)

:: 8. Conflict Marker Detection
echo %C%[0/8]%W% Checking for unresolved conflict markers...
set "HAS_REAL_CONFLICTS=0"
for /f "tokens=*" %%f in ('git grep -l "<<<<<<<" . 2^>nul') do (
    set "fname=%%f"
    if /i not "!fname!"=="reposync.bat" (
        set "HAS_REAL_CONFLICTS=1"
    )
)

if "!HAS_REAL_CONFLICTS!"=="1" (
    echo %R%[ALERT]%W% Found merge conflict markers.
    echo %Y%[HELP]%W% Please resolve these manually before running RepoSync.
    goto :error_exit
)

:: 9. Identity & Remote Detection
set "UPSTREAM="
for /f "tokens=*" %%i in ('git rev-parse --abbrev-ref @{u} 2^>nul') do set "UPSTREAM=%%i"

if defined UPSTREAM (
    for /f "tokens=1 delims=/" %%a in ("%UPSTREAM%") do set "REMOTE=%%a"
    for /f "tokens=1,* delims=/" %%a in ("%UPSTREAM%") do set "BRANCH=%%b"
)
if not defined UPSTREAM (
    for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do set "BRANCH=%%i"
    set "REMOTE="
    for /f "tokens=*" %%i in ('git remote 2^>nul ^| findstr "origin"') do set "REMOTE=%%i"
)
if not defined REMOTE (
    for /f "tokens=*" %%i in ('git remote 2^>nul') do (
        if not defined REMOTE set "REMOTE=%%i"
    )
)
if not defined REMOTE set "REMOTE=origin"

:: 10. Branch Protection Visuals
set "IS_PROTECTED=0"
if /i "!BRANCH!"=="main" set "IS_PROTECTED=1"
if /i "!BRANCH!"=="master" set "IS_PROTECTED=1"
if /i "!BRANCH!"=="prod" set "IS_PROTECTED=1"
if /i "!BRANCH!"=="production" set "IS_PROTECTED=1"

title RepoSync v2.4.0 - %BRANCH% @ %REMOTE%
echo %C%================================================================%W%
echo           %G%REPOSYNC v2.4.0 - FOOLPROOF SYNC UTILITY%W%
if "!IS_PROTECTED!"=="1" (
    echo           %R%[PROTECTED BRANCH] - PROCEED WITH CAUTION%W%
)
echo           Target: %Y%%BRANCH%%W% on %Y%%REMOTE%%W%
echo %C%================================================================%W%

:: 11. Connectivity & Fetch
echo %C%[1/8]%W% Verifying connectivity and fetching updates...
git ls-remote --exit-code %REMOTE% %BRANCH% >nul 2>&1
set "IS_NEW_BRANCH=0"
if "%errorlevel%"=="2" (
    echo      Status: [NEW BRANCH] - No remote counterpart yet.
    set "IS_NEW_BRANCH=1"
) else (
    git fetch %REMOTE% %BRANCH% >nul 2>&1
    if !errorlevel! neq 0 (
        echo %R%[ERROR]%W% Remote '%REMOTE%' is unreachable or branch missing.
        goto :error_exit
    )
)

:: 12. State Analysis
:analyze_state
set "AHEAD=0"
if "!IS_NEW_BRANCH!"=="0" (
    for /f "tokens=*" %%i in ('git rev-list --count %REMOTE%/%BRANCH%..HEAD 2^>nul') do set "AHEAD=%%i"
)
set "BEHIND=0"
if "!IS_NEW_BRANCH!"=="0" (
    for /f "tokens=*" %%i in ('git rev-list --count HEAD..%REMOTE%/%BRANCH% 2^>nul') do set "BEHIND=%%i"
)
set "DIRTY=0"
for /f "tokens=*" %%i in ('git status --porcelain') do set "DIRTY=1"

echo      Status: Ahead [%G%%AHEAD%%W%] Behind [%R%%BEHIND%%W%] Dirty [%Y%%DIRTY%%W%]

:: 13. Self-Healing
if exist ".git\rebase-merge" (
    echo %R%[ALERT]%W% Rebase is in progress. Attempting to continue...
    git rebase --continue >nul 2>&1 || (
        echo %R%[FAIL]%W% Rebase has conflicts. Please resolve manually.
        goto :error_exit
    )
)

git log -1 --pretty=format:%%s 2>nul | findstr "TEMP: RepoSync auto-save" >nul
if "%errorlevel%"=="0" (
    echo %Y%[RECOVERY]%W% Removing leftover TEMP commit...
    git reset --soft HEAD~1
    set "DIRTY=1"
)

:: 14. Sync Logic
:sync_start
if "!DIRTY!"=="1" (
    echo %C%[2/8]%W% Creating temporary save point...
    if "!IS_DRY!"=="0" (
        git add -A
        git commit -m "TEMP: RepoSync auto-save" >nul 2>&1
    )
)

if "!BEHIND!" neq "0" (
    echo %C%[3/8]%W% Integrating remote changes...
    if "!IS_DRY!"=="0" (
        git pull --rebase %REMOTE% %BRANCH%
        if !errorlevel! neq 0 (
            echo %R%[CONFLICT]%W% Manual resolution required.
            goto :error_exit
        )
    )
)

git log -1 --pretty=format:%%s 2>nul | findstr "TEMP: RepoSync auto-save" >nul
if "%errorlevel%"=="0" (
    echo %C%[4/8]%W% Restoring your changes...
    if "!IS_DRY!"=="0" git reset --soft HEAD~1
)

:: 15. Commit Workflow
echo %C%[5/8]%W% Finalizing changes...
set "HAS_FINAL=0"
for /f "tokens=*" %%i in ('git status --porcelain') do set "HAS_FINAL=1"

if "!HAS_FINAL!"=="0" (
    if "!AHEAD!"=="0" (
        if "!BEHIND!"=="0" (
            echo %G%[ ALREADY UP TO DATE ]%W%
            goto :end
        )
    )
    goto :push_logic
)

echo.
echo %G%[ CHANGELOG SUMMARY ]%W%
git status --short
echo.

echo %C%[6/8]%W% Ready to commit...
set "msg=%ARG1%"
if /i "%msg%"=="--dry" set "msg="
if /i "%msg%"=="-d" set "msg="

if not defined msg (
    set /p msg="[%G%ENTER COMMIT MESSAGE%W% (blank for auto)]: "
)

set "TS=Update"
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'"`) do set "TS_DATE=%%i"
if not defined msg (
    set "msg=Update %TS_DATE%"
)

if "!IS_DRY!"=="1" goto :push_logic

git add -A
git commit -m "!msg!"
if errorlevel 1 (
    echo %R%[ERROR]%W% Commit failed (check for pre-commit hooks or Git locks).
    goto :error_exit
)

:: 16. Push Logic
:push_logic
echo %C%[7/8]%W% Pushing to %REMOTE%/%BRANCH%...
if "!IS_DRY!"=="0" (
    git push %REMOTE% %BRANCH%
    if !errorlevel! neq 0 (
        echo %Y%[RETRY]%W% Push failed. Emergency re-sync...
        git fetch %REMOTE% %BRANCH% >nul 2>&1
        set "IS_NEW_BRANCH=0"
        goto :analyze_state
    )
    echo.
    echo %G%[ SUCCESS - Repository fully synced! ]%W%
)

:end
echo.
pause
exit /b 0

:error_exit
echo.
echo [ CRITICAL ERROR ] Script terminated.
pause
exit /b 1
