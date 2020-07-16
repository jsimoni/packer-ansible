<powershell>

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.0.2/PowerShell-7.0.2-win-x64.msi" -OutFile "C:\temp\PowerShell-7.0.2-win-x64.msi"
msiexec.exe /package C:\temp\PowerShell-7.0.2-win-x64.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1

#$Process = Start-Process PWSH -ArgumentList @("-Command Enable-PSRemoting -SkipNetworkProfileCheck -Force") -PassThru -WindowStyle Hidden

# First, make sure WinRM can't be connected to
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=block

# Delete any existing WinRM listeners
winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

# Install cmdlet for working with GPO Policies
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PolicyFileEditor -Force

# Create SSL Cert
$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName $ENV:COMPUTERNAME
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# Create a new WinRM listener and configure
winrm create winrm/config/Listener?Address=*+Transport=HTTPS
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Negotiate="true"}'
winrm set winrm/config/Listener?Address=*+Transport=HTTPS "@{Port=`"5986`";Hostname=`"$($ENV:COMPUTERNAME)`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"

# Configure UAC to allow privilege elevation in remote shells via GPO
Set-PolicyFileEntry -Path 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol' -Key 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -ValueName 'LocalAccountTokenFilterPolicy' -Data '1' -Type 'DWord'

# Configure and restart the WinRM Service
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic
Start-Service -Name WinRM

#Create firewall rule via GPO to open the necessary port(s)
New-NetFirewallRule -PolicyStore localhost -DisplayName 'Windows Remote Management (HTTPS-In)' -Name 'Windows Remote Management (HTTPS-In)' -Group "Windows Remote Management" -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" -Profile Any -LocalPort 5986 -Protocol TCP
gpupdate /force

# Uninstall cmdlet for working with GPO Policies
Uninstall-Module -Name PolicyFileEditor -Force

</powershell>
