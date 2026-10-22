# RFID Chameleon

**[Русская версия](README.md)**

Android app for reading and writing filament RFID tags via **[Chameleon Ultra](https://github.com/RfidResearchGroup/ChameleonULtra)** over Bluetooth LE. It brings the core BoxRFID-Touch workflows to a phone: QIDI, OpenSpool, Snapmaker U1, saved tags, and `.bin` import/export.

The app works **over BLE only** — no USB connection is used. It does not manage Chameleon itself (slots, emulation, DFU, or firmware); the device acts as an RFID reader/writer.

## Features

- **QIDI**
  - QIDI Plus 4 / Max 4 and QIDI Q2.
  - Read/write MIFARE Classic 1K, block 4, key A `FFFFFFFFFFFF`.
  - Built-in material lists, 24 colors, manufacturers.
  - Import a QIDI CFG file to use a custom material list.
- **OpenSpool**
  - Read/write NTAG215/216 in NDEF JSON format.
  - **OpenSpool Standard** and **Snapmaker U1** profiles.
  - Basic / Standard / All (U1) data versions, material presets, and color picker.
  - Additional U1 fields: subtype, alpha, bed temperatures, weight, diameter, additional colors.
- **Saved tags**
  - Saved only when you explicitly tap **“Save to data”**.
  - Automatic naming, rename, and delete.
  - Rewrite a tag from a saved record.
  - Export `.bin` and import `.bin`, with type detected by file size.
- **Snapmaker U1**
  - Host/port settings and HTTP connectivity check.
  - ToolHead status.
  - Send OpenSpool U1 data to the printer — **without Chameleon**; the phone and printer must be on the same Wi-Fi network.
- **Interface**
  - Russian and English.
  - Automatic Chameleon discovery and auto-connect to the last device.
  - The last tab and selected tag options are remembered.

## Requirements

- Android phone with Bluetooth LE.
- Chameleon Ultra connected over BLE. Lite detection exists in the code, but the primary tested setup is Ultra.
- Tags:
  - **MIFARE Classic 1K** for QIDI;
  - **NTAG215 or NTAG216** for OpenSpool and Snapmaker U1; NTAG213 is not supported.
- For sending to U1: a Snapmaker U1 on the same network, HTTP port `7125` by default.
- Android permissions: Bluetooth / “Nearby devices”; older Android versions also need location.

## Usage

1. Open the **Connection** tab and wait for Chameleon to be found automatically. If needed, tap **“Start search”** and pick the device manually.
2. Open the **Tag** tab and select **QIDI**, **OpenSpool**, or **Snapmaker U1**.
3. Place the tag on Chameleon and tap **“Read tag”**, or fill in the data and tap **“Write tag”**. A write is verified by reading the tag back.
4. To save the data, tap **“Save to data”**. Otherwise the tag is not added to the list.
5. The **Data** tab contains saved tags. From there you can write a tag again, rename or delete a record, and export `.bin`.
6. To import `.bin`, tap **“Import .bin”** in the Data tab. QIDI (1024 bytes), NTAG215 (540 bytes), and NTAG216 (924 bytes) files are supported.
7. For U1, open **Settings → Snapmaker U1**, enter host/port, save, and tap **“Check”**. Sending is available from the U1 form and from a saved U1 record.

Without Chameleon, saving, record management, `.bin` import/export, and sending to U1 remain available. Tag read/write buttons are disabled.

## Formats

### QIDI

- Tag: MIFARE Classic 1K.
- Data: block 4, 16 bytes.
- Bytes: `[material_id, color_id, manufacturer_id, 0, ... 0]`.
- `.bin` dump: 1024 bytes; data is located at offset `4 × 16 = 64`.
- UID and sector trailers are filled automatically during export if they are missing from the source tag.

### OpenSpool

- Tags: NTAG215 (135 pages, 504 bytes) or NTAG216 (231 pages, 888 bytes).
- CC: `E1 10 3E 00` for NTAG215, `E1 10 6D 00` for NTAG216.
- NDEF record with MIME `application/json`.
- The JSON contains `protocol: "openspool"`, `version: "1.0"`, material type, and color; U1 adds extended fields.
- User data: pages 4–129 (NTAG215) or 4–225 (NTAG216).
- `.bin` dump: 540 bytes (NTAG215) or 924 bytes (NTAG216).
- NTAG213 is not supported.

### QIDI CFG

The app imports a text configuration file with `[filaN]` sections and fields such as `filament`, `type`, `min_temp`, `max_temp`, `box_min_temp`, and `box_max_temp`. The imported list replaces the built-in one until CFG is reset in Settings.

## Settings

- **Language / Язык** — Russian or English.
- **Automatic scanning** — repeat the Chameleon search at startup and after connection loss.
- **Automatically connect to the last device** — connect to a previously used device if it is found.
- **QIDI CFG** — import `.cfg` and reset to the built-in lists.
- **Snapmaker U1** — host, port, and ToolHead check.

Manual editing of the built-in material and manufacturer lists is not implemented yet; QIDI uses CFG import.

## Technologies

- Flutter / Dart, Material 3.
- `provider` — app state.
- `flutter_blue_plus` — BLE.
- `shared_preferences` — settings and selected options.
- `path_provider` — local record storage.
- `file_picker` — file import and export.
- `http` — requests to Snapmaker U1.
- `permission_handler` — Android permissions.

Data is stored locally on the phone. Network access is used only for Snapmaker U1.

## Project structure

```text
lib/
  core/
    ble/                 Chameleon connection and auto-discovery
    chameleon/           BLE transport and Chameleon protocol
  data/
    qidi/                QIDI models, lists, CFG, and .bin
    openspool/           OpenSpool models, NDEF, and .bin
    records/             saved tags
    snapmaker/           U1 settings and models
  services/              tag read/write and U1 HTTP client
  ui/                    screens: connection, tag, data, settings
  l10n/                  Russian–English translations
```

## Build

The project is built with standard Flutter tooling. The release APK is signed with a separate key; the signing parameters and the key itself are stored locally and are not part of the repository. Universal and per-ABI builds are placed in `relase/`.

## Status and limitations

- QIDI read/write has been verified on a real Chameleon and a MIFARE Classic 1K tag.
- OpenSpool on NTAG215/216 and the Snapmaker U1 integration have not yet been tested on real hardware.
- Android only; there is no iOS version.
- No USB OTG, slot management, emulation, DFU/firmware updates, logs, or calibration.
- Snapmaker U1 uses HTTP without authentication; the phone and printer must be on the same network.
- This app is not an official QIDI, Snapmaker, or OpenSpool product.

## Acknowledgements

- [ChameleonUltraGUI](https://github.com/GameTec-live/ChameleonUltraGUI) — an open-source project for working with Chameleon Ultra, used as a reference for the BLE protocol and device commands.
- [BoxRFID-Touch](https://github.com/TinkerBarn/BoxRFID-Touch) — the source of QIDI/OpenSpool logic and formats; lists and behavior were checked against v4.2.1.
- [OpenSpool](https://github.com/spuder/openspool) — documentation and specification for the OpenSpool NDEF JSON tag format.
- [U1-RFID](https://github.com/DnG-Crafts/U1-RFID) — documentation for the Snapmaker U1 OpenSpool format and the official U1 tag protocol.

Thanks to the authors and contributors of these projects for their open materials.

## License

This project is licensed under the **GNU General Public License v3.0**. The full license text is available in [LICENSE](LICENSE).
