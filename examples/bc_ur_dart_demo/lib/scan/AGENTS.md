# SCAN MODULE

**Parent:** `../AGENTS.md`

## OVERVIEW
QR code scanning module — camera capture → multi-frame UR accumulation → parsed result display.

## FILES
| File | Lines | Purpose |
|------|-------|---------|
| `scan_page.dart` | 239 | Stateful camera controller, frame accumulation, progress UI |
| `ur_parser.dart` | 260 | `parseUR()` switch on 16 UR types, `calcProgress()` helper |
| `result_page.dart` | ~135 | Display parsed UR fields with copy functionality |

## SCAN FLOW
```
Camera → MobileScanner.onDetect → _onDetect()
  └─ ur.read(frame) → accumulate frames
  └─ calcProgress(ur) → update progress bar
  └─ done == true → parseUR(ur) → pushNamed('result', extra: result)
  └─ on exit → _reset() → restart camera for re-scan
```

## KEY FUNCTIONS

### `parseUR(UR ur) → Map<String, dynamic>`
Located: `ur_parser.dart`

Switch on `ur.type.toLowerCase()` for 16 UR types:
- ETH: `EthSignRequestUR.fromUR()`, `EthSignatureUR.fromUR()`
- Cosmos: `CosmosSignRequest.fromCBOR()`, `CosmosSignature.fromCBOR()`
- Solana: `SolSignRequest.fromCBOR()`, `SolSignature.fromCBOR()`
- Tron: `TronSignRequest.fromCBOR()`, `TronSignature.fromCBOR()`
- Alph: `AlphSignRequest.fromCBOR()`, `AlphSignature.fromCBOR()`
- PSBT: `PsbtSignRequestUR.fromUR()`, `PsbtSignatureUR.fromUR()`
- GSPL: `GsplSignRequestUR.fromUR()`, `GsplSignatureUR.fromUR()`
- HD Key: `CryptoHDKeyUR.fromUR()`
- Multi Accounts: `CryptoMultiAccountsUR.fromUR()`
- Unknown: return raw payload hex

Returns `{'type': ..., 'fields': {...}, 'isError'?: true}`.

### `calcProgress(UR ur) → double`
Located: `ur_parser.dart`

Manual progress: `ur.receivedPartIndexes.length / ur.seq.length` (clamped 0.0-1.0).
Single-frame UR: `ur.isComplete ? 1.0 : 0.0`.

## SCAN PAGE WIDGETS
- `_ScanOverlay` — CustomPaint corner brackets over camera
- `_OverlayPainter` — Draws shadow + white corner L-shapes
- Progress bar in bottom status area

## ANTI-PATTERNS
- Empty catch in `_onDetect` catches non-UR QR codes (acceptable — falls through to plain-text display)
- Camera restart on `_reset()` called via `Future.delayed` after navigation

## ADD NEW UR TYPE (DECODING)
1. Add case in `parseUR()` switch matching the UR type string
2. Call the appropriate `fromCBOR()` or `fromUR()` method
3. Return `{'type': ..., 'fields': {...}}` map

## ROUTE
- `result` route receives `extra: Map<String, dynamic>` from `parseUR()`
