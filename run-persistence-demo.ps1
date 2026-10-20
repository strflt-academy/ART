# Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [string]$InstallPath = "C:\AtomicRedTeam",
    [switch]$Cleanup,
    [switch]$CheckPrereqsOnly
)

# Ensure Invoke-AtomicRedTeam module is imported
if (-not (Get-Module -Name invoke-atomicredteam)) {
    Import-Module invoke-atomicredteam -ErrorAction Stop
}

$AtomicsPath = Join-Path $InstallPath "atomics"
if (-not (Test-Path $AtomicsPath)) {
    Write-Error "Atomic tests path not found at $AtomicsPath. Please run setup-atomic.ps1 first."
    return
}

# Curated non-destructive Persistence techniques:
# - T1547.001: Registry Run Keys / Startup Folder (Adds benign autorun entries via CLI/reg.exe)
# - T1053.005: Scheduled Task (Creates a scheduled task running benign binaries like cmd/notepad)
# - T1546.001: Change Default File Association (Modifies file association registry entries)
$Techniques = @(
    @{ ID = "T1547.001"; Name = "Registry Run Keys / Startup Folder" },
    @{ ID = "T1053.005"; Name = "Scheduled Task/Job: Scheduled Task" },
    @{ ID = "T1546.001"; Name = "Event Triggered Execution: Change Default File Association" }
)

Write-Host "==========================================================" -ForegroundColor Magenta
Write-Host "   ThreatDown EDR - Persistence (TA0003) Validation Suite " -ForegroundColor Magenta
Write-Host "==========================================================" -ForegroundColor Magenta

if ($Cleanup) {
    Write-Host "`n[*] Executing cleanup commands to remove persistence artifacts..." -ForegroundColor Yellow
    foreach ($tech in $Techniques) {
        Write-Host "[-] Cleaning up: $($tech.ID) - $($tech.Name)" -ForegroundColor DarkGray
        Invoke-AtomicTest $tech.ID -PathToAtomics$AtomicsPath -Cleanup -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "[✓] Cleanup phase complete. All autorun/task artifacts removed.`n" -ForegroundColor Green
    return
}

if ($CheckPrereqsOnly) {
    Write-Host "`n[*] Verifying dependencies and requirements..." -ForegroundColor Yellow
    foreach ($tech in $Techniques) {
        Write-Host "`n--- $($tech.ID): $($tech.Name) ---" -ForegroundColor White
        Invoke-AtomicTest $tech.ID -PathToAtomics $AtomicsPath -CheckPrereqs
    }
    return
}

Write-Host "`n[+] Executing curated persistence tests sequentially..." -ForegroundColor Green
Write-Host "    This generates registry modifications and task scheduler telemetry.`n" -ForegroundColor DarkGray

foreach ($tech in $Techniques) {
    Write-Host "--> Running $($tech.ID): $($tech.Name)..." -ForegroundColor Yellow
    
    # Executes the technique using local atomics
    Invoke-AtomicTest $tech.ID -PathToAtomics $AtomicsPath -ErrorAction Continue

    # Short delay to separate telemetry events
    Start-Sleep -Seconds 3
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "[✓] Persistence test sequence completed successfully!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host @"
Next Steps:
1. Log in to the ThreatDown Nebula console.
2. Navigate to 'Analyze' > 'Suspicious Activity'.
3. Allow up to ~20 minutes for cloud machine-learning models to analyze the registry and task modifications.
4. Run '.\run-persistence-demo.ps1 -Cleanup' when finished to remove all test entries.
"@ -ForegroundColor Gray
