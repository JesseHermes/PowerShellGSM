function Start-ServerConsole {
  [CmdletBinding()]
  [OutputType([System.Diagnostics.Process])]
  param (
    #PID of the StdIn host, so the console window can close itself when the server stops.
    [int]$WatchPID = 0
  )
  $ConsoleScript = (Resolve-Path -Path ".\console.ps1").Path
  $ArgumentList = @(
    "-NoProfile",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$ConsoleScript`"",
    "-ServerCfg", "`"$($Server.Name)`"",
    "-WatchPID", $WatchPID
  )
  return Start-Process -FilePath "powershell.exe" -WorkingDirectory (Get-Location).Path -ArgumentList $ArgumentList -PassThru
}
Export-ModuleMember -Function Start-ServerConsole
