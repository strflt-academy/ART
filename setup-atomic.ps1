# Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [string]$InstallPath = "C:\AtomicRedTeam"
)

Write-Host "[*] Starting Atomic Red Team environment preparation..." -ForegroundColor Cyan

# 1. Ensure TLS 1.2+ is used for web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Set Execution Policy for current session
Write-Host "[+] Setting execution policy to RemoteSigned..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# 3. Ensure NuGet package provider is available
Write-Host "[+] Verifying PackageManagement and NuGet provider..." -ForegroundColor Yellow
if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
}

# 4. Install Invoke-AtomicRedTeam execution framework
Write-Host "[+] Installing 'invoke-atomicredteam' PowerShell module..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name invoke-atomicredteam)) {
    Install-Module -Name invoke-atomicredteam -Scope CurrentUser -Force -AllowClobber
} else {
    Write-Host "    'invoke-atomicredteam' is already installed." -ForegroundColor Green
}

# 5. Import the module
Import-Module invoke-atomicredteam -Force

# 6. Download and install Atomic Red Team test definitions
Write-Host "[+] Downloading atomic tests to: $InstallPath" -ForegroundColor Yellow
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

Install-AtomicTechnique -RepoPath $InstallPath -Force

Write-Host "`n[✓] Setup complete! The environment is ready for detection testing." -ForegroundColor Green
Write-Host "    Definitions Path: $InstallPath\atomics" -ForegroundColor Gray
