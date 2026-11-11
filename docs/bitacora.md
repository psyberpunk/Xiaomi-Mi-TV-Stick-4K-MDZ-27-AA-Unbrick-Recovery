# Bitácora de la recuperación — 2026-11-10

Registro cronológico de lo que se hizo en Windows 11 (horas locales, tomadas de los registros de Windows y de las salidas de fastboot). Los números de serie del equipo se reemplazaron por `<SERIAL_DNL>` y `<SERIAL_FB>`.

Para esto se usó WSL2 + PowerShell (`powershell.exe`) como intérprete. Los comandos que necesitaban administrador los ejecutó el usuario en una PowerShell elevada.

## Contexto previo

- **Síntoma:** logo de Xiaomi → reinicio, en bucle.
- **Recovery con el control:** `Atrás + OK` y `Atrás + Home` (manteniendo hasta 30 s) no abrieron el menú.
- **Modelo:** confirmado por la etiqueta, MDZ-27-AA.

## Detección por USB

| Hora | Evento |
|---|---|
| ~19:00 | Windows sin **ningún** dispositivo Amlogic/Google/Xiaomi, ni en el historial. El stick todavía no estaba conectado a la PC. |
| 19:01 | Instalados **platform-tools 37.0.1** (firmados por Google LLC) en `C:\platform-tools`. Se ejecutó `adb devices`, **que dejó corriendo el servidor adb** (ver 19:51). |
| 19:05:22 | **Primera aparición del DNL** `USB\VID_1B8E&PID_C004\<SERIAL_DNL>`, sin driver. El monitoreo (cada ~1 s) no lo vio en vivo; se encontró en el historial de PnP (`DEVPKEY_Device_LastArrivalDate`). |
| 19:08:09–19:08:14 | DNL presente **5 s**. Después el stick sigue arrancando hasta el logo y **no vuelve a aparecer** por USB hasta que se reconecta. |

## Drivers

| Hora | Acción | Resultado |
|---|---|---|
| 19:12 | `pnputil /add-driver android_winusb.inf /install` (Google USB Driver r13) | `oem24.inf` agregado |
| 19:16:37 | Zadig 2.9 → WinUSB en `DNL (1B8E C004)` | Paquete `dnl.inf` (libwdi) importado como `oem26.inf`. La instalación en el dispositivo **no terminó**: el stick desapareció. |
| 19:17 | `fix-adnl-guid.ps1` (de RodrigoDeveloperX) | GUID escrito, pero `restarting device... Error genérico`. El *Disable* se aplicó y el *Enable* falló → **`ConfigFlags = 97` (0x61)**: deshabilitado + instalación fallida + reinstalar. |
| 19:18:59 | Reconexión | DNL presente 3 s, **sin driver**: al estar deshabilitado, Windows ni lo intentó. |
| 19:21:31 | `pnputil /remove-device "USB\VID_1B8E&PID_C004\<SERIAL_DNL>"` | Dispositivo eliminado |
| 19:22:28 | Reconexión | `Device Install (Hardware initiated)`. **WinUSB asignado** desde `oem26.inf`, `ConfigFlags = 0` |
| 19:23 | GUID ADB antepuesto a mano (sin reiniciar el dispositivo) | `DeviceInterfaceGUIDs = {F72FE0D4-…}, {743763FE-…}`. Windows registró la interfaz en `Control\DeviceClasses\{f72fe0d4-…}`. |

## Captura con fastboot

| Hora | Acción | Resultado |
|---|---|---|
| 19:24:06 | `fastboot` v37 esperando (`reboot bootloader`) | DNL presente 6 s, **no lo enganchó**. *Había fastboot huérfanos de intentos anteriores.* |
| 19:26:07 | `fastboot devices` v37 cada 0.15 s | No lo vio. *Mismos huérfanos.* |
| 19:27:03 → 19:27:40 | `fastboot` **r33.0.3** esperando | **`Rebooting into bootloader OKAY`** |
| 19:27:59 | 2a etapa `USB\VID_18D1&PID_0D02\…` | **Código 10**, `ProblemStatus 0xC00000B5` (timeout de E/S) |
| ~19:29 | `pnputil /restart-device "USB\VID_18D1&PID_0D02\…"` (admin) | Estado **OK** |
| 19:29–19:30 | `getvar product`, etc. (r33 y el fastboot 36.0.2 del paquete A14) | `FAILED (Device sent unknown status code: )`, serial `????????????`. **En ese momento se atribuyó al puerto USB 3. En realidad eran los procesos huérfanos (ver 19:51).** |

