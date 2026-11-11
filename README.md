# Xiaomi Mi TV Stick 4K (MDZ-27-AA) — Unbrick / Recuperación desde Windows

🇬🇧 **[English version → README.en.md](README.en.md)**

Cómo recuperamos un **Xiaomi Mi TV Stick 4K (MDZ-27-AA, nombre interno `soul`)** que se quedaba **en el logo de Xiaomi y se reiniciaba**, **sin grabar ningún firmware**: solo cambiando el **slot activo de A/B** con `fastboot`, desde una PC con **Windows 11**.

> **Resultado (2026-11-10):** el stick volvió a arrancar en Android TV con su sistema original (`RTT0.211222.001.1101`, Android 11).
> Bitácora completa con horas y salidas reales: **[docs/bitacora.md](docs/bitacora.md)**

---

## ⚠️ Antes de empezar

- Esto es el **reporte de una recuperación real en un solo equipo**, no un producto ni una garantía. Lo haces bajo tu propio riesgo.
- `fastboot flashing unlock` **puede borrar tus datos** (apps, cuentas, ajustes).
- Si tu stick **todavía arranca**, no necesitas nada de esto.
- Este repositorio **no redistribuye** firmware ni programas de terceros: todo se enlaza a su fuente original, con su hash SHA-256 en [docs/CHECKSUMS.md](docs/CHECKSUMS.md).

---

## Índice

