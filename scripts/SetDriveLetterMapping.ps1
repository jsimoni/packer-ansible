Write-Host "Step 3: Set DriveLetterMappingConfig.json"
$driveLetterMapping = Get-Content -Path C:\ProgramData\Amazon\EC2-Windows\Launch\Config\DriveLetterMappingConfig.json | ConvertFrom-Json
$driveLetterMapping.driveLetterMapping = @(
    @{
        volumeName='Data'
        driveLetter='D'
    }
)

Set-Content -Value ($driveLetterMapping | ConvertTo-Json) -Path C:\ProgramData\Amazon\EC2-Windows\Launch\Config\DriveLetterMappingConfig.json
