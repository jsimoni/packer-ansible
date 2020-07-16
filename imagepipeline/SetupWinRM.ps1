<powershell>

# https://learn.hashicorp.com/packer/getting-started/build-image#a-windows-example
# https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html#winrm-setup

#may need to use this...
#https://cloudywindows.io/post/winrm-for-provisioning-close-the-door-on-the-way-out-eh/

Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Force -ErrorAction Ignore

Write-Output "updating window firewall"
New-NetFirewallRule -DisplayName "anyanyout" -Direction Outbound -LocalPort any -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "anyanyin" -Direction inbound -LocalPort any -Protocol TCP -Action Allow
Remove-Item "c:\windows\System32\GroupPolicy" -Recurse -Force
gpupdate /force

write-output "Running User Data Script"
write-host "(host) Running User Data Script"

# Don't set this before Set-ExecutionPolicy as it throws an error
$e = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'

Enable-PSRemoting -Force

# First, make sure WinRM can't be connected to
netsh advfirewall firewall set rule name="Windows Remote Management (HTTPS-In)" new enable=yes action=block

# Remove HTTP listener
# Delete any existing WinRM listeners
winrm delete winrm/config/Listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS 2>$Null

if (-not( test-path("c:\provisioning"))) {new-item -ItemType Directory "c:\provisioning" }

$ErrorActionPreference = "stop"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -Value 5 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Name 'NTLMMinServerSec' -Value 0x20000000 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LmCompatibilityLevel' -Value 2 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' -Name 'NTLMMinServerSec' -Value 536870912 -Type DWord -Force
# Remove HTTP listener
Remove-Item -Path WSMan:\Localhost\listener\listener* -Recurse

#Set-Item WSMan:\localhost\MaxTimeoutms 1800000
#Set-Item WSMan:\localhost\Service\Auth\Basic $false

$Cert = New-SelfSignedCertificate -CertstoreLocation Cert:\LocalMachine\My -DnsName "packer"
New-Item -Path WSMan:\LocalHost\Listener -Transport HTTPS -Address * -CertificateThumbPrint $Cert.Thumbprint -Force

# WinRM
write-output "Setting up WinRM"
write-host "(host) setting up WinRM"

# Create a new WinRM listener and configure
winrm create winrm/config/Listener?Address=*+Transport=HTTPS
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/client '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Kerberos="false"}'
winrm set winrm/config/service/auth '@{Negotiate="true"}'
winrm set winrm/config/service/auth '@{CredSSP="true"}'
winrm set winrm/config/Listener?Address=*+Transport=HTTPS "@{Port=`"5986`";Hostname=`"packer`";CertificateThumbprint=`"$($Cert.Thumbprint)`"}"

#netsh advfirewall firewall add rule name="Open Port 5985" dir=in action=allow protocol=TCP localport=5985
netsh advfirewall firewall add rule name="Open Port 5986" dir=in action=allow protocol=TCP localport=5986

# Configure UAC to allow privilege elevation in remote shells
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force
cmd.exe /c reg add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\WinRM\Service" /v AllowUnencryptedTraffic /t REG_DWORD /d 1 /f

# Configure and restart the WinRM Service; Enable the required firewall exception
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule name="Windows Remote Management (HTTPS-In)" new action=allow localip=any remoteip=any
Start-Service -Name WinRM

</powershell>