1. [Síntomas](#1-síntomas)
2. [¿Qué tipo de bootloop tienes?](#2-qué-tipo-de-bootloop-tienes)
3. [Lo que necesitas](#3-lo-que-necesitas)
4. [Paso a paso en Windows](#4-paso-a-paso-en-windows)
5. [Problemas que encontramos y cómo se resolvieron](#5-problemas-que-encontramos-y-cómo-se-resolvieron)
6. [Si cambiar de slot no funciona](#6-si-cambiar-de-slot-no-funciona)
7. [Después de recuperarlo](#7-después-de-recuperarlo)
8. [Scripts de este repositorio](#8-scripts-de-este-repositorio)
9. [Hacerlo más fácil con un asistente de IA (Claude Code, Codex)](#9-hacerlo-más-fácil-con-un-asistente-de-ia-claude-code-codex)
10. [Referencias y créditos](#10-referencias-y-créditos)

---

## 1. Síntomas

- El stick prende, muestra el **logo de Xiaomi / Mi** y **se reinicia**, una y otra vez.
- **No entra a Recovery** con el control (`Atrás + OK` al conectarlo no hizo nada en este equipo).
- **ADB no sirve**: Android nunca llega a arrancar.
- Al conectarlo por USB a la PC, Windows ve **durante 3 a 6 segundos** un dispositivo llamado **`DNL`** (`USB\VID_1B8E&PID_C004`) y luego desaparece. Ese es el modo USB de emergencia de Amlogic. **No se queda ciclando**: solo aparece justo al conectarlo, así que cada intento requiere desconectar y volver a conectar.

## 2. ¿Qué tipo de bootloop tienes?

El síntoma en la TV es idéntico, pero hay **causas distintas con soluciones distintas**. Se distinguen leyendo el bootloader con fastboot (sección 4, paso 6):

| `version-bootloader` | Qué significa | Qué hacer |
|---|---|---|
| `01.01.23xxxx` (ej. `01.01.230608.170904`) **← nuestro caso** | Bootloader de la época de **Android 11**. Un slot (normalmente el que está activo) quedó dañado, por ejemplo por una actualización que se cortó. | **Primero cambia de slot** (sección 4, paso 7). Sin grabar nada. |
| `01.01.25xxxx` o `01.01.26xxxx` | La actualización **Android 11 → 14** falló a la mitad: el bootloader ya es de Android 14, pero el sistema no. | Grabar el paquete completo de **Android 14** (sección 6). Android 11 **nunca** arrancará sobre ese bootloader. |
| `0.1` y `product: amlogic` | Todavía estás en la **1a etapa** de fastboot. | Ejecuta `fastboot reboot bootloader` (no `reboot fastboot`). |

Esta tabla viene del trabajo de [RodrigoDeveloperX](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery#which-brick-do-you-have); nuestro equipo confirmó el primer renglón.

## 3. Lo que necesitas

### Hardware

| Qué | Notas |
|---|---|
| El stick MDZ-27-AA | |
| **Cable USB de datos** | Uno de carga solamente no enumera nada. Pruébalo antes con un celular: si la PC no ve el celular, no sirve. |
| PC con Windows 10/11 | Se necesitan permisos de **administrador** para los drivers y el registro. |
| Cargador de pared 5V / 1–2A | Para usarlo en la TV después. **Nunca** lo alimentes del USB de la TV. |

### Software (todo oficial, enlazado a su fuente)

| Programa | Para qué | Dónde | Verificación |
|---|---|---|---|
| **Android SDK Platform-Tools r33.0.3** | `fastboot.exe` que **sí** atrapó el stick en DNL | <https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip> | Descarga directa de Google (este build viejo no trae firma Authenticode). Hash en [CHECKSUMS](docs/CHECKSUMS.md). |
| **Google USB Driver r13** | Driver para la **2a etapa** de fastboot (`VID_18D1`) | <https://dl.google.com/android/repository/usb_driver_r13-windows.zip> | Catálogo firmado (`androidwinusba64.cat`: firma válida). |
| **Zadig 2.9** | Instalar **WinUSB** en el dispositivo **DNL** (`1B8E:C004`) | <https://github.com/pbatard/libwdi/releases> · <https://zadig.akeo.ie> | Firmado por **Akeo Consulting** (firma válida). |
| *(Opcional)* Paquete Android 14 `mi-tv-stick-4k_14_26.6.10_91_MDZ-27-AA.7z` | Solo si cambiar de slot no basta (sección 6) | [Release de RodrigoDeveloperX](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/tag/v2.0-firmware-a14-26.6.10) | SHA-256 `6300f49e9e15ba50e4b6bc9ea7f3243b80178c122b08a440a5e144b8ea6f6711`. Lo verificamos y coincide. |

Los platform-tools más nuevos (v37.0.1) los descartamos durante la sesión, pero **la prueba no fue limpia** (ver [problema 5.4](#54-procesos-fastboot-huérfanos-y-el-servidor-adb)). Lo que sabemos con certeza es que **r33.0.3 funcionó**.

Carpeta que usamos: `C:\MiStick\` (platform-tools extraído en `C:\MiStick\platform-tools\`).

## 4. Paso a paso en Windows

### Paso 1 — Instalar el driver de Google (2a etapa)

Descomprime `usb_driver_r13-windows.zip` en `C:\MiStick\usb_driver\` y, en **PowerShell como administrador**:

```powershell
pnputil /add-driver C:\MiStick\usb_driver\android_winusb.inf /install
```

Este driver incluye `USB\VID_18D1&PID_4EE7` y además se asocia por ID compatible (`USB\Class_FF&SubClass_42&Prot_03`) a la 2a etapa de nuestro stick, que aparece como **`VID_18D1&PID_0D02`** ("Android ADB Interface").

### Paso 2 — Instalar WinUSB en el DNL con Zadig (truco del tiempo)

El DNL solo existe unos **3–6 segundos** después de conectar el stick:

1. Abre Zadig → **Options → List All Devices**.
2. **Desconecta** el stick, espera 3 s y **conéctalo**. Abre de inmediato la lista: debe aparecer **`DNL`** con USB ID **`1B8E C004`**.
3. Selecciónalo, elige **WinUSB** y presiona **Install Driver**. Si el stick desaparece a la mitad, no pasa nada: el paquete queda en el *Driver Store* de Windows (`dnl.inf`, proveedor `libwdi`).
4. **Conecta el stick una vez más** para que Windows le asigne el driver.

Comprueba en PowerShell que el DNL ya tiene `Service = WinUSB` y `ConfigFlags = 0`:

```powershell
Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USB\VID_1B8E&PID_C004\*" | Select ConfigFlags, Service
```

### Paso 3 — Agregar el GUID de interfaz ADB al DNL

Sin esto, fastboot se queda en `< waiting for any device >` aunque el driver esté bien. En **PowerShell como administrador**, con el stick **desconectado**:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\set-adb-guid.ps1
```

Debe mostrar `{F72FE0D4-CBCB-407D-8814-9ED673D0DD6B}` primero y el GUID de Zadig después.

> **No cambies de puerto USB después de este paso.** Al conectar el stick en otro puerto, Windows reinstala el driver de Zadig y **borra este GUID** ([problema 5.5](#55-cambiar-de-puerto-usb-borra-el-guid)).

### Paso 4 — Cerrar cualquier fastboot/adb que esté abierto

```powershell
Get-Process fastboot, adb -ErrorAction SilentlyContinue | Stop-Process -Force
```

Dos programas hablando con el stick al mismo tiempo provocan capturas fallidas y respuestas basura ([problema 5.4](#54-procesos-fastboot-huérfanos-y-el-servidor-adb)). **No ejecutes `adb devices`** durante este proceso: deja un servidor adb corriendo en segundo plano.

### Paso 5 — Atrapar el stick y pasarlo a la 2a etapa

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\capturar.ps1
```

Cuando diga *"Esperando el stick en modo DNL"*, **desconecta el stick, espera 3 s y conéctalo**. El script deja **un solo** `fastboot reboot bootloader` esperando. En cuanto ve el DNL, el stick salta a la 2a etapa y el script lee su información. Esto es lo que dio el nuestro:

```
<SERIAL>               fastboot
product: soul
version-bootloader: 01.01.230608.170904
is-userspace: no
current-slot: b
slot-count: 2
unlocked: no
```

Si la 2a etapa aparece con **Código 10** (`CM_PROB_FAILED_START`, estado `0xC00000B5` = timeout), reiníciala **sin desconectar** el stick (PowerShell como administrador):

```powershell
pnputil /restart-device "USB\VID_18D1&PID_0D02\<el InstanceId que muestra el script>"
```

### Paso 6 — Decidir con la tabla de la sección 2

`01.01.23…` = bootloader de Android 11, así que seguimos con el paso 7. Si el tuyo es `01.01.25…` o `01.01.26…`, ve a la [sección 6](#6-si-cambiar-de-slot-no-funciona).

### Paso 7 — Cambiar al otro slot (no graba ninguna imagen)

Con el stick **todavía en fastboot**:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\cambiar-slot.ps1
```

Equivale a:

```
fastboot set_active a        -> FAILED (remote: 'locked device')   # con el bootloader bloqueado no deja
fastboot flashing unlock     -> OKAY
fastboot set_active a        -> OKAY
fastboot getvar current-slot -> current-slot: a
fastboot flashing lock       -> OKAY          # queda bloqueado otra vez, como de fábrica
fastboot reboot              -> OKAY
```

Unos 100 segundos después, Windows mostró **`Dispositivo MTP USB` (`USB\VID_18D1&PID_4EE1`)**, señal de que **Android arrancó**. La TV mostró Android TV normalmente. El sistema del slot A era `RTT0.211222.001.1101 release-keys` (Android 11, kernel de mayo 2022).

## 5. Problemas que encontramos y cómo se resolvieron

### 5.1 Windows no veía nada

Al principio no había **ningún** evento USB. El stick no estaba conectado a la PC; cuando se conectó, el DNL apareció. Si te pasa con el stick conectado: cambia el **cable** (que sea de datos) y el **puerto**.

### 5.2 El script de otro proyecto deshabilitó el DNL

`fix-adnl-guid.ps1` (del proyecto de RodrigoDeveloperX) agrega el GUID y luego hace `Disable-PnpDevice` + `Enable-PnpDevice`. Con el stick desconectado, el *Disable* sí se aplicó y el *Enable* falló (`Error genérico`). El DNL quedó con **`ConfigFlags = 97` (0x61 = deshabilitado + instalación fallida + reinstalar)**, y Windows **dejó de instalarle el driver** al conectarlo.

**Solución:** con el stick desconectado,

```powershell
pnputil /remove-device "USB\VID_1B8E&PID_C004\<serial>"
```

Luego se conecta el stick 10 s (Windows lo vuelve a crear y le pone WinUSB desde el *Driver Store*) y se agrega el GUID **sin reiniciar el dispositivo**. Eso es lo que hace [`scripts/set-adb-guid.ps1`](scripts/set-adb-guid.ps1).

### 5.3 La 2a etapa con Código 10

Justo después de `reboot bootloader`, la 2a etapa (`VID_18D1&PID_0D02`) apareció con **Código 10 / `0xC00000B5` (timeout de E/S)**. Se resolvió con `pnputil /restart-device` sin desconectar el stick.

### 5.4 Procesos fastboot huérfanos y el servidor adb

Este fue el problema que más tiempo costó. Las esperas de fastboot se lanzaban desde WSL; al cancelarlas, **el `fastboot.exe` de Windows seguía corriendo**. Llegó a haber **3 `fastboot.exe` huérfanos más el servidor `adb.exe`** peleándose por el stick. Síntomas:

- El DNL aparecía 6 s y **ningún** fastboot lo enganchaba.
- En la 2a etapa, `fastboot devices` mostraba el serial como `????????????` y **todo** `getvar` devolvía `FAILED (Device sent unknown status code: )`.

En ese momento lo atribuimos al puerto USB 3 y a la versión de fastboot. **Ninguna de las dos era la causa.** Con un solo proceso, la comunicación fue perfecta.

**Solución:** `Get-Process fastboot, adb | Stop-Process -Force` antes de cada intento, y scripts que cierran su propio fastboot al terminar (`try/finally`).

### 5.5 Cambiar de puerto USB borra el GUID

Al mover el stick a otro puerto, Windows **reconfiguró** el DNL (evento Kernel-PnP 400 "fue configurado"). El INF de Zadig volvió a escribir `DeviceInterfaceGUIDs` **solo con su GUID**, y fastboot dejó de verlo. **Solución:** volver a correr `set-adb-guid.ps1` y **no cambiar de puerto**.

### 5.6 Recovery con el control no funcionó

`Atrás + OK` (y `Atrás + Home`) al conectar el stick no abrieron el menú de Recovery en este equipo. Hay reportes de que en el MDZ-27-AA no funciona ([XDA](https://xdaforums.com/t/mi-stick-4k-mdz-27-aa-bricked-endless-bootloop.4724678/), [comunidad Xiaomi](https://new-ams.c.mi.com/global/post/684347)).

## 6. Si cambiar de slot no funciona

- **Bootloader `01.01.25…/26…` (Android 14):** graba el paquete oficial de Android 14 con el `go.cmd` que trae dentro, según la guía de RodrigoDeveloperX: **[Android 14 recovery](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/blob/main/docs/android-14-recovery.md)**. Verifica antes el hash. Lo dejamos descargado y verificado, pero **no lo necesitamos**.
- **Bootloader de Android 11, ninguno de los dos slots arranca:** el paquete de Android 11 `1440` por DNL con `adnl` ([guía](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery#step-by-step--android-11-route)). Según su autor, solo se ha probado en un equipo cuyo bootloader ya era de Android 14, donde no funcionó.
- **Grabar el paquete de Android 14 completo** también funciona sobre un bootloader de Android 11, porque incluye `bootloader.img`. Es lo mismo que hace la actualización oficial, pero escribir el bootloader es el paso más delicado.

### Sobre el "kit de 1 clic" de otro repositorio

Se encontró [kaiqueizaque-crypto/xiaomi-mi-tv-stick-4k-recovery-tool](https://github.com/kaiqueizaque-crypto/xiaomi-mi-tv-stick-4k-recovery-tool). Lo revisamos y **no lo usamos**. El script no tiene nada malicioso a la vista y repite los comandos del `go.cmd` de Android 14, pero:

- Es un reempaquetado del trabajo de RodrigoDeveloperX.
- Su firmware no publica hash.
- **No revisa si cada comando falló.** Si una partición no se graba, sigue de largo, **vuelve a bloquear el bootloader** y al final muestra "ÉXITO 100%" de todos modos.
- Asume que tienes el caso de Android 14. En un stick como el nuestro (bootloader de Android 11, un slot sano) habría grabado todo, bootloader incluido, sin necesidad.

## 7. Después de recuperarlo

- Úsalo siempre con **cargador de pared**.
- El **slot B sigue dañado**. No afecta mientras uses el A. La próxima actualización del sistema se instala en B y lo reescribe completo.
- **Con cuidado con las actualizaciones:** muy probablemente fue una actualización cortada la que causó el problema (el bootloader `230608`, de junio 2023, es más nuevo que el sistema `1101`, de mayo 2022). Si actualizas, que sea con cargador de pared y sin desconectarlo.
- **Si vuelve a quedarse en el logo:** pasos 4, 5 y 7 otra vez (unos minutos, ya con todo instalado).
- No se reparó B a mano porque no hay un paquete verificado de la versión exacta `1101`, y grabar otra versión también modificaría la partición `super`, que comparten A y B.

## 8. Scripts de este repositorio

| Script | Qué hace | ¿Escribe en el stick? | ¿Admin? |
|---|---|---|---|
| [`scripts/set-adb-guid.ps1`](scripts/set-adb-guid.ps1) | Agrega el GUID ADB al DNL **sin** deshabilitarlo; detecta si quedó deshabilitado | No (solo el registro de Windows) | Sí |
| [`scripts/capturar.ps1`](scripts/capturar.ps1) | Cierra fastboot/adb huérfanos, atrapa el DNL con un solo fastboot, lo pasa a la 2a etapa y lee la información | Solo `reboot bootloader` | No |
| [`scripts/cambiar-slot.ps1`](scripts/cambiar-slot.ps1) | `unlock → set_active → lock → reboot`, pidiendo confirmación, y vigila el USB hasta ver Android | Cambia el slot; **no graba imágenes** | No |

Son texto plano: **léelos antes de correrlos**. Están en ASCII para que PowerShell 5.1 los lea bien.

## 9. Hacerlo más fácil con un asistente de IA (Claude Code, Codex)

Esta recuperación se hizo con **[Claude Code](https://claude.com/claude-code)** en la terminal. Lo mismo se puede hacer con **[Codex CLI](https://github.com/openai/codex)** u otro agente de terminal. El asistente ejecutó los comandos, vigiló el USB, leyó los registros de Windows y encontró las causas de los problemas (el DNL deshabilitado, el GUID borrado, los procesos huérfanos). Tú solo conectas y desconectas el stick y corres los comandos de administrador.

**Cómo usarlo:**

1. Instala el asistente y ábrelo en una terminal **en la PC con Windows** (PowerShell, o WSL con acceso a `powershell.exe`).
2. Dale este repositorio como contexto. Por ejemplo:

   > Mi Xiaomi Mi TV Stick 4K (MDZ-27-AA) se queda en el logo y se reinicia. Sigue la guía de https://github.com/psyberpunk/Xiaomi-Mi-TV-Stick-4K-MDZ-27-AA-Unbrick-Recovery: revisa si Windows ve el DNL (`VID_1B8E&PID_C004`), ayúdame con los drivers y el GUID, atrapa el stick con fastboot y lee `version-bootloader` y `current-slot`. **No grabes ni desbloquees nada sin preguntarme.**

3. Pídele que te diga **qué tipo de bootloop tienes** (sección 2) antes de proponer cualquier cambio.

**Ten en cuenta:**

- **Tú tienes la última palabra.** Revisa cada comando que **escribe** en el stick (`flashing unlock`, `set_active`, `flash …`) antes de aprobarlo. Leer (`getvar`, `devices`) no tiene riesgo.
- Los comandos de **administrador** (`pnputil`, el registro) normalmente los tendrás que ejecutar tú en una PowerShell elevada. El asistente te los da listos para copiar.
- Si el asistente corre comandos de Windows desde WSL, pídele que **cierre cualquier `fastboot.exe`/`adb.exe` antes de cada intento**. Cancelar una tarea en WSL no mata el proceso de Windows, y eso fue lo que más tiempo nos costó ([problema 5.4](#54-procesos-fastboot-huérfanos-y-el-servidor-adb)).
- Igual que con cualquier herramienta: si te propone descargar un "kit de 1 clic" o un firmware **sin hash verificable**, no lo aceptes.

## 10. Referencias y créditos

- **[RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery)**: la investigación de base: las dos etapas de fastboot, el GUID ADB, la tabla de diagnóstico, el firmware con hashes. Sin ese trabajo esto no habría salido.
- **[Hilo de 4PDA del Mi TV Stick 4K](https://4pda.to/forum/index.php?showtopic=1041410)**: origen de los paquetes de firmware (requiere registro).
- **[Zadig / libwdi](https://github.com/pbatard/libwdi)**: Pete Batard / Akeo Consulting.
- **[Android SDK Platform-Tools](https://developer.android.com/tools/releases/platform-tools)** y **[Google USB Driver](https://developer.android.com/studio/run/win-usb)**: Google.
- Foros consultados sobre el modo Recovery: [Whirlpool](https://forums.whirlpool.net.au/archive/35pnvlp0), [HTCMania](https://www.htcmania.com/showthread.php?t=1618069), [XDA](https://xdaforums.com/t/mi-stick-4k-mdz-27-aa-bricked-endless-bootloop.4724678/), [Soporte Mi](https://www.mi.com/global/support/faq/details/KA-557214/).
- Diagnóstico y documentación hechos con la ayuda de [Claude Code](https://claude.com/claude-code).

---

**Aviso:** proyecto no oficial, sin relación con Xiaomi, Amlogic ni Google. El firmware es propiedad de Xiaomi. Los scripts se publican bajo licencia MIT ([LICENSE](LICENSE)), sin garantía de ningún tipo.
