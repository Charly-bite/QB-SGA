@echo off
REM ============================================================
REM  SGA Development Server Launcher
REM  Isolated from production (port 5004)
REM ============================================================

title SGA Development Server (Port 5004)

cd /d "%~dp0"

echo ============================================================
echo   SGA DEVELOPMENT SERVER
echo ============================================================
echo   Environment: DEVELOPMENT
echo   Port:        5004
echo   Database:    SGA_Development (isolated from production)
echo   SAP:         Throttled (1 conn, 2s cooldown)
echo ============================================================
echo.

REM Activate virtual environment
call .venv\Scripts\activate.bat

REM Ensure logs directory exists
if not exist "logs" mkdir logs

REM Set environment
set SGA_ENV=development
set FLASK_ENV=development

REM Navigate to sga_web and start
cd sga_web
echo Starting dev server...
echo Press CTRL+C to stop.
echo.
python run_development.py

REM If it crashes, pause so you can see the error
echo.
echo ============================================================
echo   Server stopped. Press any key to exit.
echo ============================================================
pause
