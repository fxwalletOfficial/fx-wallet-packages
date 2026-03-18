# bc_ur_dart Demo

调试 & 开发工具 App。**数据纯模拟，不涉及真实上链。**

## 快速接入

### 1. 目录结构

```
fx-wallet-packages/packages/bc_ur_dart/
├── lib/                 ← 包本体
├── pubspec.yaml
└── example/             ← 本项目（放这里）
    ├── pubspec.yaml     ← path: ../
    └── lib/
```

### 2. 依赖安装

```bash
cd packages/bc_ur_dart/example
flutter pub get
```

### 3. iOS 摄像头权限

在 `ios/Runner/Info.plist` 中添加：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用摄像头扫描 UR 二维码</string>
```

### 4. 运行

```bash
flutter run
```

## UR API

```dart
// ── 解码（扫码方向）────────────────────────────────────────

final ur = UR();                    // 创建空接收器
final done = ur.read(qrFrame);      // 喂入一帧，true = 数据完整

// 进度计算（UR 类无 progress 属性，手动算）
final total = ur.seq.length;        // 总帧数，0 表示单帧
final received = ur.receivedPartIndexes.length;
final progress = total > 0 ? received / total : (ur.isComplete ? 1.0 : 0.0);

// 解码具体类型
if (ur.isComplete) {
  final type = ur.type;   // 如 'eth-sign-request'（小写）
  final req = EthSignRequestUR.fromUR(ur: ur);  // ✅ 真实类名
}

// ── 编码（生成方向，Sprint 2）──────────────────────────────

final req = EthSignRequestUR.fromMessage(
  dataType: EthSignDataType.ETH_TRANSACTION_DATA,
  address: '0x...',
  path: "m/44'/60'/0'/0/0",
  origin: 'demo',
  xfp: '12345678',
  signData: '0xabcd...',
  chainId: 1,
);

// req 本身就是 UR 子类，直接调用 next() 生成帧
final frame = req.next();           // 每次调用返回下一帧字符串
// 用 Timer 循环调用 next()，用 qr_flutter 渲染

// ── 新式类（RegistryItem 子类）──────────────────────────────

// Cosmos / Sol / Tron / Alph 使用不同的构建/解析方式：
final tronUR = TronSignRequest.generateSignRequest(
  signData: '0xabcd...',
  path: "m/44'/195'/0'/0/0",
  xfp: '12345678',
);

final tronReq = TronSignRequest.fromCBOR(ur.payload);
```

## 类名对照表（重要！）

| 功能                 | 真实类名                                                                               |
| -------------------- | -------------------------------------------------------------------------------------- |
| ETH 签名请求         | `EthSignRequestUR`                                                                   |
| ETH 签名结果         | `EthSignatureUR`                                                                     |
| PSBT 签名请求        | `PsbtSignRequestUR`                                                                  |
| GSPL 签名请求        | `GsplSignRequestUR`                                                                  |
| GSPL 签名结果        | `GsplSignatureUR`                                                                    |
| HD 密钥              | `CryptoHDKeyUR`                                                                      |
| 多账户               | `CryptoMultiAccountsUR`                                                              |
| Cosmos/Sol/Tron/Alph | `CosmosSignRequest` / `SolSignRequest` / `TronSignRequest` / `AlphSignRequest` |

## 功能进度

| 模块                | Sprint | 状态 |
| ------------------- | ------ | ---- |
| 扫码识别 + 多帧进度 | 1      | ✅   |
| 解析结果 + 逐项复制 | 1      | ✅   |
| 动态表单 + 生成 QR  | 2      | 🚧   |
| 签名两步流程        | 3      | 📅   |
| 全 UR 类型覆盖      | 4      | 📅   |
