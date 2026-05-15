@echo off
REM ============================================================
REM  SGA Web Server - Auto-start script
REM  Registrado en el Programador de Tareas de Windows
REM ============================================================

cd /d "C:\Users\QB_DESARROLLO\Desktop\SGAv1.01\sga_web"

:RETRY
echo [%DATE% %TIME%] Iniciando SGA Web Server... >> "C:\Users\QB_DESARROLLO\Desktop\SGAv1.01\logs\web_server.log" 2>&1
python "C:\Users\QB_DESARROLLO\Desktop\SGAv1.01\sga_web\app.py" >> "C:\Users\QB_DESARROLLO\Desktop\SGAv1.01\logs\web_server.log" 2>&1

REM If the server exits unexpectedly, wait 10 seconds and restart
echo [%DATE% %TIME%] Servidor detenido. Reiniciando en 10 segundos... >> "C:\Users\QB_DESARROLLO\Desktop\SGAv1.01\logs\web_server.log" 2>&1
timeout /t 10 /nobreak
goto RETRY
