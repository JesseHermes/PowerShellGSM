function Send-StdIn {
  [CmdletBinding()]
  [OutputType([boolean])]
  param (
    [Parameter(Mandatory)]
    [string]$Command,
    [Parameter(Mandatory)]
    [string]$PipeName,
    [int]$TimeoutMs = 5000
  )
  $Pipe = $null
  $Writer = $null
  try {
    $Pipe = New-Object System.IO.Pipes.NamedPipeClientStream(".", $PipeName, [System.IO.Pipes.PipeDirection]::Out)
    $Pipe.Connect($TimeoutMs)
    $Writer = New-Object System.IO.StreamWriter($Pipe)
    $Writer.AutoFlush = $true
    $Writer.WriteLine($Command)
  }
  catch {
    return $false
  }
  finally {
    if ($Writer) { $Writer.Dispose() }
    if ($Pipe) { $Pipe.Dispose() }
  }
  return $true
}
Export-ModuleMember -Function Send-StdIn
