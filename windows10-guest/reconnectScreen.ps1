###############################################################
### Install Doesn't seem to work completely due to some bug...
###############################################################


# This script is used to reconnect the session to the main monitor after RDP session is disconnected
###########################
# Functions
###########################
# Check if the script is running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# If not running as administrator, restart with elevated privileges
if (-not $isAdmin) {
    # Create a new process with elevated privileges
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $($MyInvocation.MyCommand.Path)" -Verb RunAs

    # Exit the current non-elevated process
    Exit
}

# The rest of your script goes here

# Example: Display a message indicating administrator privileges
#Write-Host "Running with administrator privileges."

function reconnectScreen {
    # Get the active session ID for the current user
    $sessionOutput = query session | Select-String "Active"

    if ($sessionOutput -match "\s+(\d+)\s+Active") {
        $sessionID = $matches[1]
    } else {
#        Write-Host "Error: Could not determine active session ID!" -ForegroundColor Red
        return
    }

    # Transfer the session back to the console
#    Write-Host "Switching session $sessionID back to console..."
    Start-Process -FilePath "tscon.exe" -ArgumentList "$sessionID /dest:console" -NoNewWindow -Wait -ErrorAction Stop

    # Wait for a short delay to ensure transition
    Start-Sleep -Seconds 2

    # Restart GPU driver (Equivalent to Win + Ctrl + Shift + B)
#    Write-Host "Restarting GPU driver..."
    try {
        $wshell = New-Object -ComObject WScript.Shell
        $wshell.SendKeys("^+{b}")
    } catch {
        Write-Host "Failed to restart GPU driver." -ForegroundColor Yellow
    }

    # Optional: Force HDR refresh by modifying the registry
#    Write-Host "Forcing HDR refresh..."
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "EnableHDRForWindows" -Value 1 -Type DWord -ErrorAction Stop
    } catch {
        Write-Host "Failed to force HDR refresh." -ForegroundColor Yellow
    }

    # Optional: Refresh display settings
#    Write-Host "Refreshing display settings..."
    try {
        rundll32.exe user32.dll, UpdatePerUserSystemParameters ,1 ,True
    } catch {
        Write-Host "Failed to refresh display settings." -ForegroundColor Yellow
    }

#    Write-Host "Done!"
}


# Scheduled Tasks
function Register-ReconnectScreenTask {
    param (
        [string]$TaskName = "ReconnectScreenOnRDPDisconnect",
        [string]$ScriptPath = "C:\Scripts\reconnectScreen.ps1"
    )

    # Ensure script exists
    if (!(Test-Path $ScriptPath)) {
        Write-Host "Error: Script file not found at $ScriptPath" -ForegroundColor Red
        return
    }

    # Get the current user information
    $UserName = "$env:USERDOMAIN\$env:USERNAME"
    $UserSID = (Get-WmiObject Win32_UserAccount | Where-Object { $_.Name -eq $env:USERNAME }).SID

    # Define the XML template with placeholders
    $taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")</Date>
    <Author>$UserName</Author>
    <URI>\$TaskName</URI>
  </RegistrationInfo>
  <Triggers>
    <SessionStateChangeTrigger>
      <Enabled>true</Enabled>
      <StateChange>RemoteDisconnect</StateChange>
      <UserId>$UserName</UserId>
    </SessionStateChangeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$UserSID</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "$ScriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@



    # Define the temporary XML file path
    $taskXmlPath = "$env:TEMP\tempTask.xml"

    # Save the task XML file
    $taskXml | Out-File -Encoding utf8 -FilePath $taskXmlPath

    # Remove existing task if it exists
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Write-Host "Existing task found. Removing before creating a new one..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Attempt to create the task
    $output = SCHTASKS /Create /TN "$TaskName" /XML "$taskXmlPath" /F 2>&1

    # Validate task creation success
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Scheduled Task '$TaskName' created successfully to run on RDP disconnect." -ForegroundColor Green
    } else {
        Write-Host "Error: Failed to create the scheduled task '$TaskName'." -ForegroundColor Red
        Write-Host "SCHTASKS Output: $output" -ForegroundColor Yellow
    }
}

###########################
# Conditional Execution
###########################
if ($MyInvocation.InvocationName -ne ".") {
    reconnectScreen  # Runs only if the script is executed directly, not sourced
}
