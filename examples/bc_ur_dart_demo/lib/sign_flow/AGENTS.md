# SIGN FLOW MODULE

**Parent:** `../AGENTS.md`

## OVERVIEW

Two-step signing flow: build SignRequest QR → scan Signature QR → validate requestId binding. Hardware wallet integration demo.

## FILES

| File                          | Lines | Purpose                                  |
| ----------------------------- | ----- | ---------------------------------------- |
| `sign_flow_entry_page.dart` | 128   | Select coin type, shows flow explanation |
| `sign_step1_page.dart`      | 705   | Build SignRequest → display animated QR |
| `sign_step2_page.dart`      | 305   | Scan Signature QR → validate requestId  |
| `sign_result_page.dart`     | 306   | Display validation result                |

## FLOW

```
SignFlowEntryPage → select coin type
  └─ pushNamed('sign_step1', extra: config)
       └─ SignStep1Page
            ├─ Build SignRequest via buildUR()
            ├─ Display animated QR (hardware wallet scans)
            ├─ Save requestId to SessionStore
            └─ pushNamed('sign_step2')
                 └─ SignStep2Page (camera scanner)
                      ├─ Scan Signature QR frames
                      ├─ parseUR() → extract requestId
                      ├─ Compare with SessionStore.requestId
                      └─ pushNamed('sign_result', extra: {...})
                           └─ SignResultPage (validation result)
```

## SESSION STATE

`SessionStore` (`common/session_store.dart`) holds:

- `currentRequestId` — UUID from Step 1 SignRequest
- `currentCoinType` — e.g. "ETH", "Solana"
- `signRequest` — raw params map from Step 1

Session is cleared on cancel or back-to-home.

## KEY IMPLEMENTATIONS

### SignStep1Page

- `buildField()` top-level function from `form_page.dart` is reused for parameter editing panel
- `SessionStore.startSignSession()` called after successful UR build
- `ur.maxLength` controls frame size (20-200 bytes/frame)
- `AnimatedSwitcher` with `ValueKey(currentFrame)` for smooth QR transitions

### SignStep2Page

- `calcProgress()` from `ur_parser.dart` for scan progress
- `_ScanOverlay` + `_OverlayPainter` — identical to `scan_page.dart` (duplicated)
- requestId validation: case-insensitive hex string comparison

### SignResultPage

- `_VerifyBanner` — 3 states: success / error / mismatch
- `_IdCompareCard` — visual Step1-generated vs Step2-scanned comparison
- Copy-all button assembles full result text

## ROUTES

| Name            | Path                  | Page                            |
| --------------- | --------------------- | ------------------------------- |
| `sign_flow`   | `/sign_flow`        | `SignFlowEntryPage`           |
| `sign_step1`  | `/sign_flow/step1`  | `SignStep1Page(UrTypeConfig)` |
| `sign_step2`  | `/sign_flow/step2`  | `SignStep2Page`               |
| `sign_result` | `/sign_flow/result` | `SignResultPage(Map data)`    |

## DUPLICATION ISSUES

- `_ScanOverlay` + `_OverlayPainter` are **identical** to `scan/scan_page.dart` — should be extracted to `common/scan_overlay.dart`
- `buildField()` top-level function is **duplicated** from `form_page.dart` — could extract to `common/form_fields.dart`
- Field rendering logic in `FormPage` State class **duplicates** the top-level `buildField()` function

## ANTI-PATTERNS

- Chinese UI text: "两步签名流程", "发起请求", "扫描签名", etc. — needs English translation
- `withOpacity()` deprecated → use `withValues(alpha: x)` throughout
- Empty catch in `_onDetect` (line 61-63) silently ignores non-UR QR codes

## ADD COIN TYPE TO SIGN FLOW

1. Add to `kUrTypeConfigs` in `encode/type_config.dart` with `isSignRequest: true`
2. It automatically appears in `kSignFlowTypes` (filtered by `isSignRequest`)
3. Add mock data in `mock_data.dart` keyed by type string
