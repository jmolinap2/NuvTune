<#
.SYNOPSIS
    Compila, instala y diagnostica NuvTune en el telefono sin pedir ip ni puerto.

.DESCRIPTION
    La depuracion inalambrica de Android cambia de puerto cada vez que se
    reactiva, asi que guardar un serial de transporte no sirve: al dia
    siguiente apunta a la nada. Este script resuelve el dispositivo por su
    IDENTIDAD (ro.product.model / ro.product.device), no por su direccion, y
    si no lo encuentra conectado prueba a reconectarlo por mDNS.

    Sustituye la secuencia manual de `adb devices -l` -> `adb mdns services`
    -> `adb connect` -> `flutter build` -> `adb install` que habia que repetir
    en cada despliegue.

.PARAMETER Action
    device   Solo resolver el dispositivo e imprimir su serial.
    build    Solo compilar el apk.
    install  Solo instalar el apk ya compilado.
    deploy   Compilar + instalar (por defecto).
    logs     Volcar los errores recientes de NuvTune del logcat.
    run      Compilar + instalar + lanzar + seguir el log en vivo.

.PARAMETER Release
    Compila en modo release en vez de debug.

.PARAMETER Seconds
    Con `logs`: sigue el log en vivo esa cantidad de segundos en vez de
    volcar el buffer existente y salir.

.EXAMPLE
    pwsh tool/deploy.ps1
    pwsh tool/deploy.ps1 -Action logs
    pwsh tool/deploy.ps1 -Action run -Seconds 45
#>
[CmdletBinding()]
param(
    [ValidateSet('device', 'build', 'install', 'deploy', 'logs', 'run')]
    [string]$Action = 'deploy',

    [switch]$Release,

    [int]$Seconds = 0
)

$ErrorActionPreference = 'Stop'

# Identidad del telefono de desarrollo. Se compara contra estos valores en vez
# de contra un serial de transporte, que cambia con cada reconexion.
$DeviceModel   = '2311DRK48G'      # POCO X6 Pro 5G
$DeviceProduct = 'duchamp_global'
$PackageName   = 'com.nuvtune.app'

$RepoRoot = Split-Path -Parent $PSScriptRoot

function Resolve-Tool {
    param([string]$Name, [string[]]$Candidates)

    $onPath = Get-Command $Name -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    foreach ($candidate in $Candidates) {
        if (Test-Path $candidate) { return $candidate }
    }
    throw "No se encontro $Name. Agregalo al PATH o edita Resolve-Tool en tool/deploy.ps1."
}

$Adb = Resolve-Tool -Name 'adb' -Candidates @(
    'C:\Android\Sdk\platform-tools\adb.exe',
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)

$Flutter = Resolve-Tool -Name 'flutter' -Candidates @(
    'C:\Users\USER\flutter\bin\flutter.bat',
    'C:\flutter\bin\flutter.bat',
    'C:\src\flutter\bin\flutter.bat'
)

# --------------------------------------------------------------------------
# Resolucion del dispositivo
# --------------------------------------------------------------------------

function Get-AttachedDevice {
    # `adb devices -l` ya trae model/product en la misma linea, asi que casi
    # siempre alcanza con esto y no hace falta consultar propiedades.
    foreach ($line in (& $Adb devices -l 2>$null)) {
        if ($line -notmatch '\sdevice\s') { continue }
        if ($line -match "model:$DeviceModel" -or $line -match "product:$DeviceProduct") {
            return ($line -split '\s+')[0]
        }
    }
    return $null
}

function Restore-DeviceConnection {
    # El telefono esta vinculado pero no conectado: mDNS anuncia el puerto
    # actual del servicio de depuracion inalambrica. Se prueban todos los
    # candidatos y se confirma la identidad despues de conectar, porque el
    # nombre del servicio no dice de que telefono se trata.
    Write-Host 'Dispositivo no conectado. Buscando por mDNS...' -ForegroundColor Yellow

    $services = & $Adb mdns services 2>$null
    $endpoints = foreach ($line in $services) {
        if ($line -match '_adb-tls-connect\._tcp.*?([\d\.]+:\d+)\s*$') { $Matches[1] }
    }

    foreach ($endpoint in ($endpoints | Select-Object -Unique)) {
        & $Adb connect $endpoint 2>&1 | Out-Null
        $serial = Get-AttachedDevice
        if ($serial) { return $serial }
    }
    return $null
}

