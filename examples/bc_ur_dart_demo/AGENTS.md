# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-19
**Commit:** 054984f
**Branch:** feature/gs-transfer

## OVERVIEW
Flutter demo app for bc_ur_dart — debug & development tool for UR (Uniform Resource) QR code decoding/encoding. Pure mock data, no real on-chain transactions.

## STRUCTURE
```
bc_ur_dart_demo/
├── lib/
│   ├── main.dart              # Entry point: MultiProvider + go_router + ThemeNotifier
│   ├── home_page.dart         # Home screen with Sprint 1-3 feature cards
│   ├── scan/                  # QR scanning module
│   │   ├── scan_page.dart     # Camera scanner using mobile_scanner
│   │   ├── ur_parser.dart     # UR decoder → typed Map
│   │   └── result_page.dart   # Display parsed UR data
│   ├── encode/                # QR generation module
│   │   ├── type_config.dart   # Static type registry (UrTypeConfig, FieldConfig)
│   │   ├── type_selector_page.dart
│   │   ├── form_page.dart     # Dynamic form generator
│   │   ├── qr_display_page.dart # Animated multi-frame QR
│   │   └── ur_encoder.dart    # buildUR() unified encoder
│   └── common/                # Shared utilities
│       ├── app_theme.dart     # Material 3 light/dark
│       ├── session_store.dart # Signing session state
│       ├── mock_data.dart     # Mock params for 16+ types
│       └── copy_helper.dart   # Clipboard + CopyableField
├── ios/                       # iOS native config + camera permission
├── android/                   # Android native config
└── pubspec.yaml              # Flutter SDK ^3.3.4, local path to bc_ur_dart
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Run app | `flutter run` | Requires camera permission on iOS |
| Add UR type | `lib/encode/type_config.dart` + `lib/encode/ur_encoder.dart` + `lib/scan/ur_parser.dart` | See "Add New UR Type" below |
| Modify theme | `lib/common/app_theme.dart` | Material 3 light/dark |
| Session state | `lib/common/session_store.dart` | Active signing session (Sprint 3) |
| Theme switching | `main.dart` `ThemeNotifier` class | system/light/dark cycle |
| Mock data | `lib/common/mock_data.dart` | All UR type mock params |

## ROUTES (go_router named routes)
| Name | Path | Builder |
|------|------|---------|
| `home` | `/` | `HomePage()` |
| `scan` | `/scan` | `ScanPage()` |
| `result` | `/result` | `ResultPage(urData)` |
| `encode` | `/encode` | `TypeSelectorPage()` |
| `form` | `/encode/form` | `FormPage(config: UrTypeConfig)` |
| `qr` | `/encode/qr` | `QrDisplayPage(type, params)` |

## CONVENTIONS (THIS PROJECT)
- Navigation: `go_router` with named routes
- State: `provider` with `ChangeNotifier` (SessionStore, ThemeNotifier)
- Theme: Material 3 with `ThemeNotifier` (system/light/dark cycling)
- QR: `mobile_scanner` for camera, `qr_flutter` for generation
- Data flow: Scan → `parseUR()` → Map | Encode → `buildUR()` → animated `qr_flutter`
- Private `_` widgets: `_ModuleCard`, `_InfoBanner`, `_ScanOverlay`, etc.

## ADD NEW UR TYPE
1. `lib/encode/type_config.dart` — Add `UrTypeConfig` to `kUrTypeConfigs`
2. `lib/common/mock_data.dart` — Add mock params keyed by type
3. `lib/encode/ur_encoder.dart` — Add switch case in `buildUR()`
4. `lib/scan/ur_parser.dart` — Add switch case in `parseUR()`

## ANTI-PATTERNS (THIS PROJECT)
- All mock data — no real on-chain transactions
- Sprint 3 features show "In Development" toast (not implemented)
- Empty catch blocks in `qr_display_page.dart` silently swallow parsing errors

## BUILD & TEST
```bash
# Install deps
flutter pub get

# Run (device with camera recommended)
flutter run

# iOS camera permission - ios/Runner/Info.plist:
# NSCameraUsageDescription: Camera access for UR QR scanning

# Monorepo analysis/test (run from repo root)
cd ../.. && melos run analyze
cd ../.. && melos run test
```

## NOTES
- Depends on local `bc_ur_dart` via `path: ../../packages/bc_ur_dart`
- Supports: ETH, Cosmos, Solana, Tron, Alephium, PSBT, GSPL, CryptoHDKey, CryptoMultiAccounts
- Progress calculation: `receivedPartIndexes.length / seq.length` (manual, UR class has no progress property)
- ThemeNotifier lives in `main.dart` (not extracted to lib/common/ — deviation from Flutter convention)
