<#
.SYNOPSIS
    Spawns an engagement VM using a Differencing VHDX linked to the sealed Read-Only Kali Golden Image.
.PARAMETER EngagementName
    Unique identifier for the engagement VM (e.g., Kali-Eng-01).
.PARAMETER GoldenVHDPath
    Path to the sealed, Read-Only Golden Image VHDX.
.PARAMETER EngagementDir
    Directory where the engagement differencing VHDX will be stored.
.PARAMETER SwitchName
    Target Hyper-V virtual switch (defaults to Dedicated-USB-External-Switch).
.EXAMPLE
    .\New-EngagementVM.ps1 -EngagementName "Kali-Eng-01" -GoldenVHDPath "C:\HyperV\VHDs\Kali-Golden-Master.vhdx" -SwitchName "Dedicated-USB-External-Switch"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EngagementName,

    [Parameter(Mandatory = $true)]
    [string]$GoldenVHDPath,

    [string]$EngagementDir = "C:\HyperV\Engagements\$EngagementName",
    [string]$SwitchName = "Dedicated-USB-External-Switch",
    [int64]$MemoryStartupBytes = 4GB,
    [int]$ProcessorCount = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $GoldenVHDPath)) {
    throw "Golden VHDX not found at: $GoldenVHDPath"
}

$ParentFile = Get-Item $GoldenVHDPath
if (-not $ParentFile.IsReadOnly) {
    Write-Warning "Parent Golden VHDX was not Read-Only. Enforcing ReadOnly attribute to protect master image."
    $ParentFile.IsReadOnly = $true
}

if (-not (Test-Path $EngagementDir)) {
    New-Item -ItemType Directory -Path $EngagementDir -Force | Out-Null
}

$DiffVHDPath = Join-Path $EngagementDir "$EngagementName-diff.vhdx"

Write-Host "[+] Creating Differencing VHDX linked to $GoldenVHDPath" -ForegroundColor Cyan
New-VHD -Path $DiffVHDPath -ParentPath $GoldenVHDPath -Differencing | Out-Null

Write-Host "[+] Provisioning Engagement VM: $EngagementName" -ForegroundColor Cyan
New-VM -Name $EngagementName `
       -MemoryStartupBytes $MemoryStartupBytes `
       -Generation 2 `
       -VHDPath $DiffVHDPath `
       -SwitchName $SwitchName | Out-Null

Set-VMProcessor -VMName $EngagementName -Count $ProcessorCount
Set-VMMemory -VMName $EngagementName -DynamicMemoryEnabled $true -MinimumBytes 2GB -MaximumBytes 8GB
Set-VMFirmware -VMName $EngagementName -EnableSecureBoot Off

Write-Host "[+] Engagement VM '$EngagementName' ready on switch '$SwitchName'." -ForegroundColor Green
Write-Host "[!] First Boot: Run 'sudo bash Invoke-KaliCISHardening.sh --clone $EngagementName' and 'passwd <operator>'." -ForegroundColor Yellow
