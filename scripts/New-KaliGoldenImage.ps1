<#
.SYNOPSIS
    Provisions a Generation 2 Hyper-V VM configured for building a Kali Linux Golden Image.
.PARAMETER VMName
    Name of the Golden Image VM (defaults to Kali-Golden-Master).
.PARAMETER ISOPath
    Path to the Kali Linux installer ISO.
.PARAMETER VHDPath
    Destination path for the dynamic VHDX file.
.PARAMETER SwitchName
    Name of the Hyper-V Virtual Switch used for initial OS updates.
.EXAMPLE
    .\New-KaliGoldenImage.ps1 -VMName "Kali-Golden-Master" -ISOPath "D:\ISOs\kali-linux-installer-amd64.iso" -SwitchName "External-Update-Switch"
#>
[CmdletBinding()]
param(
    [string]$VMName = "Kali-Golden-Master",

    [Parameter(Mandatory = $true)]
    [string]$ISOPath,

    [string]$VHDPath = "C:\HyperV\VHDs\$VMName.vhdx",
    [string]$SwitchName = "External-Update-Switch",
    [int64]$MemoryStartupBytes = 4GB,
    [int64]$VHDSizeBytes = 80GB,
    [int]$ProcessorCount = 4
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $ISOPath)) {
    throw "Kali ISO not found at path: $ISOPath"
}

$VHDDir = Split-Path -Parent $VHDPath
if (-not (Test-Path $VHDDir)) {
    New-Item -ItemType Directory -Path $VHDDir -Force | Out-Null
}

Write-Host "[+] Creating Generation 2 Golden Image VM: $VMName" -ForegroundColor Cyan
New-VM -Name $VMName `
       -MemoryStartupBytes $MemoryStartupBytes `
       -Generation 2 `
       -NewVHDPath $VHDPath `
       -NewVHDSizeBytes $VHDSizeBytes `
       -SwitchName $SwitchName | Out-Null

Set-VMProcessor -VMName $VMName -Count $ProcessorCount
Set-VMMemory -VMName $VMName -DynamicMemoryEnabled $true -MinimumBytes 2GB -MaximumBytes 8GB
Set-VMFirmware -VMName $VMName -EnableSecureBoot Off

Add-VMDvdDrive -VMName $VMName -Path $ISOPath
$DvdDrive = Get-VMDvdDrive -VMName $VMName
Set-VMFirmware -VMName $VMName -FirstBootDevice $DvdDrive

Enable-VMIntegrationService -VMName $VMName -Name "Guest Service Interface"

Write-Host "[+] VM '$VMName' created successfully on switch '$SwitchName'." -ForegroundColor Green
Write-Host "[!] Next: Install Kali (non-root operator), run Invoke-KaliCISHardening.sh --seal, and mark VHDX Read-Only." -ForegroundColor Yellow
