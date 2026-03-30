$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $root "logs\svc-tunnel.pid"

if (-not (Test-Path $pidFile)) {
    Write-Output "[INFO] No PID file found"
    exit 0
}

$pid = Get-Content $pidFile -ErrorAction SilentlyContinue
if ($pid -and (Get-Process -Id $pid -ErrorAction SilentlyContinue)) {
    Stop-Process -Id $pid -Force
    Write-Output "[INFO] Tunnel stopped (PID $pid)"
} else {
    Write-Output "[INFO] Tunnel process is not running"
}

Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
