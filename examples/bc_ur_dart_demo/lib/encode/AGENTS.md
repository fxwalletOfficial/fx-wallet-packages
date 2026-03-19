# ENCODE MODULE

**Parent:** `../AGENTS.md`

## OVERVIEW
QR code generation module — type selection → dynamic form → UR encoding → animated multi-frame QR display.

## FILES
| File | Lines | Purpose |
|------|-------|---------|
| `type_config.dart` | 313 | Static `kUrTypeConfigs` list + `FieldType` enum + helpers |
| `type_selector_page.dart` | 96 | Chain-grouped type selector (`Ethereum`, `Cosmos`, `Solana`, etc.) |
| `form_page.dart` | 300 | Dynamic form generator from `UrTypeConfig` |
| `qr_display_page.dart` | ~400 | Animated multi-frame QR with size/frame controls |
| `ur_encoder.dart` | 270 | `buildUR()` unified factory for all UR types |

## ENCODE FLOW
```
TypeSelectorPage → pushNamed('form', extra: config)
  └─ FormPage (dynamic fields from UrTypeConfig)
       └─ _collectParams() → Map<String, dynamic>
       └─ pushNamed('qr', extra: {'type': ..., 'params': ...})
            └─ QrDisplayPage → buildUR(type, params)
                 └─ ur.next() → frame string → QrImageView
                 └─ Timer.periodic → animate frames
```

## TYPE CONFIG SYSTEM

### `FieldType` enum
`text`, `hex`, `path`, `address`, `integer`, `dropdown`, `jsonList`, `jsonMap`, `xpub`

### `FieldConfig`
```dart
FieldConfig(key: 'signData', label: 'Sign Data (hex)', 
    type: FieldType.hex, required: true, options: null, hint: '...')
```

### `UrTypeConfig`
```dart
UrTypeConfig(type: 'eth-sign-request', label: 'ETH Sign Request',
    group: 'Ethereum', isSignRequest: true, fields: [...])
```

### Grouped access
```dart
kUrTypesByGroup  // Map<String, List<UrTypeConfig>>
findConfig(type)  // UrTypeConfig? lookup by type string
```

## BUILDUR() FACTORY
Located: `ur_encoder.dart`

**Old style** (UR IS-A object): ETH, PSBT, GSPL, HDKey, MultiAccounts — return directly
**New style** (.toUR() conversion): Cosmos, Solana, Tron, Alph — call `.toUR()` on the object

Callers always get `UR` — call `ur.next()` for frame strings.

### Signature builders (internal)
- `_buildEthSignature(params)` — manual CBOR with CborMap + CborBytes
- `_buildPsbtSignature(params)` — same pattern
- `_buildGsplSignature(params)` — uses `GsplTxData.toCbor()`

### Enum converters
- `_ethDataType(name)` → `EthSignDataType`
- `_solSignType(name)` → `SignType`
- `_gsplDataType(name)` → `GsplDataType`

## QR DISPLAY CONTROLS
- **Frame size slider** (`_maxLength: 10-100`): Smaller = more frames, larger = fewer frames
- **QR size slider** (`_qrSize: 160-400px`)
- **Play/Pause** animation toggle for multi-frame
- **Copy current frame** button in app bar

## FORM FEATURES
- **Mock Data** button: fills form from `kMockByType[type]`
- **JSON validation**: `jsonDecode()` check with user-friendly error messages
- **Required field validation**: `${field.label} is required`
- **Dropdown fields**: `FieldType.dropdown` → `DropdownButtonFormField`

## ADD NEW UR TYPE (ENCODING)
1. `type_config.dart`: Add `UrTypeConfig` with `FieldConfig` fields
2. `mock_data.dart`: Add mock params in `kMockByType`
3. `ur_encoder.dart`: Add `case 'type-string':` in `buildUR()` switch
4. `ur_parser.dart` (scan module): Add parsing case in `parseUR()`

## ANTI-PATTERNS
- `_SliderRow` tooltips require `IconButton` wrapper for reliable touch detection
- `withOpacity()` deprecated → use `withValues(alpha: x)` in Material 3
- Empty catch blocks in `qr_display_page.dart` silently swallow parse errors
