@echo off
"%~dp0api\node\node.exe" "%~dp0api\workbench\server.cjs" --open
if errorlevel 1 pause
