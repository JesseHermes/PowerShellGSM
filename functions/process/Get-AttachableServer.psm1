function Get-AttachableServer {
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param (
  )
  <#
    A server can be attached to when its StdIn host is running. The host publishes its own
    PID while alive, so the host PID files are the list of running StdIn servers: no config
    files have to be imported to work out what is available.
  #>
  [System.Collections.ArrayList]$Servers = @()
  $PidFiles = Get-ChildItem -Path ".\servers" -Filter "*.stdinhost.pid" -File -ErrorAction SilentlyContinue
  foreach ($PidFile in $PidFiles) {
    $Name = $PidFile.Name -replace "\.stdinhost\.pid$", ""
    #A stale file means the host died without cleaning up, so there is nothing to attach to.
    $HostPID = Get-LivePID -Path $PidFile.FullName
    if ($HostPID -le 0) {
      continue
    }
    if (-not (Test-Path -Path ".\configs\$Name.psm1" -PathType "Leaf" -ErrorAction SilentlyContinue)) {
      continue
    }
    $ConsolePID = Get-LivePID -Path ".\servers\$Name.console.pid"
    $null = $Servers.Add([PSCustomObject]@{
        Name       = $Name
        HostPID    = $HostPID
        ConsolePID = $ConsolePID
        Attached   = ($ConsolePID -gt 0)
      })
  }
  #Returned unrolled on purpose. Callers must wrap this in @() so that a single result
  #stays an array: in Windows PowerShell a lone PSCustomObject has no usable .Count.
  return $Servers
}
Export-ModuleMember -Function Get-AttachableServer
