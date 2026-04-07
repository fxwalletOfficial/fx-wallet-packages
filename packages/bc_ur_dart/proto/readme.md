

## Development Setup


### 1.**Install protoc**

#### Windows :

```powershell
winget install protobuf

protoc --version

## Install Dart Plugin for protobuf 4.x
dart pub global activate protoc\_plugin 21.1.2
```

Add `%USERPROFILE%\\AppData\\Local\\Pub\\Cache\\bin` to `Path`

#### macOS :

```
brew install protobuf
```

### 2.**Generate Dart Code**

```powershell
protoc --dart_out=lib/src/gen --proto_path=proto keystone/base.proto keystone/payload.proto keystone/transaction.proto keystone/sign_transaction_result.proto keystone/chains/btc_transaction.proto keystone/chains/bch_transaction.proto
```

