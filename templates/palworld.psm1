#Server Name, Always Match the Launcher and config file name.
$Name = $ServerCfg

#---------------------------------------------------------
# Server Configuration
#---------------------------------------------------------

$ServerDetails = @{

  #Login username used by SteamCMD
  Login              = "anonymous"

  #Server Name
  ServerName         = "My PalWorld Server"

  #Server Description
  ServerDescription  = "My PalWorld Server Description"

  #Server Region
  Region             = ""

  #Server Password
  Password           = "CHANGEME"

  #Maximum number of players (1-32)
  MaxPlayers         = 32

  #Is the server listed in the community server list (adds -publiclobby)
  Public             = $true

  #Server Port (UDP)
  Port               = 8211

  #Rcon IP
  ManagementIP       = "127.0.0.1"

  #Rcon Port
  ManagementPort     = "25575"

  #Rcon / Admin Password
  ManagementPassword = "CHANGEMETOO"

  #Enable the REST API (separate from RCON, used by third party tools)
  UseRestApi         = $false

  #REST API listening port
  RestApiPort        = 8212

  <#
  Performance launch arguments.
  Since Palworld v1.0 the official documentation states that leaving
  -useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS unset may
  actually perform better. Set to $true only if you measured an improvement.
  #>
  UsePerfThreads     = $false

  #Number of server worker threads. 0 = let the server decide.
  WorkerThreads      = 0

  #EDIT OTHER SERVER SETTINGS AT THE BOTTOM OF THIS FILE

  #---------------------------------------------------------
  # Server Installation Details
  #---------------------------------------------------------

  #Name of the Server Instance
  Name               = $Name

  #Server Installation Path
  Path               = ".\servers\$Name"

  #Server configuration folder
  ConfigFolder       = ".\servers\$Name\Pal\Saved\Config\WindowsServer"

  #Steam Server App Id
  AppID              = 2394010

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
  ProcessName        = "PalServer-Win64-Shipping-Cmd"

  #Use PID instead of Process Name.
  UsePID             = $true

  #Server Executable
  Exec               = ".\servers\$Name\PalServer.exe"

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
  Use        = $true

  #Backup Folder
  Path       = ".\backups\$($Server.Name)"

  #Number of days of backups to keep.
  Days       = 7

  #Number of weeks of weekly backups to keep.
  Weeks      = 4

  #Folder to include in backup
  Saves      = ".\servers\$($Server.Name)\Pal\Saved"

  #Exclusions (Regex use | as separator)
  Exclusions = ""
}
#Create the object
$Backups = New-Object -TypeName PsObject -Property $BackupsDetails

#---------------------------------------------------------
# Restart Warnings (Require RCON, Telnet or WebSocket API)
#---------------------------------------------------------

$WarningsDetails = @{
  #Use Rcon to restart server softly.
  Use        = $true

  #What protocol to use : RCON, ARRCON, Telnet, Websocket, StdIn
  Protocol   = "ARRCON"

  #Times at which the servers will warn the players that it is about to restart. (in seconds between each timers)
  Timers     = [System.Collections.ArrayList]@(240, 50, 10) #Total wait time is 240+50+10 = 300 seconds or 5 minutes

  #message that will be sent. % is a wildcard for the timer.
  #Palworld's Broadcast command does not accept spaces, use underscores.
  MessageMin = "The_server_will_restart_in_%_minutes_!"

  #message that will be sent. % is a wildcard for the timer.
  MessageSec = "The_server_will_restart_in_%_seconds_!"

  #command to send a message.
  CmdMessage = "Broadcast"

  #command to save the server
  CmdSave    = "Save"

  #How long to wait in seconds after the save command is sent.
  SaveDelay  = 75

  #command to stop the server
  CmdStop    = "Shutdown"
}
#Create the object
$Warnings = New-Object -TypeName PsObject -Property $WarningsDetails

#---------------------------------------------------------
# Launch Arguments
#---------------------------------------------------------

#Launch Arguments
#Reference : https://docs.palworldgame.com/settings-and-operation/arguments
$ArgumentList = [System.Collections.ArrayList]@(
  "-port=$($Server.Port)",
  "-players=$($Server.MaxPlayers)",
  "-log",
  "-logformat=text"
)

