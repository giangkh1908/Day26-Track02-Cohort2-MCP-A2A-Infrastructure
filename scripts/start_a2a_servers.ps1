$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "_lab_env.ps1") -Root $root

$logsDir = Join-Path $root "logs"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

function Stop-PortProcess {
    param([int]$Port)

    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    foreach ($connection in $connections) {
        try {
            Stop-Process -Id $connection.OwningProcess -Force -ErrorAction Stop
        } catch {
        }
    }
}

function Start-Agent {
    param(
        [string]$Name,
        [int]$Port
    )

    Stop-PortProcess -Port $Port
    $stdoutLog = Join-Path $logsDir "$Name.out.log"
    $stderrLog = Join-Path $logsDir "$Name.err.log"
    $pidFile = Join-Path $logsDir "$Name.pid"
    $arguments = @(
        "-m", "uvicorn",
        "agents.$Name.agent:a2a_app",
        "--host", "127.0.0.1",
        "--port", "$Port"
    )

    $process = Start-Process -FilePath $script:LabPython `
        -ArgumentList $arguments `
        -WorkingDirectory $root `
        -RedirectStandardOutput $stdoutLog `
        -RedirectStandardError $stderrLog `
        -WindowStyle Hidden `
        -PassThru

    Set-Content -LiteralPath $pidFile -Value $process.Id
    Write-Host "-> Started $Name on :$Port (pid $($process.Id))"
}

Start-Agent -Name "search_agent" -Port 8001
Start-Agent -Name "database_agent" -Port 8002
Start-Agent -Name "synthesis_agent" -Port 8003

Write-Host "Waiting for A2A servers..."
Start-Sleep -Seconds 5

$checks = @(
    @{ Name = "search_agent"; Url = "http://127.0.0.1:8001/.well-known/agent-card.json" },
    @{ Name = "database_agent"; Url = "http://127.0.0.1:8002/.well-known/agent-card.json" },
    @{ Name = "synthesis_agent"; Url = "http://127.0.0.1:8003/.well-known/agent-card.json" }
)

foreach ($check in $checks) {
    try {
        $response = Invoke-WebRequest -Uri $check.Url -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "OK $($check.Name)"
        } else {
            Write-Warning "$($check.Name) returned HTTP $($response.StatusCode)"
        }
    } catch {
        Write-Warning "$($check.Name) chua san sang - xem logs/$($check.Name).out.log va .err.log"
    }
}
