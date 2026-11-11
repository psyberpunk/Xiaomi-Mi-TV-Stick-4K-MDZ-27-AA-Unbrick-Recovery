<#
.SYNOPSIS
    Agrega el GUID de interfaz ADB al dispositivo DNL (VID_1B8E&PID_C004) para que
    fastboot.exe lo encuentre. NO deshabilita ni reinicia el dispositivo.

.DESCRIPTION
    fastboot.exe / AdbWinApi.dll buscan los dispositivos por el GUID de interfaz
    {F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}. Zadig registra un GUID aleatorio,
    asi que fastboot se queda en "< waiting for any device >" para siempre.

    Este script antepone el GUID ADB en "Device Parameters\DeviceInterfaceGUIDs",
    conservando el de Zadig.

    Diferencia con tools/fix-adnl-guid.ps1 del proyecto de RodrigoDeveloperX:
    aquel script hace Disable-PnpDevice / Enable-PnpDevice para "reiniciar" el
    dispositivo. Con el stick DESCONECTADO (que es lo normal, porque DNL dura
    pocos segundos), en nuestro caso el Disable se aplico y el Enable fallo
    ("Error generico"), dejando el dispositivo DESHABILITADO (ConfigFlags = 0x61)
    y Windows dejo de instalarle el driver. Este script no hace eso: el GUID se
    aplica solo la proxima vez que conectes el stick.

    IMPORTANTE: Windows BORRA este GUID cada vez que reconfigura el dispositivo
    (por ejemplo, al conectarlo en OTRO puerto USB, que reinstala el driver de
    Zadig). Si cambias de puerto, vuelve a correr este script.

.NOTES
    Requiere PowerShell como Administrador.
#>
[CmdletBinding()]
param(
    [string]$HardwareId = 'VID_1B8E&PID_C004'
)

$ADB_GUID = '{F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Ejecuta este script en PowerShell como ADMINISTRADOR." -ForegroundColor Red
    exit 1
}

$root = "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\$HardwareId"
if (-not (Test-Path $root)) {
    Write-Host "Windows no tiene registro de USB\$HardwareId." -ForegroundColor Yellow
    Write-Host "Conecta el stick una vez (con el driver WinUSB de Zadig ya instalado) y vuelve a correr esto."
    exit 1
}

foreach ($inst in Get-ChildItem $root) {
    $id = "USB\$HardwareId\$($inst.PSChildName)"
    $flags = (Get-ItemProperty $inst.PSPath).ConfigFlags
    $svc = (Get-ItemProperty $inst.PSPath).Service
    Write-Host ""
    Write-Host "Dispositivo: $id"
    Write-Host "  Servicio: $svc   ConfigFlags: $flags"

    if ($flags -band 1) {
        Write-Host "  [!] El dispositivo esta DESHABILITADO (ConfigFlags bit 0x1)." -ForegroundColor Red
        Write-Host "      Con el stick desconectado, borralo y deja que Windows lo vuelva a crear:"
        Write-Host "        pnputil /remove-device `"$id`""
        Write-Host "      Luego conecta el stick 10 s, desconectalo y corre este script otra vez."
        continue
    }
    if ($svc -ne 'WinUSB') {
        Write-Host "  [!] No tiene el driver WinUSB. Instalalo con Zadig primero." -ForegroundColor Yellow
    }

    $key = Join-Path $inst.PSPath 'Device Parameters'
    if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
    $old = @((Get-ItemProperty $key -EA SilentlyContinue).DeviceInterfaceGUIDs |
             Where-Object { $_ -and $_ -ne $ADB_GUID })
    $new = [string[]](@($ADB_GUID) + $old)
    Set-ItemProperty -Path $key -Name DeviceInterfaceGUIDs -Type MultiString -Value $new
    $now = (Get-ItemProperty $key).DeviceInterfaceGUIDs
    Write-Host "  DeviceInterfaceGUIDs: $($now -join ', ')" -ForegroundColor Green
}

Write-Host ""
Write-Host "Listo. Se aplica la proxima vez que conectes el stick (en el MISMO puerto)." -ForegroundColor Green
