param(
    [Parameter(Mandatory = $true)]
    [string]$Root
)

function Import-LabDotEnv {
    param([string]$ProjectRoot)

    $envFile = Join-Path $ProjectRoot ".env"
    if (-not (Test-Path -LiteralPath $envFile)) {
        Write-Warning "Khong tim thay $envFile - GOOGLE_API_KEY co the thieu"
        return
    }

    Get-Content -LiteralPath $envFile | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#")) {
            return
        }
        $parts = $line -split "=", 2
        if ($parts.Count -ne 2) {
            return
        }
        [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim().Trim("'`""), "Process")
    }

    if (-not $env:GOOGLE_GENAI_USE_VERTEXAI) {
        $env:GOOGLE_GENAI_USE_VERTEXAI = "FALSE"
    }

    if ($env:GOOGLE_API_KEY) {
        Write-Host "-> .env loaded (GOOGLE_API_KEY set)"
    } else {
        Write-Warning "GOOGLE_API_KEY trong .env dang trong"
    }
}

function Resolve-LabPython {
    $candidates = @()

    if ($env:CONDA_PREFIX) {
        $condaPython = Join-Path $env:CONDA_PREFIX "python.exe"
        if (Test-Path -LiteralPath $condaPython) {
            $candidates += $condaPython
        }
        $condaScriptsPython = Join-Path $env:CONDA_PREFIX "Scripts\python.exe"
        if (Test-Path -LiteralPath $condaScriptsPython) {
            $candidates += $condaScriptsPython
        }
    }

    try {
        $candidates += (Get-Command python -ErrorAction Stop).Source
    } catch {
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        & $candidate -c "import google.adk" *> $null
        if ($LASTEXITCODE -eq 0) {
            return $candidate
        }
    }

    throw "Khong tim thay Python co google-adk. Hay kich hoat env dung cho lab va cai requirements."
}

Import-LabDotEnv -ProjectRoot $Root

$script:LabPython = Resolve-LabPython
$pythonDir = Split-Path -Parent $script:LabPython
$script:LabAdk = Join-Path $pythonDir "adk.exe"

if (-not (Test-Path -LiteralPath $script:LabAdk)) {
    try {
        $script:LabAdk = (Get-Command adk -ErrorAction Stop).Source
    } catch {
        throw "Khong tim thay lenh adk trong environment hien tai."
    }
}

if ($env:PYTHONPATH) {
    $env:PYTHONPATH = "$Root;$env:PYTHONPATH"
} else {
    $env:PYTHONPATH = $Root
}

Write-Host "-> Python: $script:LabPython"
Write-Host "-> ADK:    $script:LabAdk"