function Get-Device {
    $serial = Get-AttachedDevice
    if (-not $serial) { $serial = Restore-DeviceConnection }
    if (-not $serial) {
        throw @"
No se pudo encontrar el POCO X6 Pro ($DeviceModel).
Reviselo en el telefono: Opciones de desarrollador > Depuracion inalambrica
encendida, y el telefono en la misma red wifi que esta PC. Si Android pidio
un emparejamiento nuevo, hay que volver a vincularlo a mano una vez.
"@
    }
    return $serial
}

# --------------------------------------------------------------------------
# Acciones
# --------------------------------------------------------------------------

$ApkPath = if ($Release) {
    Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
} else {
    Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-debug.apk'
}

function Invoke-Build {
    $mode = if ($Release) { '--release' } else { '--debug' }
    Write-Host "Compilando apk $mode..." -ForegroundColor Cyan
    & $Flutter build apk $mode
    if ($LASTEXITCODE -ne 0) { throw 'Fallo la compilacion.' }
}

function Invoke-Install {
    param([string]$Serial)

    if (-not (Test-Path $ApkPath)) { throw "No existe $ApkPath. Compila primero." }
    Write-Host 'Instalando...' -ForegroundColor Cyan

    # `-r` reinstala conservando los datos. Si aparece un conflicto de firma NO
    # se desinstala automaticamente: eso borraria la biblioteca y las listas
    # del usuario, y es una decision que le toca a el.
    $output = & $Adb -s $Serial install -r $ApkPath 2>&1
    $output | Write-Host
    # $output es un array de lineas: -match/-notmatch sobre un array filtran
    # elementos en vez de devolver un booleano, asi que un array no vacio de
    # "lineas que no dicen Success" es verdadero aunque Success SI aparezca
    # en alguna otra linea. Se une todo en un solo texto antes de comparar.
    $joined = $output -join "`n"
    if ($joined -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match') {
        throw @'
Conflicto de firma: el apk instalado se firmo con otra clave. Desinstalar
borraria los datos de NuvTune (biblioteca, listas, regalos), asi que no se
hace solo. Confirma antes de ejecutar:
    adb uninstall com.nuvtune.app
'@
    }
    if ($joined -notmatch 'Success') { throw 'Fallo la instalacion.' }
}

function Invoke-Launch {
    param([string]$Serial)
    & $Adb -s $Serial shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
}

function Invoke-Logs {
    param([string]$Serial)

    # Solo lo de NuvTune: el logcat de MIUI esta dominado por el fondo de
    # pantalla animado y los servicios del sistema, que ahogan cualquier
    # error propio.
    $filter = 'nuvtune|NuvTune|flutter|AndroidRuntime|ExoPlayer|MusicPlayer|YoutubeDL|GiftPack|DownloadEngine'

    if ($Seconds -gt 0) {
        Write-Host "Siguiendo el log $Seconds s (Ctrl+C para cortar)..." -ForegroundColor Cyan
        & $Adb -s $Serial logcat -c 2>&1 | Out-Null
        $job = Start-Job -ScriptBlock {
            param($adb, $serial) & $adb -s $serial logcat -v brief
        } -ArgumentList $Adb, $Serial
        Start-Sleep -Seconds $Seconds
        Stop-Job $job | Out-Null
        $lines = Receive-Job $job
        Remove-Job $job | Out-Null
    } else {
        $lines = & $Adb -s $Serial logcat -d -v brief 2>&1
    }

    $lines | Select-String -Pattern $filter | Select-Object -Last 200
}

# --------------------------------------------------------------------------

switch ($Action) {
    'device' {
        $serial = Get-Device
        Write-Host $serial
    }
    'build' { Invoke-Build }
    'install' {
        $serial = Get-Device
        Invoke-Install -Serial $serial
    }
    'deploy' {
        $serial = Get-Device
        Invoke-Build
        Invoke-Install -Serial $serial
        Write-Host 'Listo.' -ForegroundColor Green
    }
    'logs' {
        $serial = Get-Device
        Invoke-Logs -Serial $serial
    }
    'run' {
        $serial = Get-Device
        Invoke-Build
        Invoke-Install -Serial $serial
        Invoke-Launch -Serial $serial
        if ($Seconds -le 0) { $Seconds = 30 }
        Invoke-Logs -Serial $serial
    }
}
