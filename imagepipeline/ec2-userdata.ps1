<powershell>

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

# Don't set this before Set-ExecutionPolicy as it throws an error
$ErrorActionPreference = "stop"

#Write-Output "updating window firewall"
#New-NetFirewallRule -DisplayName "anyanyout" -Direction Outbound -LocalPort any -Protocol TCP -Action Allow
#New-NetFirewallRule -DisplayName "anyanyin" -Direction inbound -LocalPort any -Protocol TCP -Action Allow
Remove-Item "c:\windows\System32\GroupPolicy" -Recurse -Force
gpupdate /force

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PolicyFileEditor -Force
Set-PolicyFileEntry -Path 'C:\Windows\System32\GroupPolicy\Machine\Registry.pol' -Key 'Software\Policies\Microsoft\Windows\WinRM\Service' -ValueName 'AllowBasic' -Data '1' -Type 'DWord'
#Uninstall-Module -Name PolicyFileEditor -Force

# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

#Set-Item WSMan:\localhost\MaxTimeoutms 1800000
#Set-Item WSMan:\localhost\Service\Auth\Basic $true

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

cmd.exe /c winrm quickconfig -q
cmd.exe /c winrm set "winrm/config" '@{MaxTimeoutms="1800000"}'
cmd.exe /c winrm set "winrm/config/winrs" '@{MaxMemoryPerShellMB="1024"}'
#cmd.exe /c winrm set "winrm/config/service" '@{AllowUnencrypted="true"}'
#cmd.exe /c winrm set "winrm/config/client" '@{AllowUnencrypted="true"}'
cmd.exe /c winrm set "winrm/config/service/auth" '@{Basic="true"}'
#cmd.exe /c winrm set "winrm/config/client/auth" '@{Basic="true"}'
#cmd.exe /c winrm set "winrm/config/service/auth" '@{CredSSP="true"}'
cmd.exe /c winrm set "winrm/config/listener?Address=*+Transport=HTTPS" "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"

New-NetFirewallRule -DisplayName 'Windows Remote Management (HTTPS-In)' -Name 'Windows Remote Management (HTTPS-In)' -Group "Windows Remote Management" -Description "Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]" -Profile Any -LocalPort 5986 -Protocol TCP

#cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes
#cmd.exe /c netsh firewall add portopening TCP 5986 "Port 5986"
cmd.exe /c net stop winrm
cmd.exe /c sc config winrm start= auto
cmd.exe /c net start winrm



</powershell>
