# Requires -RunAsAdministrator
[CmdletBinding()]
param (
    [string]$InstallPath = "C:\AtomicRedTeam",
    [switch]$Cleanup,
    [switch]$CheckPrereqsOnly
)

# Ensure the execution harness is loaded
if (-not (Get-Module -Name invoke-atomicredteam)) {
    Import-Module invoke-atomicredteam -ErrorAction Stop
}

$AtomicsPath = Join-Path $InstallPath "atomics"
if (-not (Test-Path $AtomicsPath)) {
    Write-Error "Atomic tests path not found at $AtomicsPath. Please run setup-atomic.ps1 first."
    return
}

# Curated non-destructive techniques for EDR telemetry validation:
# - T1082: System Information Discovery (spawns built-in host diagnostic utilities)
# - T1033: System Owner/User Discovery (enumerates active user sessions and account context)
# - T1016: System Network Configuration Discovery (rapid IP, route, and adapter queries)
# - T1057: Process Discovery (enumerates running processes via standard CLI)
$Techniques = @(
    @{ ID = "T1082"; Name = "System Information Discovery" },
    @{ ID = "T1033"; Name = "System Owner / User Discovery" },
    @{ ID = "T1016"; Name = "System Network Configuration Discovery" },
    @{ ID = "T1057"; Name = "Process Discovery" }
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ThreatDown EDR Telemetry & Behavioral Demo Runner      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Cleanup) {
    Write-Host "`n[*] Executing cleanup commands for demonstrated techniques..." -ForegroundColor Yellow
    foreach ($tech in$Techniques) {
        Write-Host "[-] Cleaning up: $($tech.ID) - $($tech.Name)" -ForegroundColor DarkGray
        Invoke-AtomicTest $tech.ID -PathToAtomics$AtomicsPath -Cleanup -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host "[✓] Cleanup phase completed.`n" -ForegroundColor Green
    return
}

if ($CheckPrereqsOnly) {
    Write-Host "`n[*] Verifying dependencies and requirements..." -ForegroundColor Yellow
    foreach ($tech in$Techniques) {
        Write-Host "`n--- $($tech.ID): $($tech.Name) ---" -ForegroundColor White
        Invoke-AtomicTest $tech.ID -PathToAtomics $AtomicsPath -CheckPrereqs
    }
    return
}

Write-Host "`n[+] Executing curated discovery tests sequentially..." -ForegroundColor Green
Write-Host "    This generates rapid process lineage and execution telemetry.`n" -ForegroundColor DarkGray

foreach ($tech in $Techniques) {
    Write-Host "--> Running $($tech.ID): $($tech.Name)..." -ForegroundColor Yellow
    
    # Executes the technique using local atomics
    Invoke-AtomicTest $tech.ID -PathToAtomics $AtomicsPath -ErrorAction Continue

    # Short delay to separate process trees in temporal logs
    Start-Sleep -Seconds 3
}

Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "[✓] Demonstration sequence completed successfully!" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host @"
Next Steps:
1. Log in to the ThreatDown Nebula console.
2. Navigate to 'Analyze' > 'Suspicious Activity'.
3. Allow up to ~20 minutes for cloud machine-learning models to evaluate process lineage.
4. Run '.\run-edr-demo.ps1 -Cleanup' if test artifacts need to be cleared.
"@ -ForegroundColor Gray
