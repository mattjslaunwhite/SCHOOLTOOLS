# ==============================================================================
# Hyper-V Automation: LinuxFinal Project Setup
# ==============================================================================

# --- Configuration Variables ---
$VMName        = "LinuxFinal Project"
$VMPath        = "C:\Hyper-V\$VMName"
$VHD1Path      = "$VMPath\LinuxFinalProject_OS.vhdx"
$VHD2Path      = "$VMPath\LinuxFinalProject_Data.vhdx"
$IsoPath       = "C:\ISO\Fedora-Workstation-Live-x86_64.iso"  # <--- UPDATE THIS PATH
$MemoryBytes   = 4GB
$VHD1SizeBytes = 127GB$VHD2SizeBytes = 50GB

# 1. Detect Virtual Switch (Defaults to 'Default Switch' or first available External switch)
$Switch = Get-VMSwitch \vert{} Where-Object {$_.SwitchType -eq 'External' } | Select-Object -First 1
if (-not $Switch) {
    $Switch = Get-VMSwitch \vert{} Where-Object {$_.Name -like "*Default Switch*" } | Select-Object -First 1
}
if (-not $Switch) {
    Write-Error "No valid External or Default virtual switch found. Please create one in Hyper-V Manager."
    return
}
Write-Host "[+] Using Virtual Switch: $($Switch.Name)" -ForegroundColor Cyan

# 2. Prepare Directory
if (-not (Test-Path -Path $VMPath)) {
    New-Item -ItemType Directory -Path $VMPath -Force | Out-Null
    Write-Host "[+] Created VM storage folder: $VMPath" -ForegroundColor Green
}

# 3. Create Virtual Hard Disks (.vhdx)
Write-Host "[+] Provisioning 127GB dynamic OS disk..." -ForegroundColor Cyan
New-VHD -Path $VHD1Path -SizeBytes$VHD1SizeBytes -Dynamic | Out-Null

Write-Host "[+] Provisioning 50GB dynamic secondary data disk (/dev/sdb)..." -ForegroundColor Cyan
New-VHD -Path $VHD2Path -SizeBytes$VHD2SizeBytes -Dynamic | Out-Null

# 4. Create the Generation 2 Virtual Machine
Write-Host "[+] Creating Virtual Machine: $VMName..." -ForegroundColor Cyan
New-VM -Name $VMName `
       -MemoryStartupBytes $MemoryBytes `
       -Generation 2 `
       -VHDPath $VHD1Path `
       -SwitchName $Switch.Name `
       -Path "C:\Hyper-V" | Out-Null

# 5. Attach Second Hard Disk (/dev/sdb)
Write-Host "[+] Attaching 50GB second disk to SCSI Controller..." -ForegroundColor Cyan
Add-VMHardDiskDrive -VMName $VMName -ControllerType SCSI -ControllerNumber 0 -Path $VHD2Path

# 6. Configure DVD Drive with Fedora ISO
Write-Host "[+] Attaching Fedora Workstation ISO..." -ForegroundColor Cyan
Add-VMDvdDrive -VMName $VMName -ControllerNumber 0 -Path $IsoPath

# 7. Configure UEFI / Secure Boot for Fedora
# Fedora supports standard UEFI Secure Boot using the Microsoft UEFI CA template
Set-VMFirmware -VMName $VMName -EnableSecureBoot On -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

# Set Boot Order: Boot from DVD (Installer) first, then primary hard disk
$DvdDrive = Get-VMDvdDrive -VMName $VMName
$HardDrive = Get-VMHardDiskDrive -VMName $VMName | Where-Object { $_.Path -eq $VHD1Path }
Set-VMFirmware -VMName $VMName -FirstBootDevice $DvdDrive

# 8. Optimize CPU and Memory
Set-VM -VMName $VMName -ProcessorCount 2 -StaticMemory -MemoryStartupBytes $MemoryBytes

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Virtual Machine '$VMName' configured!" -ForegroundColor Green
Write-Host " - RAM: 4 GB (Static)"
Write-Host " - Disk 1 (OS): 127 GB ($VHD1Path)"
Write-Host " - Disk 2 (Data): 50 GB ($VHD2Path) -> will be /dev/sdb"
Write-Host " - Switch: $($Switch.Name)"
Write-Host " - Boot ISO: $IsoPath"
Write-Host "========================================================" -ForegroundColor Green
Write-Host "Start the VM now with: Start-VM -Name '$VMName'" -ForegroundColor Yellow
