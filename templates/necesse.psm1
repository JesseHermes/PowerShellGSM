#Server Name, Always Match the Launcher and config file name.
$Name = $ServerCfg

#---------------------------------------------------------
# Server Configuration
#---------------------------------------------------------

$ServerDetails = @{

  #Login username used by SteamCMD
  Login              = "anonymous"

  #Name of save game to host in data dir \ saves
  World              = "World1"

  #Value of $true instructs the server to pause the world when no players are logged in. Value of $false, world continues without players
  PauseWhenEmpty     = $true

  #Number of player slots to open on the server, default 10
  MaxPlayers         = 10

  #Password to join the World *NO SPACES*
  Password           = "CHANGEME"

  #Server Port
  Port               = 14159

  #Rcon IP (unused, Necesse has no RCON. See Warnings.Protocol = "StdIn" below)
  ManagementIP       = "127.0.0.1"

  #Rcon Port
  ManagementPort     = ""

  #Rcon Password
  ManagementPassword = ""

  #---------------------------------------------------------
  # Server Installation Details
  #---------------------------------------------------------

  #Name of the Server Instance
  Name               = $Name

  #Server Installation Path
  Path               = ".\servers\$Name"

  #Server configuration folder
  ConfigFolder       = ".\servers\$Name\cfg"

  #Steam Server App Id
  AppID              = 1169370

  #Name of the Beta Build
  BetaBuild          = ""

  #Beta Build Password
  BetaBuildPassword  = ""

  #Set to $true if you want this server to automatically update.
  AutoUpdates        = $true

  #Set to $true if you want this server to automatically restart on crash.
  AutoRestartOnCrash = $true

  #Set to $true if you want this server to automatically restart at set hour.
  AutoRestart        = $true

  #The time at which the server will restart daily.
  #(Hour, Minute, Seconds)
  AutoRestartTime    = @(3, 0, 0)

  #Process name in the task manager
  ProcessName        = "java"

  #Use PID instead of Process Name.
  UsePID             = $true

  #Server Executable
  Exec               = ".\servers\$Name\jre\bin\java.exe"

  #Allow force close, usefull for server without RCON.
  AllowForceClose    = $true

  #Process Priority Realtime, High, AboveNormal, Normal, BelowNormal, Low
  UsePriority        = $true
  AppPriority        = "High"

  <#
  Process Affinity (Core Assignation)
  Core 1 = > 00000001 = > 1
  Core 2 = > 00000010 = > 2
  Core 3 = > 00000100 = > 4
  Core 4 = > 00001000 = > 8
  Core 5 = > 00010000 = > 16
  Core 6 = > 00100000 = > 32
  Core 7 = > 01000000 = > 64
  Core 8 = > 10000000 = > 128
  ----------------------------
  8 Cores = > 11111111 = > 255
  4 Cores = > 00001111 = > 15
  2 Cores = > 00000011 = > 3
  #>

  UseAffinity        = $false
  AppAffinity        = 15

  #Should the server validate install after installation or update *(recommended)
  Validate           = $true

  #How long should it wait to check if the server is stable
  StartupWaitTime    = 10
}
#Create the object
$Server = New-Object -TypeName PsObject -Property $ServerDetails

#---------------------------------------------------------
# Backups
#---------------------------------------------------------

$BackupsDetails = @{
  #Do Backups
  Use   = $false

  #Backup Folder
  Path  = ".\backups\$($Server.Name)"

  #Number of days of backups to keep.
  Days  = 7

  #Number of weeks of weekly backups to keep.
  Weeks = 4

  #Folder to include in backup
  Saves = "$($Server.DataDirectory)\saves"

  #Exclusions (Regex use | as separator)
  Exclusions = ""
}
#Create the object
$Backups = New-Object -TypeName PsObject -Property $BackupsDetails

#---------------------------------------------------------
# Restart Warnings (Require RCON, Telnet, StdIn or REST API)
#---------------------------------------------------------

$WarningsDetails = @{
  #Necesse has no RCON, but its console does read commands from StandardInput (the same
  #console text you'd type manually). "StdIn" routes save/stop commands through a hidden
  #host process that keeps that console pipe open across separate script invocations.
  Use        = $true

  #What protocol to use : RCON, ARRCON, Telnet, StdIn, RestAPI
  Protocol   = "StdIn"

  #Times at which the servers will warn the players that it is about to restart. (in seconds between each timers)
  Timers     = [System.Collections.ArrayList]@(240, 50, 10) #Total wait time is 240+50+10 = 300 seconds or 5 minutes

  #message that will be sent. % is a wildcard for the timer.
  MessageMin = "The server will restart in % minutes!"

  #message that will be sent. % is a wildcard for the timer.
  MessageSec = "The server will restart in % seconds!"

  #command to send a message.
  CmdMessage = "say"

  #command to save the server
  CmdSave    = "save"

  #How long to wait in seconds after the save command is sent.
  SaveDelay  = 10

  #command to stop the server. "exit" is what saves and closes Necesse cleanly.
  CmdStop    = "exit"
}
#Create the object
$Warnings = New-Object -TypeName PsObject -Property $WarningsDetails

#---------------------------------------------------------
# Launch Arguments
#---------------------------------------------------------

#Launch Arguments
$ArgumentList = @(
    "-XX:+UnlockExperimentalVMOptions "
    "-XX:+UseG1GC "
    "-XX:+ExplicitGCInvokesConcurrent "
    "-XX:G1NewSizePercent=20 "
    "-XX:G1ReservePercent=20 "
    "-XX:MaxGCPauseMillis=50 "
    "-XX:G1HeapRegionSize=32M "
    "-jar Server.jar "
    "-nogui "
    "-port $($Server.Port) "
    "-world `"$($Server.World)`" "
    "-password `"$($Server.Password)`" "
    "-localdir `"$($Server.Path)`" "
    "-pausewhenempty $([int]$Server.PauseWhenEmpty) "
    "-slots $($Server.MaxPlayers) "
)
Add-Member -InputObject $Server -Name "ArgumentList" -Type NoteProperty -Value $ArgumentList
Add-Member -InputObject $Server -Name "Launcher" -Type NoteProperty -Value "$($Server.Exec)"
Add-Member -InputObject $Server -Name "WorkingDirectory" -Type NoteProperty -Value "$($Server.Path)"

#---------------------------------------------------------
# Function that runs just before the server starts.
#---------------------------------------------------------

function Start-ServerPrep {

  Write-ScriptMsg "Port Forward : $($Server.Port) in UDP to $($Global.InternalIP)"

}

Export-ModuleMember -Function Start-ServerPrep -Variable @("Server", "Backups", "Warnings")