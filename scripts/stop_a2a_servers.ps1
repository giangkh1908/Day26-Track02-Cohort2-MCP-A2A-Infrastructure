$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$logsDir = Join-Path $root "logs"

foreach ($name in @("search_agent", "database_agent", "synthesis_agent")) {
    $pidFile = Join-Path $logsDir "$name.pid"
    if (Test-Path -LiteralPath $pidFile) {
        $pid = Get-Content -LiteralPath $pidFile | Select-Object -First 1
        if ($pid) {
            try {
                Stop-Process -Id ([int]$pid) -Force -ErrorAction Stop
                Write-Host "Stopped $name (pid $pid)"
            } catch {
            }
        }
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    }
}

foreach ($port in @(8001, 8002, 8003)) {
    $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    foreach ($connection in $connections) {
        try {
            Stop-Process -Id $connection.OwningProcess -Force -ErrorAction Stop
            Write-Host "Freed port $port"
        } catch {
        }
    }
}
