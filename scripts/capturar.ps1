<#
.SYNOPSIS
    Atrapa el Xiaomi Mi TV Stick 4K (MDZ-27-AA) en modo DNL, lo pasa a la
    2a etapa de fastboot y lee su informacion. SOLO LECTURA: no graba ni borra nada.

.DESCRIPTION
    El stick entra a DNL (USB VID_1B8E&PID_C004) solo unos 3-6 segundos despues
    de conectarlo. Este script deja UN SOLO fastboot.exe esperando, envia
    "reboot bootloader" en cuanto lo ve, espera la 2a etapa (VID_18D1) y lee:
    product, version-bootloader, is-userspace, current-slot, slot-count, unlocked.

    Antes de empezar y al terminar mata cualquier fastboot.exe / adb.exe que
    haya quedado abierto: varios procesos peleandose por el stick causan capturas
    fallidas y respuestas basura ("Device sent unknown status code", serial "????").

.PARAMETER Fastboot
    Ruta a fastboot.exe. Se uso con exito platform-tools r33.0.3.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\capturar.ps1
    (luego desconecta y conecta el stick)
#>
[CmdletBinding()]
param(
    [string]$Fastboot = "C:\MiStick\platform-tools\fastboot.exe",
    [int]$TimeoutMinutes = 10
)

$ErrorActionPreference = "Continue"
function T { Get-Date -Format "HH:mm:ss.f" }

if (-not (Test-Path $Fastboot)) {
    Write-Host "No encuentro fastboot.exe en: $Fastboot" -ForegroundColor Red
    Write-Host "Descarga platform-tools r33.0.3 y extraelo en C:\MiStick (ver README)."
    exit 1
}

function Invoke-FB([string[]]$FbArgs, [int]$TimeoutMs = 15000) {
    $e = Join-Path $env:TEMP "fb_e.txt"; $o = Join-Path $env:TEMP "fb_o.txt"
    $q = Start-Process -FilePath $Fastboot -ArgumentList $FbArgs -NoNewWindow -PassThru `
        -RedirectStandardError $e -RedirectStandardOutput $o
    if (-not $q.WaitForExit($TimeoutMs)) { $q.Kill(); "  (timeout: $($FbArgs -join ' '))" }
    Get-Content $e, $o -EA SilentlyContinue | Where-Object { $_ -notmatch "^Finished" } | ForEach-Object { "  $_" }
}

try {
    Get-Process fastboot, adb -EA SilentlyContinue | Stop-Process -Force

    Write-Host "[$(T)] Esperando el stick en modo DNL..." -ForegroundColor Cyan
    Write-Host "         >>> Desconecta el stick, espera 3 s y vuelve a conectarlo. <<<" -ForegroundColor Yellow

    $e = Join-Path $env:TEMP "fb_cap_e.txt"; $o = Join-Path $env:TEMP "fb_cap_o.txt"
    $p = Start-Process -FilePath $Fastboot -ArgumentList "reboot", "bootloader" -NoNewWindow -PassThru `
        -RedirectStandardError $e -RedirectStandardOutput $o
    if (-not $p.WaitForExit($TimeoutMinutes * 60000)) {
        $p.Kill()
        Write-Host "[$(T)] No lo vi en $TimeoutMinutes min." -ForegroundColor Red
        Write-Host "  Revisa: cable de datos, driver WinUSB en el DNL, y el GUID (set-adb-guid.ps1)."
        exit 1
    }
    Get-Content $e, $o -EA SilentlyContinue | ForEach-Object { "  $_" }
    Write-Host "[$(T)] 'reboot bootloader' enviado. Esperando la 2a etapa..." -ForegroundColor Cyan

    $ok = $false
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep 1
        $d = Get-PnpDevice -PresentOnly -EA SilentlyContinue | Where-Object { $_.InstanceId -match "VID_18D1" }
        if ($d) {
            "[$(T)] 2a etapa: $($d.Status) $($d.Problem) $($d.InstanceId)"
            if ($d.Status -eq "OK") { $ok = $true; break }
        }
    }
    if (-not $ok) {
        Write-Host "[$(T)] La 2a etapa no quedo en OK." -ForegroundColor Red
        Write-Host "  Si aparece con Codigo 10 (CM_PROB_FAILED_START), en PowerShell de ADMINISTRADOR:"
        Write-Host '    pnputil /restart-device "<InstanceId de arriba>"'
        Write-Host "  y vuelve a correr solo la parte de lectura:  fastboot getvar product"
        exit 2
    }
    Start-Sleep 2

    Write-Host ""
    Write-Host "=== Informacion del stick ===" -ForegroundColor Green
    Invoke-FB @("devices", "-l")
    foreach ($v in "product", "version-bootloader", "is-userspace", "current-slot", "slot-count", "unlocked") {
        Invoke-FB @("getvar", $v)
    }
    Write-Host ""
    Write-Host "El stick se queda en fastboot. NO lo desconectes si vas a correr cambiar-slot.ps1." -ForegroundColor Yellow
}
finally {
    Get-Process fastboot -EA SilentlyContinue | Stop-Process -Force
}
