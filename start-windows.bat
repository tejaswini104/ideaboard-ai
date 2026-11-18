@echo off
cd /d "%~dp0"
if not exist .env copy .env.example .env
echo Starting IdeaBoard AI. Make sure Docker Desktop is running.
docker compose up --build -d
if errorlevel 1 (echo Startup failed. Open Docker Desktop and try again. & pause & exit /b 1)
echo.
echo Application: http://localhost:3000
echo API docs:   http://localhost:8000/docs
echo Health:     http://localhost:8000/health
echo.
docker compose ps
pause
