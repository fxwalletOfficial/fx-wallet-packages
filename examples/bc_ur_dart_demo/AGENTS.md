# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-18
**Commit:** 054984f
**Branch:** feature/gs-transfer

## OVERVIEW
Flutter demo app for bc_ur_dart — debug & development tool for UR (Uniform Resource) QR code decoding/encoding. Pure mock data, no real on-chain transactions.

## STRUCTURE
```
bc_ur_dart_demo/
├── lib/
│   ├── main.dart              # Entry point, go_router + provider setup
│   ├── home_page.dart         # Home screen with Sprint 1-3 feature cards
│   ├── scan/                  # QR scanning module
│   │   ├── scan_page.dart     # Camera scanner using mobile_scanner
│   │   ├── ur_parser.dart     # UR decoder wrapper
│   │   └── result_page.dart   # Display parsed UR data
│   └── common/                # Shared utilities
│       ├── app_theme.dart      # Light/dark theme config
│       ├── session_store.dart # Provider-based state (active signing sessions)
│       └── copy_helper.dart   # Clipboard utilities
├── ios/                       # iOS native config
├── android/                   # Android native config
└── pubspec.yaml              # Flutter SDK ^3.3.4
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Run app | `flutter run` | Requires camera permission on iOS |
| Add UR type | `lib/scan/ur_parser.dart` | Parse decoded UR to typed objects |
| Modify theme | `lib/common/app_theme.dart` | Material 3 light/dark |
| Session state | `lib/common/session_store.dart` | Active signing session tracking |

## CONVENTIONS (THIS PROJECT)
- Navigation: `go_router` with named routes
- State: `provider` with `ChangeNotifier`
- Theme: Material 3 with system mode
- QR: `mobile_scanner` for camera, `qr_flutter` for generation
- Routes: `/`, `/scan`, `/result`

## ANTI-PATTERNS (THIS PROJECT)
- No real transactions — all mock data per README
- Sprint 2-3 features show toast "开发中" (in development)

## UNIQUE STYLES
- Chinese UI text in About dialog and banners
- Color badges for Sprint milestones (Sprint 2 = orange, Sprint 3 = green)
- Section labels with icons for visual grouping

## COMMANDS
```bash
# Install deps
flutter pub get

# Run (requires camera permission on device)
flutter run

# iOS permission - add to ios/Runner/Info.plist:
# NSCameraUsageDescription: 需要使用摄像头扫描 UR 二维码

# Analyze
cd ../.. && melos run analyze

# Test
cd ../.. && melos run test
```

## NOTES
- Depends on local `bc_ur_dart` package via path: `../../packages/bc_ur_dart`
- Supports: ETH, Cosmos, Solana, Tron, Aleo, PSBT, GSPL, CryptoHDKey, CryptoMultiAccounts
- Progress calculated manually: `receivedPartIndexes.length / seq.length`
