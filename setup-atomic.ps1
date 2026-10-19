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

# 4. Install Invoke-AtomicRedTeam execution framework module
Write-Host "[+] Installing 'invoke-atomicredteam' PowerShell module..." -ForegroundColor Yellow
if (-not (Get-Module -ListAvailable -Name invoke-atomicredteam)) {
    Install-Module -Name invoke-atomicredteam -Scope CurrentUser -Force -AllowClobber
}

# 5. Download and extract Atomic tests directly from GitHub
Write-Host "[+] Downloading atomic test definitions to: $InstallPath" -ForegroundColor Yellow

if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

$ZipUrl = "https://github.com/redcanaryco/atomic-red-team/archive/refs/heads/master.zip"
$ZipFile = Join-Path $InstallPath "art.zip"
$ExtractTemp = Join-Path $InstallPath "art-temp"

# Download archive
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile -UseBasicParsing

# Extract archive
Expand-Archive -Path $ZipFile -DestinationPath $ExtractTemp -Force

# Move the atomics folder into place
$SourceAtomics = Join-Path $ExtractTemp "atomic-red-team-master\atomics"
$DestinationAtomics = Join-Path $InstallPath "atomics"

if (Test-Path $DestinationAtomics) {
    Remove-Item $DestinationAtomics -Recurse -Force
}
Move-Item -Path $SourceAtomics -Destination $DestinationAtomics -Force

# Clean up temporary archive files
Remove-Item $ZipFile -Force
Remove-Item $ExtractTemp -Recurse -Force

Write-Host "`n[✓] Setup complete! Atomics are installed at $DestinationAtomics" -ForegroundColor Green
