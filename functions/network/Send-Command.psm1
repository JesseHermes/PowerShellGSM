<#
Recursively replace %MESSAGE% inside a route definition so that a template can
put the placeholder anywhere : in the path, in a top level body field or in a
nested object. Everything that is not a string or a container is returned as is.
#>
function Expand-ApiPlaceholder {
  param (
    $InputObject,
    [string]$Message
  )
  if ($InputObject -is [string]) {
    return $InputObject.Replace("%MESSAGE%", $Message)
  }
  if ($InputObject -is [System.Collections.IDictionary]) {
    $Copy = @{}
    foreach ($Key in $InputObject.Keys) {
      $Copy[$Key] = Expand-ApiPlaceholder -InputObject $InputObject[$Key] -Message $Message
    }
    return $Copy
  }
  if ($InputObject -is [array]) {
    return @($InputObject | ForEach-Object { Expand-ApiPlaceholder -InputObject $_ -Message $Message })
  }
  return $InputObject
}

function Send-Command {
  [CmdletBinding()]
  [OutputType([boolean])]
  param (
    [Parameter()]
    $Command,
    $Message = ""
  )

  $Result = $null
  $Success = $false
  #Select Protocol
  switch ($Warnings.Protocol) {
    "RCON" {
      #send Rcon command.
      $Result = Start-Process $Global.Mcrcon -ArgumentList "-c -H $($Server.ManagementIP) -P $($Server.ManagementPort) -p $($Server.ManagementPassword) `"$Command $Message`"" -Wait -PassThru -NoNewWindow
      if ($Result.ExitCode -eq 0) {
        $Success = $true
      }
    }

    "ARRCON" {
      #send ARRCON command.
      $Result = Start-Process $Global.ARRCON -ArgumentList "-c -H $($Server.ManagementIP) -P $($Server.ManagementPort) -p $($Server.ManagementPassword) `"$Command $Message`"" -Wait -PassThru -NoNewWindow
      if ($Result.ExitCode -eq 0) {
        $Success = $true
      }
    }

    "Telnet" {
      #send Telnet command.
      $Result = Get-Telnet -Command "$Command `"$Message`"" -RemoteHost $Server.ManagementIP -Port $Server.ManagementPort -Password $Server.ManagementPassword
      Write-Host $Result
      if (-not (($Result -like "*Unable to connect to host:*") -or ($Result -like "*incorrect*"))) {
        $Success = $true
      }
    }

    "StdIn" {
      #send command through the named pipe held open by the StdIn host process.
      $Success = Send-StdIn -Command "$Command $Message".Trim() -PipeName $Server.PipeName
    }

    "RestAPI" {
      <#
      Generic HTTP API transport.

      This function knows nothing about any particular game. The template
      supplies $Warnings.Api, which maps the logical command names already used
      by CmdMessage / CmdSave / CmdStop to an HTTP request :

        Api = @{
          BaseUrl = "http://127.0.0.1:8212/v1/api"
          Auth    = "Basic"          # Basic, Bearer or None
          User    = "admin"          # Basic only
          Routes  = @{
            Broadcast = @{ Method = "POST"; Path = "announce"; Body = @{ message = "%MESSAGE%" } }
            Save      = @{ Method = "POST"; Path = "save" }
            Shutdown  = @{ Method = "POST"; Path = "shutdown"; Body = @{ waittime = 1 } }
          }
        }

      %MESSAGE% is replaced by the -Message argument anywhere it appears.
      Password defaults to $Server.ManagementPassword unless Api.Password is set.
      #>
      $Api = $Warnings.Api
      if ($null -eq $Api) {
        Write-Warning "Protocol RestAPI requires an Api definition in the Warnings section of the template."
        break
      }
      $Route = $Api.Routes[$Command]
      if ($null -eq $Route) {
        Write-Warning "No RestAPI route defined for command '$Command'."
        break
      }

      #Resolve the request from the route definition.
      $Path = Expand-ApiPlaceholder -InputObject $Route.Path -Message $Message
      $Uri = "$($Api.BaseUrl.TrimEnd('/'))/$($Path.TrimStart('/'))"
      $Method = if ($Route.Method) { $Route.Method } else { "POST" }

      #Build the authentication header.
      $Headers = @{}
      $Password = if ($Api.Password) { $Api.Password } else { $Server.ManagementPassword }
      switch ($Api.Auth) {
        "Basic" {
          $User = if ($Api.User) { $Api.User } else { "admin" }
          $Pair = [Text.Encoding]::UTF8.GetBytes("${User}:${Password}")
          $Headers["Authorization"] = "Basic " + [Convert]::ToBase64String($Pair)
        }
        "Bearer" {
          $Headers["Authorization"] = "Bearer $Password"
        }
      }
      #Extra static headers declared by the template.
      if ($Api.Headers) {
        foreach ($Key in $Api.Headers.Keys) { $Headers[$Key] = $Api.Headers[$Key] }
      }

      $Params = @{
        Uri         = $Uri
        Method      = $Method
        Headers     = $Headers
        TimeoutSec  = 10
        ErrorAction = "Stop"
      }
      #Only send a body when the route declares one.
      if ($Route.Body) {
        $Body = Expand-ApiPlaceholder -InputObject $Route.Body -Message $Message
        $Params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
        $Params.ContentType = "application/json; charset=utf-8"
      }

      try {
        $Result = Invoke-RestMethod @Params
        if ($Result) { Write-Host $Result }
        $Success = $true
      }
      catch {
        Write-Warning "RestAPI $Method $Uri failed : $($_.Exception.Message)"
      }
    }

    Default {
      Write-Warning "Protocol $($Warnings.Protocol) Not Found"
    }
  }
  if ($Success) {
    Write-ServerMsg "Command Sent."
  }
  else {
    Write-ServerMsg "Failed to send command."
  }
  Return $Success
}

Export-ModuleMember -Function Send-Command