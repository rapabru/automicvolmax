<#[
.SYNOPSIS
  Sube el volumen del micrófono en Windows 11.

.DESCRIPTION
  Usa el módulo AudioDeviceCmdlets si está disponible para incrementar el volumen
  de la entrada de audio (micrófono). Si el módulo no está instalado, muestra
  instrucciones de instalación.

.PARAMETER Increment
  Incremento en porcentaje (0-100). Por defecto: 10.

.EXAMPLE
  .\subir_microfono.ps1

.EXAMPLE
  .\subir_microfono.ps1 -Increment 5
#>
[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateRange(0, 100)]
  [int]$Increment = 10
)

$volumeCmd = Get-Command -Name Get-AudioDeviceVolume -ErrorAction SilentlyContinue
$setCmd = Get-Command -Name Set-AudioDeviceVolume -ErrorAction SilentlyContinue
$getDeviceCmd = Get-Command -Name Get-AudioDevice -ErrorAction SilentlyContinue

if (-not $volumeCmd -or -not $setCmd -or -not $getDeviceCmd) {
  Write-Error "No se encontró el módulo 'AudioDeviceCmdlets'."
  Write-Host "Instálalo con:" -ForegroundColor Yellow
  Write-Host "  Install-Module -Name AudioDeviceCmdlets -Scope CurrentUser" -ForegroundColor Yellow
  Write-Host "Luego vuelve a ejecutar este script." -ForegroundColor Yellow
  exit 1
}

$devices = Get-AudioDevice -List | Where-Object { $_.Type -eq 'Recording' }
if (-not $devices) {
  Write-Error "No se pudieron determinar los dispositivos de grabación."
  exit 1
}

$setParams = (Get-Command Set-AudioDeviceVolume).Parameters.Keys
$getParams = (Get-Command Get-AudioDeviceVolume).Parameters.Keys
$idParam = @('DeviceId', 'Id', 'Device') | Where-Object { $setParams -contains $_ } | Select-Object -First 1
$getIdParam = @('DeviceId', 'Id', 'Device') | Where-Object { $getParams -contains $_ } | Select-Object -First 1

foreach ($device in $devices) {
  $current = $null
  if ($getIdParam) {
    $current = Get-AudioDeviceVolume @{$getIdParam = $device.Id}
  } else {
    $current = Get-AudioDeviceVolume -Recording
  }

  if (-not $current) {
    Write-Warning ("No se pudo obtener el volumen actual para '{0}'." -f $device.Name)
    continue
  }

  $newVolume = [Math]::Min(100, $current.Volume + $Increment)
  if ($idParam) {
    Set-AudioDeviceVolume @{$idParam = $device.Id; Volume = $newVolume} | Out-Null
  } else {
    Set-AudioDeviceVolume -Recording -Volume $newVolume | Out-Null
  }

  Write-Host ("Micrófono '{0}' incrementado de {1}% a {2}%." -f $device.Name, $current.Volume, $newVolume)
}