## Cambio de puerto y procesos huérfanos

| Hora | Evento |
|---|---|
| 19:32:09 | El stick se pasa a un puerto USB "2.0" (negro). Windows **reconfigura** el DNL (Kernel-PnP 400) y el INF de Zadig **reescribe `DeviceInterfaceGUIDs` solo con su GUID**. |
| 19:32:56, 19:46:35, 19:48:05, 19:50:36, 19:53:17 | DNL presente 3–7 s cada vez. **Fastboot nunca lo ve** (falta el GUID, más los procesos huérfanos). |
| 19:51 | `Get-Process` muestra **`adb.exe` (desde 19:01) y 3 `fastboot.exe` huérfanos** (19:32, 19:34, 19:42): esperas canceladas desde WSL cuyo proceso de Windows siguió vivo. Se matan todos. |
| 19:53 | Se descubre que el GUID ADB desapareció del DNL (solo quedaba `{743763FE-…}`). |
| 19:54 | El usuario vuelve a anteponer el GUID (admin). |

## Diagnóstico y solución

| Hora | Acción | Resultado |
|---|---|---|
| 19:54:44 | DNL aparece, con **un solo** fastboot r33 esperando | `Rebooting into bootloader OKAY [0.000s]` |
| 19:54:47 | 2a etapa `USB\VID_18D1&PID_0D02\<SERIAL_FB>` | **OK** a la primera, sin Código 10 |
| 19:54:5x | Lecturas | `product: soul` · `version-bootloader: 01.01.230608.170904` · `is-userspace: no` · `current-slot: b` · `slot-count: 2` · `unlocked: no` |
| 19:55 | `getvar slot-successful/unbootable/retry-count:a/b` | `Variable not implemented` |
| 19:55 | `set_active a` | `FAILED (remote: 'locked device')` |
| 19:55 | `flashing unlock` | `OKAY [0.549s]` → `unlocked: yes` |
| 19:55 | `set_active a` | `OKAY` → `current-slot: a` |
| 19:56 | `flashing lock` | `OKAY` → `unlocked: no` |
| 19:56:4x | `reboot` | `OKAY` |
| 19:56:51 | USB | (nada): Android arrancando |
| **19:58:30** | USB | **`Dispositivo MTP USB` `USB\VID_18D1&PID_4EE1\<SERIAL_FB>`**: **Android arrancó** |
| ~19:59 | TV | Pantalla de inicio de Android TV. Información: **`RTT0.211222.001.1101 release-keys`**, kernel 5.4 del 20 de mayo de 2022. |

## Lo que se descargó pero no hizo falta

- `mi-tv-stick-4k_14_26.6.10_91_MDZ-27-AA.7z` (989,694,390 bytes, SHA-256 `6300f49e…6711`, **coincide**). Se extrajo con `tar.exe` de Windows (bsdtar soporta 7z). Hashes de cada imagen en [CHECKSUMS.md](CHECKSUMS.md).

## Conclusiones

1. Con bootloader `01.01.23…`, **probar el otro slot antes que cualquier flasheo**. Resolvió el problema sin escribir ninguna imagen.
2. **Un solo proceso** hablando con el stick. Los huérfanos causaron tanto las capturas fallidas como las respuestas basura.
3. **El GUID ADB se borra** si Windows reconfigura el DNL (por ejemplo, al cambiar de puerto).
4. **No reiniciar el DNL con Disable/Enable** cuando el stick no está conectado: lo deja deshabilitado.
5. La 2a etapa de este equipo (bootloader de Android 11) es `18D1:0D02`, no `18D1:4EE7` como en el equipo con bootloader de Android 14.
