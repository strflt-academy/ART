# Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [string]$InstallPath = "C:\AtomicRedTeam"
)

Write-Host "[*] Starting Atomic Red Team environment preparation..." -ForegroundColor Cyan

# 1. Enforce TLS 1.2+
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# 3. Ensure NuGet provider exists
if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
}

# 4. Install Invoke-AtomicRedTeam
Write-Host "[+] Installing 'invoke-atomicredteam' PowerShell module..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name invoke-atomicredteam)) {
    Install-Module -Name invoke-atomicredteam -Scope CurrentUser -Force -AllowClobber
}

# 5. Import the module explicitly into the active session
Import-Module invoke-atomicredteam -Force

# 6. Download the Atomic definitions using the official cmdlet (Install-AtomicsFolder)
Write-Host "[+] Downloading atomic tests to: $InstallPath" -ForegroundColor Yellow
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

# Use Install-AtomicsFolder (or clone directly if fallback is needed)
Install-AtomicsFolder -RepoPath $InstallPath -Force

Write-Host "`n[✓] Setup complete! Atomics are installed at $InstallPath\atomics" -ForegroundColor Green
