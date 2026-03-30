$ErrorActionPreference = "Stop"

param(
    [string]$SshHost,
    [int]$SshPort = 22,
    [string]$SshUser,
    [int]$LocalPort = 17860,
    [int]$RemotePort = 7860,
    [string]$Password
)

if (-not $SshHost) {
    throw "Missing -SshHost."
}

if (-not $SshUser) {
    throw "Missing -SshUser."
}

if (-not $Password) {
    throw "Missing -Password."
}

$root = Split-Path -Parent $PSScriptRoot
$python = Join-Path $root ".venv\Scripts\python.exe"
$script = Join-Path $root "tools\ssh_tunnel.py"
$logDir = Join-Path $root "logs"
$logFile = Join-Path $logDir "svc-tunnel.log"
$pidFile = Join-Path $logDir "svc-tunnel.pid"

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

if (Test-Path $pidFile) {
    $oldPid = Get-Content $pidFile -ErrorAction SilentlyContinue
    if ($oldPid -and (Get-Process -Id $oldPid -ErrorAction SilentlyContinue)) {
        Write-Output "[INFO] Tunnel is already running with PID $oldPid"
        exit 0
    }
}

$argList = @(
    $script,
    "--ssh-host", $SshHost,
    "--ssh-port", "$SshPort",
    "--ssh-user", $SshUser,
    "--ssh-password", $Password,
    "--remote-host", "127.0.0.1",
    "--remote-port", "$RemotePort",
    "--local-host", "127.0.0.1",
    "--local-port", "$LocalPort"
)

$process = Start-Process -FilePath $python -ArgumentList $argList -RedirectStandardOutput $logFile -RedirectStandardError $logFile -WindowStyle Hidden -PassThru
$process.Id | Set-Content $pidFile

Write-Output "[INFO] Tunnel started"
Write-Output "[INFO] Local URL: http://127.0.0.1:$LocalPort"
Write-Output "[INFO] PID: $($process.Id)"
Write-Output "[INFO] Log: $logFile"
