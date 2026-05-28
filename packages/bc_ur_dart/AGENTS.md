# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-18
**Commit:** 054984f
**Branch:** feature/gs-transfer

## OVERVIEW
Dart package for UR (Uniform Resource) encoding/decoding — CBOR-based QR protocol for crypto wallet cold signing. Supports BTC, ETH, SOL, TRON, Cosmos, Aleo.

## STRUCTURE
```
bc_ur_dart/
├── lib/
│   ├── bc_ur_dart.dart        # Public exports
│   └── src/
│       ├── ur.dart             # Core UR class (encode/decode/read/next)
│       ├── models/             # SignRequest/Signature per chain
│       │   ├── alph/           # Aleo
│       │   ├── btc/            # PSBT, GSPL
│       │   ├── eth/
│       │   ├── sol/
│       │   ├── tron/
│       │   ├── cosmos/
│       │   ├── key/            # HDKey, MultiAccounts
│       │   └── common/         # Fragment, Seq
│       ├── registry/           # RegistryType, CryptoTxEntity
│       └── utils/              # CRC32, ByteWords, Type, Error
└── test/                       # 6 test files
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Add new UR type | `lib/src/models/{chain}/` | Create sign_request + signature pair |
| Core UR logic | `lib/src/ur.dart` | encode(), decode(), read(), next() |
| Registry types | `lib/src/registry/` | RegistryType enum, CryptoTxEntity |
| CBOR encoding | Uses `package:cbor` | External dependency |

## CONVENTIONS
- **Model pairs**: `{Chain}SignRequest` + `{Chain}Signature` in same dir
- **Naming**: snake_case files, PascalCase classes
- **Entry**: `lib/bc_ur_dart.dart` (not `index.dart`)
- **Tests**: Flat in `test/`, mirror lib structure loosely

## ANTI-PATTERNS (THIS PROJECT)
- No example/ directory (README claims it exists — it's missing)
- Tests use `flutter test` but this is a pure Dart package (use `dart test`)

## GIT CONSTRAINTS
- **NEVER run `git commit` or `git push`** — ask user explicitly before any git write operations
- Only use read-only git commands (`git log`, `git show`, `git diff`, `git status`, etc.)

## UNIQUE STYLES
- Monorepo via Melos (root: fx-wallet-packages)
- Dependency override via `pubspec_overrides.yaml` (monorepo artifact)
- 54 linter rules in analysis_options.yaml

## COMMANDS
```bash
dart analyze        # Lint check
dart test           # Run tests
dart format .       # Format code
```

## NOTES
- No UREncoder/URDecoder — encoding/decoding is in `UR` class itself
- `UR.decode(string)` → `UR` object
- `ur.encode()` → UR string
- `ur.next()` → fragment for large payloads
