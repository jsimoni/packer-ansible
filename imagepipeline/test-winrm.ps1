#just a simple script to test connecting to WinRM via powershell

$User = "Administrator"
$PWord = ConvertTo-SecureString -String "XXXXXXXXXXXXXXXXXXXXX" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$session = New-PSSessionOption  -SkipCACheck -SkipCNCheck
Enter-PSSession -ComputerName "54.85.176.122" -UseSSL -Credential $Credential -Authentication "Basic" -SessionOption $session
