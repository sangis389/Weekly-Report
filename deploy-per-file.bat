@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "SRC=%~dp0"

rem --- commit message: version auto-extracted from index.html (v=YYYYMMDDx) ---
rem NOTE: keep the powershell call on ONE line. A "^" line continuation inside
rem       for /f backquotes gets mangled and the fragments run as commands.
set "VER="
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "$m=[regex]::Match((Get-Content -Raw -LiteralPath '%~dp0index.html'),'data_booking\.js\?v=([0-9A-Za-z_]+)'); if($m.Success){$m.Groups[1].Value}"`) do set "VER=%%V"
if not defined VER (
  echo [FAILED] Could not read version from index.html. Is the rebuild finished?
  pause & exit /b 1
)

rem --- optional note: first line of commit_note.txt is appended to the message ---
set "NOTE="
if not "%~1"=="" set "NOTE=%~1"
if not defined NOTE if exist "%~dp0commit_note.txt" for /f "usebackq delims=" %%N in ("%~dp0commit_note.txt") do if not defined NOTE set "NOTE=%%N"

if defined NOTE (set "MSG=weekly %VER%: %NOTE%") else (set "MSG=weekly %VER%")
echo Commit message: %MSG%
echo.

rem ---------- locate git ----------
set "GIT="
where git >nul 2>&1 && set "GIT=git"
if not defined GIT if exist "%ProgramFiles%\Git\cmd\git.exe" set "GIT=%ProgramFiles%\Git\cmd\git.exe"
if not defined GIT if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "GIT=%ProgramFiles(x86)%\Git\cmd\git.exe"
if not defined GIT if exist "%LocalAppData%\Programs\Git\cmd\git.exe" set "GIT=%LocalAppData%\Programs\Git\cmd\git.exe"
if not defined GIT for /f "delims=" %%D in ('dir /b /ad "%LocalAppData%\GitHubDesktop\app-*" 2^>nul') do if exist "%LocalAppData%\GitHubDesktop\%%D\resources\app\git\cmd\git.exe" set "GIT=%LocalAppData%\GitHubDesktop\%%D\resources\app\git\cmd\git.exe"
if not defined GIT for /f "delims=" %%D in ('dir /b /ad "%LocalAppData%\GitHubDesktop\app-*" 2^>nul') do if exist "%LocalAppData%\GitHubDesktop\%%D\resources\app\git\mingw64\bin\git.exe" set "GIT=%LocalAppData%\GitHubDesktop\%%D\resources\app\git\mingw64\bin\git.exe"
if not defined GIT echo ERROR: No git found. Open GitHub Desktop once, then retry. & pause & exit /b 1

echo Using git: %GIT%
"%GIT%" --version
echo.

rem ---------- fresh shallow clone in TEMP (existing history preserved, no force-push) ----------
set "WORK=%TEMP%\WR_deploy_%RANDOM%%RANDOM%"
echo Cloning sangis389/Weekly-Report into "%WORK%" ...
"%GIT%" -c credential.helper=manager clone --depth 1 --branch main https://github.com/sangis389/Weekly-Report.git "%WORK%"
if errorlevel 1 (echo. & echo CLONE FAILED - check network / GitHub sign-in. & pause & exit /b 1)

cd /d "%WORK%"
"%GIT%" config user.email "Global_SCM@ohmyhotel.com"
"%GIT%" config user.name  "OMH SCM"
"%GIT%" config credential.helper manager
rem large-push hardening
"%GIT%" config http.version HTTP/1.1
"%GIT%" config http.postBuffer 524288000
"%GIT%" config core.compression 0

rem ---------- one commit + one push per file ----------
set FILES=index.html data_booking.js data_booking_b.js data_booking_c.js data_checkout.js data_checkout_b.js data_checkout_c.js aux_data.js nat_data.js

set /a N=0
for %%F in (%FILES%) do (
  set /a N+=1
  echo.
  echo ============================================================
  echo  [!N!/9] %%F
  echo ============================================================
  if not exist "%SRC%%%F" (
    echo   MISSING in source folder - aborting.
    cd /d "%SRC%"
    pause
    exit /b 1
  )
  copy /Y "%SRC%%%F" "%WORK%\%%F" >nul
  "%GIT%" add -- "%%F"
  "%GIT%" diff --cached --quiet -- "%%F"
  if errorlevel 1 (
    "%GIT%" commit -m "%MSG%" -- "%%F"
    if errorlevel 1 (echo   COMMIT FAILED & cd /d "%SRC%" & pause & exit /b 1)
    echo   pushing...
    "%GIT%" push origin main
    if errorlevel 1 (
      echo   push failed - retry 1...
      timeout /t 5 /nobreak >nul
      "%GIT%" push origin main
      if errorlevel 1 (
        echo   push failed - retry 2...
        timeout /t 15 /nobreak >nul
        "%GIT%" push origin main
        if errorlevel 1 (echo. & echo PUSH FAILED on %%F. Fix and re-run. & cd /d "%SRC%" & pause & exit /b 1)
      )
    )
    echo   OK
  ) else (
    echo   no change - skipped
  )
)

echo.
echo ============================================================
echo  DONE - 9 files processed. Live in 1-2 min:
echo  https://sangis389.github.io/Weekly-Report/
echo ============================================================
cd /d "%SRC%"
rmdir /s /q "%WORK%" 2>nul
pause
