# Xiaomi Mi TV Stick 4K (MDZ-27-AA) — Unbrick / Recovery from Windows

🇪🇸 **[Versión en español → README.md](README.md)**

This is how we recovered a **Xiaomi Mi TV Stick 4K (MDZ-27-AA, codename `soul`)** that was **stuck on the Xiaomi logo and kept rebooting**. We did it **without flashing any firmware**: we only switched the **active A/B slot** with `fastboot`, from a **Windows 11** PC.

> **Result (2026-11-10):** the stick booted back into Android TV with its original system (`RTT0.211222.001.1101`, Android 11).
> Full log with real timestamps and outputs (in Spanish): **[docs/bitacora.md](docs/bitacora.md)**

---

## ⚠️ Before you start

- This is a **report of one real recovery on one device**. It is not a product and not a guarantee. You do this at your own risk.
- `fastboot flashing unlock` **may wipe your data** (apps, accounts, settings).
- If your stick **still boots**, you don't need any of this.
- This repository **does not redistribute** firmware or third-party programs. Everything links to its original source, and the SHA-256 hashes are in [docs/CHECKSUMS.md](docs/CHECKSUMS.md).

## 1. Symptoms

- The stick powers on, shows the **Xiaomi / Mi logo** and **reboots**, over and over.
- The remote's **Recovery combo (`Back + OK` while plugging in) does nothing** on this device.
- **ADB is useless**, because Android never finishes booting.
- When you plug it into a PC, Windows sees a device named **`DNL`** (`USB\VID_1B8E&PID_C004`) for **3–6 seconds** and then it disappears. That is the Amlogic USB emergency mode. On this device **it does not keep cycling**: it only shows up right after you plug it in, so every attempt means unplugging and plugging it back in.

## 2. Which brick do you have?

The symptom on the TV looks the same in every case, but there are **different causes that need different fixes**. You tell them apart by reading the bootloader version with fastboot (step 5):

| `version-bootloader` | Meaning | What to do |
|---|---|---|
| `01.01.23xxxx` (e.g. `01.01.230608.170904`) **← our case** | **Android 11**-era bootloader. One slot (usually the active one) is broken, for example by an interrupted update. | **Switch slots first** (step 7). Nothing gets flashed. |
| `01.01.25xxxx` / `01.01.26xxxx` | The **Android 11 → 14** OTA failed partway: the bootloader is already Android 14, but the system is not. | Flash the full **Android 14** package (section 6). Android 11 will **never** boot on that bootloader. |
| `0.1` and `product: amlogic` | You are still in the **1st** fastboot stage. | Run `fastboot reboot bootloader` (not `reboot fastboot`). |

