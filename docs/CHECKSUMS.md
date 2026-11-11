# Checksums (SHA-256)

Hashes de los archivos **tal como se usaron** en la recuperación del 2026-11-10. Ninguno se redistribuye aquí: descárgalos de su fuente y compara.

```powershell
Get-FileHash .\archivo -Algorithm SHA256
```

## Herramientas

| Archivo | Fuente | SHA-256 | Firma |
|---|---|---|---|
| `platform-tools_r33.0.3-windows.zip` → `fastboot.exe` (33.0.3-8952118) | [dl.google.com](https://dl.google.com/android/repository/platform-tools_r33.0.3-windows.zip) (zip: 5,642,796 bytes) | `0fcd728122cfd2ed6ab2baaf98070ab484c1d55a4b4b20f6ae663ec3837801fb` | Sin firma Authenticode (build antiguo) |
| `…r33.0.3…\AdbWinApi.dll` | ídem | `d60103a5e99bc9888f786ee916f5d6e45493c3247972cb053833803de7e95cf9` | |
| `…r33.0.3…\AdbWinUsbApi.dll` | ídem | `25207c506d29c4e8dceb61b4bd50e8669ba26012988a43fbf26a890b1e60fc97` | |
| `platform-tools-latest-windows.zip` → `fastboot.exe` (37.0.1-15733141) | [dl.google.com](https://dl.google.com/android/repository/platform-tools-latest-windows.zip) | `b2d9cbff4ce9ae7eb448cfc831bafc867935f50f5be38f8f81057fd7eb3b8d86` | Google LLC (válida) |
| `usb_driver_r13-windows.zip` | [dl.google.com](https://dl.google.com/android/repository/usb_driver_r13-windows.zip) | `360b01d3dfb6c41621a3a64ae570dfac2c9a40cca1b5a1f136ae90d02f5e9e0b` | `androidwinusba64.cat` válida |
| `zadig-2.9.exe` | [github.com/pbatard/libwdi/releases](https://github.com/pbatard/libwdi/releases) | `4ecaa95df3da3621486a043aef8b3050b8bafe7c901402871e816229ef82039b` | Akeo Consulting (válida) |

## Firmware Android 14 (no se usó al final)

`mi-tv-stick-4k_14_26.6.10_91_MDZ-27-AA.7z`: 989,694,390 bytes
SHA-256 `6300f49e9e15ba50e4b6bc9ea7f3243b80178c122b08a440a5e144b8ea6f6711` (coincide con el publicado por [RodrigoDeveloperX](https://github.com/RodrigoDeveloperX/xiaomi-mi-tv-stick-4k-mdz-27-aa-recovery/releases/tag/v2.0-firmware-a14-26.6.10)).

Build `UKG3.250107.001.V816.0.26.6.10.UZFAATK` (Android 14).

| Archivo dentro del paquete | Bytes | SHA-256 |
|---|---|---|
| `bin/fastboot.exe` (36.0.2-14143358) | 2,096,280 | `561bec25f791d2ee75ed57ac84a09960c9fadb62f531240a6896fba1cb091d1d` |
| `images/boot.img` | 67,108,864 | `314646829819f3437a8dd36dad132fcd6b1a08b93b3a516fc65037a5e7503d80` |
| `images/bootloader.img` | 4,100,096 | `9c4ae84ebd363afc5640ccb1fada3f2387e71556837b574ead840aa7705609c6` |
| `images/dtbo.img` | 2,097,152 | `715eb4226f23292eed097b27633a986a1b02a75eb0f730404d5f274cd471d7d8` |
| `images/odm_ext.img` | 16,777,216 | `62479bc1e7fde316381b3487a287024cc0dd386b76715c30b62b326ebe515ae7` |
| `images/oem.img` | 33,554,432 | `2f6f52b20d28610094a7038f7acc13db10254b830a7093eba0e9e0fca3f30e00` |
| `images/super.img` | 1,887,436,800 | `075c4e1b589e9fc0da8dc80a992276a74908c07e2fdcfeb68d64915db1b50a23` |
| `images/vbmeta.img` | 2,097,152 | `644987c4c80b76f3a714c97004dc34239616621044b72a358e5ba0b3f7bb411d` |
| `images/vbmeta_system.img` | 2,097,152 | `e7839f9b4f907c916f5d2b82b88a037396824d5f0abfcefd17395357e0cc19f2` |
| `images/vendor_boot.img` | 25,165,824 | `584cda1789cdc38c37172f21d446837983b05365fc37101d5db23eeba6f4f0fc` |
