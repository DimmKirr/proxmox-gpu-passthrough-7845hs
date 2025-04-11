#################################################################################
# Run in a User Shell
#################################################################################
# Install Scoop
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install git
scoop bucket add extras
# Install Scoop packages
scoop install totalcommander notepadplusplus tightvnc

# Enable WSL
wsl --install

####
# PS2EXE for running reconnecScreen as an admin easier
Install-Module -Name PS2EXE -Scope CurrentUser -Force


#################################################################################
# Run in an Admin Shell
#################################################################################
### Enable AutoLogin
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$User = $env:USERNAME
$Domain = $env:USERDOMAIN
$Password = Read-Host "Enter password for $User" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Set registry keys
Set-ItemProperty -Path $RegPath -Name "AutoAdminLogon" -Value "1" -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultUserName" -Value $User -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultDomainName" -Value $Domain -Type String
Set-ItemProperty -Path $RegPath -Name "DefaultPassword" -Value $PlainPassword -Type String

Write-Host "Auto-login has been enabled for user $User."

### Disable Sleep
############################
# Set power scheme to high performance
powercfg -SETACTIVE SCHEME_MIN

# Disable sleep timeout for both AC and battery
powercfg -CHANGE -standby-timeout-ac 0
powercfg -CHANGE -standby-timeout-dc 0

# Disable monitor timeout for both AC and battery
powercfg -CHANGE -monitor-timeout-ac 0
powercfg -CHANGE -monitor-timeout-dc 0

# Disable hard disk timeout for both AC and battery
powercfg -CHANGE -disk-timeout-ac 0
powercfg -CHANGE -disk-timeout-dc 0


### Disable Auto Lock
############################
# Set the inactivity timeout to never lock the screen
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "InactivityTimeoutSecs" -Value 0 -PropertyType DWord -Force

# Disable screen saver lock
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaverIsSecure -Value 0
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name ScreenSaveActive -Value 0

# Disable User Account Control (UAC)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLUA" -Value 0






# Restart the computer
Restart-Computer -Force
