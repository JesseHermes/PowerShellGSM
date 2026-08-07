function Get-LivePID {
  [CmdletBinding()]
  [OutputType([Int])]
  param (
    #Path to a file containing a single process ID.
    [Parameter(Mandatory)]
    [string]$Path
  )
  #Returns the process ID only if that process is still running, 0 otherwise, so a stale
  #file left behind by a killed process reads the same as no file at all.
  if (-not (Test-Path -Path $Path -PathType "Leaf" -ErrorAction SilentlyContinue)) {
    return 0
  }
  $FilePID = 0
  if (-not [int]::TryParse((Get-Content -Path $Path -ErrorAction SilentlyContinue), [ref]$FilePID)) {
    return 0
  }
  if (Get-Process -Id $FilePID -ErrorAction SilentlyContinue) {
    return $FilePID
  }
  return 0
}
Export-ModuleMember -Function Get-LivePID
