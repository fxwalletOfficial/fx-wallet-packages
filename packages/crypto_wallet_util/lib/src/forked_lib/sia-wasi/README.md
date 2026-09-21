# Sia transaction native library

从 Sia 官方代码精简出的交易签名逻辑，编译成 **原生动态库**，由 Dart 通过 FFI 调用
（见 `lib/src/transaction/sc/sc_go_ffi_bridge.dart`）。用来替代慢速的纯 Dart WASM
解释器（`wasd`）。

## 环境要求

- Go 1.24 或更高版本（CGO 需要本机 C 工具链）

## 文件说明

- `main_cgo.go`：CGO 入口，导出完整交易和 V2 语义签名 C 接口。
- `main_wasip1.go`：WASI reactor 入口，保留旧导出并新增 V2 语义签名导出。
- `transactions.go`：兼容的完整交易 JSON 处理逻辑（基于固定版本 `go.sia.tech/core`）。
- `semantics.go`：严格的 `sia-v2-siacoin-transfer-v1` 编解码、校验和 InputSigHash。
- `build.sh`：编译当前平台的动态库，产物输出到
  `test/native/`，仅作为测试资产。
- `build_wasm.sh`：重建发布资产 `lib/src/transaction/sc/sc.wasm`。

## 构建

```bash
./build.sh
./build_wasm.sh
```

产物命名为 `libsc_transaction_<os>_<arch>.{dylib,so,dll}`，例如
`libsc_transaction_darwin_arm64.dylib`。

## 导出函数

- `process_sc_transaction(inputJson, **outputJson) -> int`：输入 V2 交易 JSON，
  在 `*outputJson` 写入补好签名占位的交易 JSON，成功返回 0。
- `extract_sc_v2_transaction_semantics(inputJson, **outputJson) -> int`：从完整
  unsigned V2 JSON 提取规范语义、模型和 InputSigHash。
- `inspect_sc_v2_transaction_semantics(inputJson, **outputJson) -> int`：严格解析
  规范语义 bytes（hex），返回相同模型和 InputSigHash。
- `free_string(ptr)`：释放 `process_sc_transaction` 返回的字符串。

WASM 额外导出 `getV2TransactionSemantics` 与
`inspectV2TransactionSemantics`；内存 ABI 与旧
`getUnsignedV2Transaction` 共用 `alloc`、`release`、`resultPtr`、`resultLen`。

## 多平台说明

目前 `build.sh` 只构建宿主平台。iOS / Android 需用相应工具链（NDK、iOS SDK）交叉
编译 CGO c-shared 库，并由宿主 App 负责打包，属于后续工作。
