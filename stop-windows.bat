@echo off
cd /d "%~dp0"
docker compose down
echo IdeaBoard containers stopped. Your ideas are still saved.
pause
