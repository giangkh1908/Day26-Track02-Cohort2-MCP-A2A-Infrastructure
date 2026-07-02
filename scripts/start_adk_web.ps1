$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "_lab_env.ps1") -Root $root

$agentDir = Join-Path $root "agents\orchestrator"
if (-not (Test-Path -LiteralPath (Join-Path $agentDir "agent.py"))) {
    throw "Khong tim thay agents/orchestrator/agent.py"
}

Write-Host "-> ADK Web UI: http://localhost:8000"
Write-Host "   Agent: $agentDir"

& $script:LabAdk web $agentDir