#Register the server on the community server list.
if ($Server.Public) {
  [void]$ArgumentList.Add("-publiclobby")
}

#Legacy multithreading switches, off by default since v1.0. See UsePerfThreads above.
if ($Server.UsePerfThreads) {
  [void]$ArgumentList.Add("-useperfthreads")
  [void]$ArgumentList.Add("-NoAsyncLoadingThread")
  [void]$ArgumentList.Add("-UseMultithreadForDS")
}

#Explicit worker thread count, 0 lets the server decide.
if ($Server.WorkerThreads -gt 0) {
  [void]$ArgumentList.Add("-NumberOfWorkerThreadsServer=$($Server.WorkerThreads)")
}

Add-Member -InputObject $Server -Name "ArgumentList" -Type NoteProperty -Value $ArgumentList
Add-Member -InputObject $Server -Name "Launcher" -Type NoteProperty -Value "$($Server.Exec)"
Add-Member -InputObject $Server -Name "WorkingDirectory" -Type NoteProperty -Value "$($Server.Path)"

#---------------------------------------------------------
# Function that runs just before the server starts.
#---------------------------------------------------------

function Start-ServerPrep {
  Write-ScriptMsg "Writing config to $($Server.ConfigFolder)\PalWorldSettings.ini"

  <#
  YOU MUST EDIT THE CONFIGURATION BELOW AS THE FILE WILL BE OVERWRITTEN AT EACH LAUNCH.

  Values below are the Palworld v1.0 defaults, in the same order as the game's own
  DefaultPalWorldSettings.ini. Booleans must be the literal text True or False.
  Reference : https://docs.palworldgame.com/settings-and-operation/configuration

  Entries marked "MANAGED" are overwritten further down from the Server Configuration
  section at the top of this file. Do not edit them here.
  #>

  $OptionSettings = [ordered]@{

    #--- Game Balance ---------------------------------------------------------

    #None, Normal, Difficult
    Difficulty                                  = "None"

    #Pal randomizer : None, Region, Random
    RandomizerType                              = "None"

    #Seed for the randomizer, empty for random.
    RandomizerSeed                              = '""'

    #Randomize Pal levels when the randomizer is active.
    bIsRandomizerPalLevelRandom                 = "False"

    DayTimeSpeedRate                            = "1.000000"
    NightTimeSpeedRate                          = "1.000000"
    ExpRate                                     = "1.000000"
    PalCaptureRate                              = "1.000000"
    PalSpawnNumRate                             = "1.000000"
    PalDamageRateAttack                         = "1.000000"
    PalDamageRateDefense                        = "1.000000"
    PlayerDamageRateAttack                      = "1.000000"
    PlayerDamageRateDefense                     = "1.000000"

    #Yes, the game really does spell these "Decreace".
    PlayerStomachDecreaceRate                   = "1.000000"
    PlayerStaminaDecreaceRate                   = "1.000000"
    PlayerAutoHPRegeneRate                      = "1.000000"
    PlayerAutoHpRegeneRateInSleep               = "1.000000"
    PalStomachDecreaceRate                      = "1.000000"
    PalStaminaDecreaceRate                      = "1.000000"
    PalAutoHPRegeneRate                         = "1.000000"
    PalAutoHpRegeneRateInSleep                  = "1.000000"

    BuildObjectHpRate                           = "1.000000"
    BuildObjectDamageRate                       = "1.000000"
    BuildObjectDeteriorationDamageRate          = "1.000000"
    CollectionDropRate                          = "1.000000"
    CollectionObjectHpRate                      = "1.000000"
    CollectionObjectRespawnSpeedRate            = "1.000000"
    EnemyDropItemRate                           = "1.000000"

    #None, Item, ItemAndEquipment, All
    DeathPenalty                                = "Item"

    bEnablePlayerToPlayerDamage                 = "False"
    bEnableFriendlyFire                         = "False"
    bEnableInvaderEnemy                         = "True"
    bActiveUNKO                                 = "False"
    bEnableAimAssistPad                         = "True"
    bEnableAimAssistKeyboard                    = "False"

    DropItemMaxNum                              = "3000"

    #Dropped items allowed to use physics, -1 = no limit.
    PhysicsActiveDropItemMaxNum                 = "-1"

    DropItemMaxNum_UNKO                         = "100"

    #Total number of bases across the whole server.
    BaseCampMaxNum                              = "128"

    #Maximum Pals per base, max 50. Raising this raises CPU load.
    BaseCampWorkerMaxNum                        = "15"

    DropItemAliveMaxHours                       = "1.000000"

    bAutoResetGuildNoOnlinePlayers              = "False"
    AutoResetGuildTimeNoOnlinePlayers           = "72.000000"
    GuildPlayerMaxNum                           = "20"

    #Bases per guild, max 10. Raising this raises CPU load.
    BaseCampMaxNumInGuild                       = "4"

    #Hours. Was 72 before v1.0.
    PalEggDefaultHatchingTime                   = "1.000000"

    WorkSpeedRate                               = "1.000000"

    #Autosave interval in seconds.
    AutoSaveSpan                                = "30.000000"

    bIsMultiplay                                = "False"
    bIsPvP                                      = "False"
    bHardcore                                   = "False"

    #Pals are lost permanently on death in hardcore.
    bPalLost                                    = "False"

    bCharacterRecreateInHardcore                = "False"

    bCanPickupOtherGuildDeathPenaltyDrop        = "False"
    bEnableNonLoginPenalty                      = "True"
    bEnableFastTravel                           = "True"

    #Restrict fast travel to base camps only.
    bEnableFastTravelOnlyBaseCamp               = "False"

    #Default changed to False in v1.0.
    bIsStartLocationSelectByMap                 = "False"

    bExistPlayerAfterLogout                     = "False"
    bEnableDefenseOtherGuildPlayer              = "False"
    bInvisibleOtherGuildBaseCampAreaFX          = "False"
    bBuildAreaLimit                             = "False"
    ItemWeightRate                              = "1.000000"
    CoopPlayerMaxNum                            = "4"

    #--- Server Management ----------------------------------------------------

    ServerPlayerMaxNum                          = "MANAGED"
    ServerName                                  = "MANAGED"
    ServerDescription                           = "MANAGED"
    AdminPassword                               = "MANAGED"
    ServerPassword                              = "MANAGED"

    #Allow players with mods enabled to join.
    bAllowClientMod                             = "True"

    PublicPort                                  = "MANAGED"

    #Leave empty to auto detect.
    PublicIP                                    = '""'

    RCONEnabled                                 = "MANAGED"
    RCONPort                                    = "MANAGED"
    Region                                      = "MANAGED"
    bUseAuth                                    = "True"
    BanListURL                                  = '"https://b.palworldgame.com/api/banlist.txt"'
    RESTAPIEnabled                              = "MANAGED"
    RESTAPIPort                                 = "MANAGED"

    #Show the player list to non admins.
    bShowPlayerList                             = "False"

    ChatPostLimitPerMinute                      = "30"

    #Allowed platforms : Steam, Xbox, PS5, Mac
    CrossplayPlatforms                          = "(Steam,Xbox,PS5,Mac)"

    #World backups by the server itself. Increases disk load.
    bIsUseBackupSaveData                        = "True"

    #Text or Json
    LogFormatType                               = "Text"

    bIsShowJoinLeftMessage                      = "True"

    SupplyDropSpan                              = "180"
    EnablePredatorBossPal                       = "True"

    #--- Performance ----------------------------------------------------------

    #Per player building cap, 0 = unlimited.
    MaxBuildingLimitNum                         = "0"

    #Pal sync distance from players in cm. Minimum 5000, maximum 15000.
    ServerReplicatePawnCullDistance             = "15000.000000"

    #Global Palbox transfers between servers.
    bAllowGlobalPalboxExport                    = "True"
    bAllowGlobalPalboxImport                    = "False"

    EquipmentDurabilityDamageRate               = "1.000000"

    #Seconds between forced re-sync while a container UI is open.
    ItemContainerForceMarkDirtyInterval         = "1.000000"

    PlayerDataPalStorageUpdateCheckTickInterval = "1.000000"
    ItemCorruptionMultiplier                    = "1.000000"
    MonsterFarmActionSpeedRate                  = "1.000000"

    #Comma separated technology ids to forbid, empty to allow everything.
    #Written unquoted, the game ships this as a bare empty value.
    DenyTechnologyList                          = ""

    GuildRejoinCooldownMinutes                  = "0"

    #Automatic guild master transfer when the master is inactive.
    AutoTransferMasterCheckIntervalSeconds      = "3600.000000"
    AutoTransferMasterThresholdDays             = "14"

    MaxGuildsPerFrame                           = "10"

    #--- Respawn and PvP ------------------------------------------------------

    BlockRespawnTime                            = "5.000000"
    RespawnPenaltyDurationThreshold             = "0.000000"
    RespawnPenaltyTimeScale                     = "2.000000"

    bDisplayPvPItemNumOnWorldMap_BaseCamp       = "False"
    bDisplayPvPItemNumOnWorldMap_Player         = "False"

    AdditionalDropItemWhenPlayerKillingInPvPMode    = '"PlayerDropItem"'
    AdditionalDropItemNumWhenPlayerKillingInPvPMode = "1"
    bAdditionalDropItemWhenPlayerKillingInPvPMode   = "False"

    #--- Voice Chat -----------------------------------------------------------

    bEnableVoiceChat                            = "False"
    VoiceChatMaxVolumeDistance                  = "3000.000000"
    VoiceChatZeroVolumeDistance                 = "15000.000000"

    #--- Stat Enhancement -----------------------------------------------------

    bAllowEnhanceStat_Health                    = "True"
    bAllowEnhanceStat_Attack                    = "True"
    bAllowEnhanceStat_Stamina                   = "True"
    bAllowEnhanceStat_Weight                    = "True"
    bAllowEnhanceStat_WorkSpeed                 = "True"

    #--- Building Ownership Display -------------------------------------------

    bEnableBuildingPlayerUIdDisplay             = "False"
    BuildingNameDisplayCacheTTLSeconds          = "60"
  }

  # YOU MUST EDIT THE CONFIGURATION ABOVE AS THE FILE WILL BE OVERWRITTEN AT EACH LAUNCH.

  #Values driven by the Server Configuration section at the top of this file.
  $OptionSettings.ServerName         = "`"$($Server.ServerName)`""
  $OptionSettings.ServerDescription  = "`"$($Server.ServerDescription)`""
  $OptionSettings.AdminPassword      = "`"$($Server.ManagementPassword)`""
  $OptionSettings.ServerPassword     = "`"$($Server.Password)`""
  $OptionSettings.ServerPlayerMaxNum = "$($Server.MaxPlayers)"
  $OptionSettings.PublicPort         = "$($Server.Port)"
  $OptionSettings.RCONPort           = "$($Server.ManagementPort)"
  $OptionSettings.Region             = "`"$($Server.Region)`""
  $OptionSettings.RESTAPIEnabled     = if ($Server.UseRestApi) { "True" } else { "False" }
  $OptionSettings.RESTAPIPort        = "$($Server.RestApiPort)"

  #RCON is only needed when the restart warnings use an RCON based protocol.
  $UseRcon = $Warnings.Use -and ($Warnings.Protocol -in @("RCON", "ARRCON"))
  $OptionSettings.RCONEnabled = if ($UseRcon) { "True" } else { "False" }

  #Build the single line OptionSettings=(...) the game expects.
  $Options = ($OptionSettings.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ","
  $content = "[/Script/Pal.PalGameWorldSettings]`r`nOptionSettings=($Options)"

  if (-not (Test-Path -Path $Server.ConfigFolder)) {
    New-Item -ItemType Directory -Path $Server.ConfigFolder -Force | Out-Null
  }
  Set-Content -Path "$($Server.ConfigFolder)/PalWorldSettings.ini" -Value $content

  Write-ScriptMsg "Port Forward : $($Server.Port) in UDP to $($Global.InternalIP)"
  if ($UseRcon) {
    Write-ScriptMsg "RCON listening on port $($Server.ManagementPort) (do not port forward)"
  }
  if ($Server.UseRestApi) {
    Write-ScriptMsg "REST API listening on port $($Server.RestApiPort) (do not port forward)"
  }
}

Export-ModuleMember -Function Start-ServerPrep -Variable @("Server", "Backups", "Warnings")
