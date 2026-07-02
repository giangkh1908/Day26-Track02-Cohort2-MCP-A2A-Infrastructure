$ErrorActionPreference = "Stop"

& (Join-Path $PSScriptRoot "stop_a2a_servers.ps1")
& (Join-Path $PSScriptRoot "start_a2a_servers.ps1")

Write-Host ""
Write-Host "-> Starting ADK Web for orchestrator..."
Write-Host "   URL: http://localhost:8000"
Write-Host "   A2A: :8001 search | :8002 database | :8003 synthesis"
Write-Host ""

& (Join-Path $PSScriptRoot "start_adk_web.ps1")