The table comes from [RodrigoDeveloperX's work](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery#which-brick-do-you-have). Our device confirmed the first row.

## 3. What you need

**Hardware:** the stick, a **data-capable USB cable** (test it with a phone first), a Windows 10/11 PC with **admin** rights, and a 5V / 1–2A wall charger for using the stick on the TV afterwards.

**Software (all official, linked to the source):**

| Program | Purpose | Where | Verification |
|---|---|---|---|
| **Android SDK Platform-Tools r33.0.3** | The `fastboot.exe` that **did** catch the stick in DNL | <https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip> | Direct from Google. This old build is not Authenticode-signed. Hash in [CHECKSUMS](docs/CHECKSUMS.md). |
| **Google USB Driver r13** | Driver for the **2nd** fastboot stage (`VID_18D1`) | <https://dl.google.com/android/repository/usb_driver_r13-windows.zip> | Signed catalog (valid). |
| **Zadig 2.9** | Puts **WinUSB** on the **DNL** device (`1B8E:C004`) | <https://github.com/pbatard/libwdi/releases> | Signed by **Akeo Consulting** (valid). |
| *(Optional)* Android 14 package `mi-tv-stick-4k_14_26.6.10_91_MDZ-27-AA.7z` | Only if switching slots isn't enough (section 6) | [RodrigoDeveloperX release](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/tag/v2.0-firmware-a14-26.6.10) | SHA-256 `6300f49e9e15ba50e4b6bc9ea7f3243b80178c122b08a440a5e144b8ea6f6711`. We checked it and it matched. |

We set aside the newer platform-tools (v37.0.1) during the session, but **that test wasn't clean** (see 5.4). All we know for sure is that **r33.0.3 worked**. The folder we used was `C:\MiStick\`, with platform-tools extracted to `C:\MiStick\platform-tools\`.

## 4. Step by step on Windows

1. **Google driver.** Run this in an admin PowerShell:
   ```powershell
   pnputil /add-driver C:\MiStick\usb_driver\android_winusb.inf /install
   ```
   Our stick's 2nd stage shows up as **`VID_18D1&PID_0D02`** ("Android ADB Interface"). It binds to this driver through the compatible ID `USB\Class_FF&SubClass_42&Prot_03`.
2. **WinUSB on DNL with Zadig, using the timing trick.**
   - Open Zadig and turn on **Options → List All Devices**.
   - Unplug the stick, wait 3 s, plug it back in, and open the list right away.
   - Pick **`DNL` (`1B8E C004`)**, choose **WinUSB**, and click **Install Driver**. If the stick disappears mid-install, that's fine: the driver package stays in the Driver Store.
   - Plug the stick in once more so Windows binds the driver.
3. **Add the ADB interface GUID to DNL.** Use an admin PowerShell, with the stick unplugged:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\set-adb-guid.ps1
   ```
   Without the GUID, fastboot sits at `< waiting for any device >` forever. **Don't switch USB ports after this step** (see 5.5).
4. **Kill any stray fastboot/adb:**
   ```powershell
   Get-Process fastboot, adb -ErrorAction SilentlyContinue | Stop-Process -Force
   ```
   Don't run `adb devices` during this process, because it leaves an adb server running in the background.
5. **Catch the stick and read its info:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\capturar.ps1
   ```
   When the script says it's waiting, unplug the stick, wait 3 s and plug it back in. Here is what ours returned:
   ```
   product: soul
   version-bootloader: 01.01.230608.170904
   is-userspace: no
   current-slot: b
   slot-count: 2
   unlocked: no
   ```
   If the 2nd stage shows **Code 10** (`0xC00000B5`, I/O timeout), run this in an admin PowerShell without unplugging the stick:
   ```powershell
   pnputil /restart-device "USB\VID_18D1&PID_0D02\<InstanceId>"
   ```
6. **Decide using the table in section 2.**
7. **Switch slots.** No images are flashed:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\cambiar-slot.ps1
   ```
   This is what happened on ours:
   ```
   set_active a      -> FAILED (remote: 'locked device')
   flashing unlock   -> OKAY
   set_active a      -> OKAY
   flashing lock     -> OKAY
   reboot            -> OKAY
   ```
   About 100 s later, Windows showed **`MTP USB Device` (`VID_18D1&PID_4EE1`)**, which means **Android had booted**. The TV reached Android TV normally.

## 5. Problems we hit and how we solved them

1. **Windows saw nothing at first.** The stick simply wasn't plugged into the PC yet. If it is plugged in and you still see nothing, suspect the cable or the port.
2. **Another project's GUID script disabled the DNL device.** `fix-adnl-guid.ps1` runs `Disable-PnpDevice` + `Enable-PnpDevice`. With the stick unplugged, the disable went through and the enable failed. That left **`ConfigFlags = 0x61`** (disabled + failed install), and Windows stopped binding the driver.
   **Fix:** run `pnputil /remove-device "USB\VID_1B8E&PID_C004\<serial>"`, replug the stick, then add the GUID **without** restarting the device (that's what `set-adb-guid.ps1` does).
3. **The 2nd stage came up with Code 10.** Fixed with `pnputil /restart-device`.
4. **Orphaned fastboot processes and the adb server.** This cost the most time. The fastboot waits were launched from WSL, and cancelling them left the Windows `fastboot.exe` running. At one point **3 orphaned `fastboot.exe` plus `adb.exe`** were fighting over the stick. The result was missed captures, a serial shown as `????????????`, and every `getvar` returning `FAILED (Device sent unknown status code: )`. At the time we blamed the USB 3 port and the fastboot version. **Neither was the cause.** With a single process, communication was flawless.
5. **Changing USB ports wipes the GUID.** On a new port, Windows reconfigures the DNL device (Kernel-PnP event 400), and Zadig's INF rewrites `DeviceInterfaceGUIDs` with only its own GUID. Re-run `set-adb-guid.ps1` and stay on the same port.
6. **The remote's Recovery combo didn't work** on this MDZ-27-AA, which matches other reports.

## 6. If switching slots doesn't work

- **Bootloader `01.01.25…/26…`:** flash the official Android 14 package with its own `go.cmd`, following [RodrigoDeveloperX's Android 14 recovery guide](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/blob/main/docs/android-14-recovery.md). Verify the hash first.
- **Android 11 bootloader, and neither slot boots:** use the Android 11 `1440` package over DNL with `adnl` ([guide](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery#step-by-step--android-11-route)). Its author only tested it on a device whose bootloader was already Android 14, where it did not work.
- **About the third-party "1-click kit"** ([kaiqueizaque-crypto/…](https://github.com/kaiqueizaque-crypto/xiaomi-mi-tv-stick-4k-recovery-tool)): we reviewed it and did **not** use it.
  - It repackages RodrigoDeveloperX's work.
  - It publishes no firmware hash.
  - **It never checks whether a command failed.** It re-locks the bootloader and prints "100% SUCCESS" either way.
  - It assumes the Android 14 case, so on a stick like ours it would have flashed everything, bootloader included, for no reason.

## 7. After recovery

- Always power the stick from a **wall charger**.
- **Slot B is still broken.** That's harmless while you're on A. The next system update installs to B and rewrites it completely.
- **Be careful with updates.** An interrupted update most likely caused this: the bootloader `230608` (June 2023) is newer than the system `1101` (May 2022). If you update, use a wall charger and don't unplug the stick.
- **If it bootloops again,** repeat steps 4, 5 and 7.

## 8. Scripts

| Script | What it does | Writes to the stick? | Admin? |
|---|---|---|---|
| [`scripts/set-adb-guid.ps1`](scripts/set-adb-guid.ps1) | Adds the ADB GUID to DNL **without** disabling the device, and detects a disabled DNL | No (Windows registry only) | Yes |
| [`scripts/capturar.ps1`](scripts/capturar.ps1) | Kills stray fastboot/adb, catches DNL with a single fastboot, moves the stick to the 2nd stage, and reads its info | Only `reboot bootloader` | No |
| [`scripts/cambiar-slot.ps1`](scripts/cambiar-slot.ps1) | `unlock → set_active → lock → reboot` after asking for confirmation, then watches USB until Android shows up | Changes the slot; **flashes no images** | No |

The scripts' messages are in Spanish. **Read them before you run them.**

## 9. References and credits

- **[RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery)**: the core research (the two fastboot stages, the ADB GUID, the diagnosis table, and the firmware with hashes).
- **[4PDA thread](https://4pda.to/forum/index.php?showtopic=1041410)**: where the firmware packages come from.
- **[Zadig / libwdi](https://github.com/pbatard/libwdi)** (Pete Batard / Akeo), **[Platform-Tools](https://developer.android.com/tools/releases/platform-tools)** and the **[Google USB Driver](https://developer.android.com/studio/run/win-usb)** (Google).
- Diagnosis and documentation were done with the help of [Claude Code](https://claude.com/claude-code).

**Disclaimer:** this is an unofficial project, not affiliated with Xiaomi, Amlogic or Google. The firmware belongs to Xiaomi. The scripts are MIT-licensed ([LICENSE](LICENSE)) and come with no warranty.
