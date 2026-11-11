<#
.SYNOPSIS
    Cambia el slot activo (A/B) del Mi TV Stick 4K que ya esta en la 2a etapa de
    fastboot, y lo reinicia. NO graba ninguna imagen.

.DESCRIPTION
    Secuencia (la misma que usa el go.cmd oficial para set_active):
        fastboot flashing unlock      <- puede BORRAR tus datos (apps, cuentas)
        fastboot set_active <slot>
        fastboot flashing lock        <- deja el bootloader bloqueado como de fabrica
        fastboot reboot

    Despues vigila el USB: si Android arranca, el stick aparece como
    "Dispositivo MTP USB" (VID_18D1&PID_4EE1). Si vuelve a aparecer el DNL
    (VID_1B8E&PID_C004), no arranco.

    Corre primero capturar.ps1 para dejar el stick en la 2a etapa.

.PARAMETER Slot
    'a', 'b' u 'other' (el contrario al actual). Por defecto: other.
#>
[CmdletBinding()]
param(
    [ValidateSet('a', 'b', 'other')][string]$Slot = 'other',
    [string]$Fastboot = "C:\MiStick\platform-tools\fastboot.exe"
)

$ErrorActionPreference = "Continue"
function T { Get-Date -Format "HH:mm:ss" }
function Invoke-FB([string[]]$FbArgs) {
    $e = Join-Path $env:TEMP "fb_e.txt"; $o = Join-Path $env:TEMP "fb_o.txt"
    $q = Start-Process -FilePath $Fastboot -ArgumentList $FbArgs -NoNewWindow -PassThru `
        -RedirectStandardError $e -RedirectStandardOutput $o
    if (-not $q.WaitForExit(20000)) { $q.Kill(); return "(timeout)" }
    (Get-Content $e, $o -EA SilentlyContinue | Where-Object { $_ -notmatch "^Finished" }) -join "`n"
}

try {
    Get-Process fastboot, adb -EA SilentlyContinue | Stop-Process -Force

    $dev = Invoke-FB @("devices")
    if ($dev -notmatch "fastboot") {
        Write-Host "El stick no esta en fastboot. Corre primero capturar.ps1." -ForegroundColor Red
        exit 1
    }
    $cur = Invoke-FB @("getvar", "current-slot")
    $prod = Invoke-FB @("getvar", "product")
    Write-Host $prod
    Write-Host $cur
    if ($prod -notmatch "product:\s*soul") {
        Write-Host "El producto no es 'soul' (MDZ-27-AA). Me detengo." -ForegroundColor Red
        exit 1
    }

    if ($Slot -eq 'other') {
        if ($cur -match "current-slot:\s*a") { $Slot = 'b' } elseif ($cur -match "current-slot:\s*b") { $Slot = 'a' }
        else { Write-Host "No pude leer el slot actual." -ForegroundColor Red; exit 1 }
    }

    Write-Host ""
    Write-Host "Voy a cambiar el slot activo a '$Slot'." -ForegroundColor Yellow
    Write-Host "Esto DESBLOQUEA el bootloader un momento (puede borrar tus datos) y lo vuelve a bloquear."
    $r = Read-Host "Escribe SI para continuar"
    if ($r -ne "SI") { Write-Host "Cancelado."; exit 0 }

    "[$(T)] flashing unlock";      Invoke-FB @("flashing", "unlock")
    "[$(T)] set_active $Slot";     Invoke-FB @("set_active", $Slot)
    "[$(T)] current-slot";         Invoke-FB @("getvar", "current-slot")
    "[$(T)] flashing lock";        Invoke-FB @("flashing", "lock")
    "[$(T)] unlocked?";            Invoke-FB @("getvar", "unlocked")
    "[$(T)] reboot";               Invoke-FB @("reboot")
}
finally {
    Get-Process fastboot -EA SilentlyContinue | Stop-Process -Force
}

Write-Host ""
Write-Host "[$(T)] Vigilando el USB 4 minutos para ver si Android arranca..." -ForegroundColor Cyan
$last = ""
for ($i = 0; $i -lt 120; $i++) {
    Start-Sleep 2
    $d = Get-PnpDevice -PresentOnly -EA SilentlyContinue |
         Where-Object { $_.InstanceId -match "VID_1B8E|VID_18D1" } |
         ForEach-Object { "$($_.FriendlyName) [$($_.InstanceId -replace '\\[^\\]+$','')] $($_.Status)" }
    $s = ($d -join " ; "); if (-not $s) { $s = "(nada)" }
    if ($s -ne $last) { "[$(T)] $s"; $last = $s }
    if ($s -match "PID_4EE1") {
        Write-Host "ANDROID ARRANCO (MTP 18D1:4EE1). Pasalo a la TV con cargador de pared." -ForegroundColor Green
        exit 0
    }
}
Write-Host "No vi arrancar Android en 4 min. Si la TV tampoco muestra el inicio, prueba el otro slot." -ForegroundColor Yellow
