@echo off
setlocal
cd /d "%~dp0"

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
echo Publishing github-pages to GitHub...
if exist ".git" rmdir /s /q ".git"
"%GIT%" init -b main
"%GIT%" remote add origin https://github.com/sangis389/Weekly-Report.git
"%GIT%" add -A
"%GIT%" -c user.email="Global_SCM@ohmyhotel.com" -c user.name="OMH SCM" commit -m "Update dashboard: WoW tab + weekly data 2026-06-29 to 07-05"
"%GIT%" -c credential.helper=manager push -f -u origin main
if errorlevel 1 (echo. & echo PUSH FAILED - complete the GitHub sign-in window if it appeared, or check Git credentials. & pause & exit /b 1)
echo.
echo ============================================================
echo  DONE. Live in 1-2 min: https://sangis389.github.io/Weekly-Report/
echo ============================================================
pause
