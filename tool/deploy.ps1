<#
.SYNOPSIS
    Compila, instala, respalda y diagnostica NuvTune en el telefono.

.DESCRIPTION
    La depuracion inalambrica de Android cambia de puerto cada vez que se
    reactiva, asi que guardar un serial de transporte no sirve: al dia
    siguiente apunta a la nada. Este script resuelve el dispositivo por su
    IDENTIDAD (ro.product.model / ro.product.device), no por su direccion, y
    si no lo encuentra conectado prueba a reconectarlo por mDNS.

    El deploy predeterminado genera una APK release versionada, la instala sin
    borrar los datos de la aplicacion y sincroniza la copia visible del APK en
    "APK'S - DESARROLLOS". La APK anterior se mueve a "respaldo" y ahi se
    conservan unicamente las cuatro versiones mas recientes de NuvTune.

.PARAMETER Action
    device   Solo resolver el dispositivo e imprimir su serial.
    build    Solo compilar el apk.
    install  Solo instalar el apk ya compilado.
    deploy   Compilar + instalar + respaldar y copiar la APK (por defecto).
    logs     Volcar los errores recientes de NuvTune del logcat.
    run      Compilar + instalar + lanzar + seguir el log en vivo.

.PARAMETER DebugBuild
    Compila en modo debug. Sin este parametro se compila release.

.PARAMETER Seconds
    Con `logs`: sigue el log en vivo esa cantidad de segundos en vez de
    volcar el buffer existente y salir.

.EXAMPLE
    pwsh tool/deploy.ps1
    pwsh tool/deploy.ps1 -DebugBuild
    pwsh tool/deploy.ps1 -Action logs
    pwsh tool/deploy.ps1 -Action run -Seconds 45
#>
[CmdletBinding()]
param(
    [ValidateSet('device', 'build', 'install', 'deploy', 'logs', 'run')]
    [string]$Action = 'deploy',

    [switch]$DebugBuild,

    [int]$Seconds = 0
)

$ErrorActionPreference = 'Stop'

# Identidad del telefono de desarrollo. Se compara contra estos valores en vez
# de contra un serial de transporte, que cambia con cada reconexion.
$DeviceModel   = '2311DRK48G'      # POCO X6 Pro 5G
$DeviceProduct = 'duchamp_global'
$AppName       = 'NuvTune'
$PackageName   = 'com.nuvtune.app'
$PhoneDir      = "/sdcard/APK'S - DESARROLLOS"
$BackupDir     = "$PhoneDir/respaldo"
$BackupLimit   = 4

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
    'C:\Users\USER\fvm\versions\3.41.9\bin\flutter.bat',
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

$BuildMode = if ($DebugBuild) { 'debug' } else { 'release' }
$ApkPath = if ($DebugBuild) {
    Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-debug.apk'
} else {
    Join-Path $RepoRoot 'build\app\outputs\flutter-apk\app-release.apk'
}

function Get-AppVersion {
    $pubspecPath = Join-Path $RepoRoot 'pubspec.yaml'
    $versionLine = Get-Content $pubspecPath | Where-Object {
        $_ -match '^\s*version:\s*([^\s#]+)'
    } | Select-Object -First 1

    if (-not $versionLine -or $versionLine -notmatch '^\s*version:\s*([0-9A-Za-z.-]+)\+(\d+)\s*(?:#.*)?$') {
        throw 'pubspec.yaml debe tener una version valida, por ejemplo: version: 1.3.2+9'
    }

    # El numero de compilacion (versionCode) sale del numero de commits, igual
    # que en el CI (.github/workflows/release.yml): una sola formula, para que
    # un APK instalado por internet y uno instalado desde aqui sean comparables
    # y ninguno cuente como "bajar de version".
    $commits = [int](git -C $RepoRoot rev-list --count HEAD)
    [pscustomobject]@{
        Name  = $Matches[1]
        Build = 100 + $commits
    }
}

$AppVersion = Get-AppVersion
$DebugSuffix = if ($DebugBuild) { '-debug' } else { '' }
$ArtifactName = "$AppName-v$($AppVersion.Name)-b$($AppVersion.Build)$DebugSuffix.apk"
$VersionedApkPath = Join-Path $RepoRoot $ArtifactName

function Invoke-Build {
    $mode = "--$BuildMode"
    Write-Host "Compilando apk $mode..." -ForegroundColor Cyan
    & $Flutter build apk $mode --build-number=$($AppVersion.Build) --target-platform android-arm64
    if ($LASTEXITCODE -ne 0) { throw 'Fallo la compilacion.' }
    if (-not (Test-Path $ApkPath)) { throw "No se genero $ApkPath." }

    Copy-Item -LiteralPath $ApkPath -Destination $VersionedApkPath -Force
    Write-Host "APK generada: $VersionedApkPath" -ForegroundColor Cyan
}

