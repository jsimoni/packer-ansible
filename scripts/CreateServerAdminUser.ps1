Write-Host "Creating secondary ServerAdmin account"
Write-Host "Getting Administrator Password"
# $AdminPassword = Get-SSMParameter -Name 'AdminPassword' -WithDecryption $true
$AdminPasswordValue = ConvertTo-SecureString "LMnp7ZYE<F6!whmK" -AsPlainText -Force
#$AdminPasswordValue = "LMnp7ZYE<F6!whmK"
#Write-Host "Administrator Password: $AdminPasswordValue"
New-LocalUser "ServerAdmin" -Password $AdminPasswordValue -FullName "Server Admin" -Description "Server Admin." -PasswordNeverExpires
Add-LocalGroupMember -Group "Administrators" -Member "ServerAdmin"