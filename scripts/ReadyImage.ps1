
Write-Host "Running Send Ready Signal"
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/SendWindowsIsReady.ps1 -Schedule
if ($LASTEXITCODE -ne 0) {
	throw("Failed to run signal")
}

Write-Host "Updating drive mappings"
Copy-Item -Path 'C:\bootstap\DriveLetterMappingConfig.json' -Destination 'C:\ProgramData\Amazon\EC2-Windows\Launch\Config'
if ($LASTEXITCODE -ne 0) {
	throw("Failed to run Initialize Disk")
}

Write-Host "Running Initialize Disks"
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/InitializeDisks.ps1 -Schedule
if ($LASTEXITCODE -ne 0) {
	throw("Failed to run Initialize Disk")
}

Write-Host "Running InitializeInstance"
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/InitializeInstance.ps1 -Schedule
if ($LASTEXITCODE -ne 0) {
	throw("Failed to run Initialize Instance")
}

Write-Host "Running Sysprep Instance"
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/SysprepInstance.ps1 -NoShutdown
if ($LASTEXITCODE -ne 0) {
	throw("Failed to run Sysprep")
}