function Invoke-Install {
    param([string]$Serial)

    if (-not (Test-Path $ApkPath)) { throw "No existe $ApkPath. Compila primero." }
    Write-Host 'Instalando...' -ForegroundColor Cyan

    # `-r` reinstala conservando los datos. Si aparece un conflicto de firma NO
    # se desinstala automaticamente: eso borraria la biblioteca y las listas
    # del usuario, y es una decision que le toca a el.
    $output = & $Adb -s $Serial install -r --user 0 $ApkPath 2>&1
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

function Invoke-AdbShell {
    param(
        [string]$Serial,
        [string]$Command
    )

    $output = & $Adb -s $Serial shell $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Fallo el comando remoto: $Command`n$($output -join "`n")"
    }
    return $output
}

function Get-RemoteAppApks {
    param(
        [string]$Serial,
        [string]$Directory,
        [switch]$NewestFirst
    )

    $lsOption = if ($NewestFirst) { '-1t' } else { '-1' }
    $command = "ls $lsOption `"$Directory`"/$AppName-*.apk 2>/dev/null || true"
    $lines = & $Adb -s $Serial shell $command 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "No se pudieron listar las APK de $Directory.`n$($lines -join "`n")"
    }

    $safePath = '^' + [regex]::Escape("$Directory/$AppName-") + '[0-9A-Za-z._+-]+\.apk$'
    foreach ($line in $lines) {
        $remotePath = "$line".Trim()
        if (-not $remotePath -or $remotePath.EndsWith('*.apk')) { continue }
        if ($remotePath -notmatch $safePath) {
            throw "ADB devolvio una ruta inesperada y no se modificara: $remotePath"
        }
        $remotePath
    }
}

function Invoke-BackupRotation {
    param([string]$Serial)

    $backups = @(Get-RemoteAppApks -Serial $Serial -Directory $BackupDir -NewestFirst)
    $obsolete = @($backups | Select-Object -Skip $BackupLimit)

    foreach ($remoteApk in $obsolete) {
        Write-Host "Eliminando respaldo antiguo: $([IO.Path]::GetFileName($remoteApk))" -ForegroundColor DarkYellow
        Invoke-AdbShell -Serial $Serial -Command "rm -f `"$remoteApk`"" | Out-Null
    }
}

function Publish-ApkToDevice {
    param([string]$Serial)

    if (-not (Test-Path $VersionedApkPath)) {
        throw "No existe $VersionedApkPath. Compila primero."
    }

    Invoke-AdbShell -Serial $Serial -Command "mkdir -p `"$PhoneDir`" `"$BackupDir`"" | Out-Null

    # Primero se sube a un nombre temporal. Asi, si adb push falla, la APK
    # actualmente visible en el telefono permanece intacta.
    $uploadName = ".$AppName-upload-$PID-$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()).apk"
    $uploadPath = "$PhoneDir/$uploadName"
    $destination = "$PhoneDir/$ArtifactName"
    $uploadPending = $true

    try {
        Write-Host 'Copiando la APK nueva al telefono...' -ForegroundColor Cyan
        $pushOutput = & $Adb -s $Serial push $VersionedApkPath $uploadPath 2>&1
        $pushOutput | Write-Host
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo copiar la APK al telefono.' }

        # Solo NuvTune se administra aqui. Las APK actuales de otros proyectos
        # que comparten PHONE_DIR no se tocan.
        $currentApks = @(Get-RemoteAppApks -Serial $Serial -Directory $PhoneDir)
        foreach ($remoteApk in $currentApks) {
            $baseName = [IO.Path]::GetFileNameWithoutExtension($remoteApk)
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmssfff'
            $backupPath = "$BackupDir/$baseName-$timestamp.apk"
            Write-Host "Respaldando APK anterior: $([IO.Path]::GetFileName($remoteApk))" -ForegroundColor Cyan
            Invoke-AdbShell -Serial $Serial -Command "mv `"$remoteApk`" `"$backupPath`"" | Out-Null
        }

        Invoke-AdbShell -Serial $Serial -Command "mv `"$uploadPath`" `"$destination`"" | Out-Null
        $uploadPending = $false

        Invoke-BackupRotation -Serial $Serial
        Write-Host "APK actual en el telefono: $destination" -ForegroundColor Green
    }
    finally {
        if ($uploadPending) {
            & $Adb -s $Serial shell "rm -f `"$uploadPath`"" 2>&1 | Out-Null
        }
    }
}

function Show-InstalledVersion {
    param([string]$Serial)

    Write-Host 'Version instalada:' -ForegroundColor Cyan
    & $Adb -s $Serial shell dumpsys package $PackageName 2>&1 |
        Select-String -Pattern 'versionCode=|versionName=' |
        Select-Object -First 2 |
        ForEach-Object { Write-Host $_.Line.Trim() }
}

function Invoke-Deploy {
    param([string]$Serial)

    Invoke-Build
    Invoke-Install -Serial $Serial
    Publish-ApkToDevice -Serial $Serial
    Show-InstalledVersion -Serial $Serial
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
        Invoke-Deploy -Serial $serial
        Write-Host 'Listo.' -ForegroundColor Green
    }
    'logs' {
        $serial = Get-Device
        Invoke-Logs -Serial $serial
    }
    'run' {
        $serial = Get-Device
        Invoke-Deploy -Serial $serial
        Invoke-Launch -Serial $serial
        if ($Seconds -le 0) { $Seconds = 30 }
        Invoke-Logs -Serial $serial
    }
}
