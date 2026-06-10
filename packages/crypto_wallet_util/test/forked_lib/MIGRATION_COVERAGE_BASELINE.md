# blockchain_utils 1.6.0 → 6.0.0 升级：覆盖率与风险基线

> 阶段 0.5「覆盖审计闸门」产出物。重构前固化，重构后用于对照。
> 数据采集于 blockchain_utils **1.6.0**（升级前），分支 `feature/upgrade-blockchain-utils-v6`。

## 1. 影响面

`blockchain_utils` 仅被两个 vendored fork 使用，项目自有代码 **0** 处直接依赖：

| fork | 文件数 | 用途 |
|------|------:|------|
| `lib/src/forked_lib/bitcoin_base_hd` | 19（引用 blockchain_utils 的） | BTC/LTC/BCH 钱包 **仅用 `ECPrivate`** |
| `lib/src/forked_lib/xrpl_dart` | 16（引用 blockchain_utils 的） | XRP |

把约束改成 `^6.0.0` 后 `dart analyze` 报 **211 error，全部在这两个 fork 内**，自有代码 0。

## 2. 升级前覆盖率（含被排除的 fork）

> 注意：仓库现有 `generate_coverage.sh` 用 `--ignore-files` 把这两个 fork **排除**在覆盖率外，
> 即对本次要改的代码原本零可见性。下表是去掉该排除后的真实数据。

| 范围 | 升级前 | 闸门后 |
|------|------:|------:|
| `bitcoin_base_hd` 整体 | 1.6% (26/1588) | 1.6%（见 §4，多为运行时死代码） |
| `xrpl_dart` 整体 | 16.7% (521/3111) | **19.3% (600/3111)** |
| `xrpl_private_key.dart`（含 orderLen） | 26.3% | **88.9%** |
| `xrpl/address/xrpl.dart`（X-address） | 27.3% | **77.3%** |
| 测试总数 | 771 | **779** |

## 3. 「编译可达」≠「运行时执行」

入口 `ec_private.dart` 顺着 barrel 把整个 `bitcoin_base_hd` import 进来，所以**全部文件都必须能编译过 6.x**（211 个报错都要修，不能简单删）。
但**运行时真正被测试执行**的只有一小撮：

- BTC/LTC/BCH：只用 `ECPrivate`（`signInput` / `signTapRoot` / `signMessage` 均已被 btc + taproot 测试命中）。
- XRP：`fromHex` + secp256k1 签名（xrp_test 用 golden `signedBlob` 锁定 payment / token / trust_set 三类）、公钥→地址、ed25519 派生。

其余（tx-builder、script、address 类、provider/RPC、binary_parser 解码、xchain、fulfillment）**运行时 0% 执行**——这是 1.6% 的根因，不是测试缺失，而是 crypto_wallet_util 根本不调用。

## 4. 待改文件风险分层

| 层级 | 处理策略 | 文件 |
|------|----------|------|
| 🟢 运行时死代码（仅需编译过 6.x） | 机械修复，无需补测 | bitcoin_base_hd 的 tx-builder/script/address/provider；xrpl 的 binary_parser(解码)/xchain_bridge/ans1_raw_encoder/rpc provider |
| 🟡 活码·已被现有测试覆盖 | 现有 golden 兜底，可安全改 | xrpl_public_key、currency、binary_serializer(序列化)、st_object(序列化)、ec_private/ec_public sign、地址 encodeKey |
| 🔴 活码/半活·低覆盖·有语义改动 | **已在本闸门补特征测试** | xrpl_private_key（orderLen）、X-address 转换 |

## 5. 本闸门新增的特征测试（pin 升级前行为）

1. `test/forked_lib/xrpl_dart/keypair/xrpl_seed_characterization_test.dart`
   - secp256k1 家族种子派生（`deriveKeyPair` → **`orderLen` line 63，升级前命中=0**）。
   - 用 XRPL 官方主种子向量 `snoPBrXtMeMyMHUVTgbuqAfg1SUTb → rHb9CJAWyB4rj91VRWn96DkukG4bwdtyTh` 交叉验证。
   - 覆盖 ed25519 派生（`sha512HashHalves().item1` → 6.x record）、secp256k1 签名往返。
2. `test/forked_lib/xrpl_dart/address/xaddress_characterization_test.dart`
   - classic ↔ X-address（`decodeXAddress` 的 `.item1/.item2` Tuple→record；`encodeKey` 签名变化）。
   - 用官方向量 `rHb9… ↔ XVPcpSm47b1CZkf5AkKM9a84dQHe3m4sBhsrA4XtnBECTAc` 交叉验证。

> 这些路径**运行时未被 XrpCoin 调用**，但升级会改动它们，故以特征测试 pin 住，确保字节不变。

## 6. 死代码处理建议（任务 #22）

`ec_private.dart` 实际只从 barrel 用到 `ECPublic / BitcoinSigner / Script / BitcoinNetwork / BitcoinOpCodeConst`，
**不**用 tx-builder / provider。理论上可切断 barrel→删死代码，但 `Script` 的传递依赖需要谨慎解耦。

**建议**：本升级 PR **不**删死代码，只「修到能编译」（原子、可回退、聚焦）。
死代码移除作为**独立后续 PR**（纯重构，可单独验证；且 1.6% 覆盖下本就该先补特征测试）。

## 7. 复现命令

```bash
cd packages/crypto_wallet_util
dart run wasm_run:setup           # 否则 SC(Sia) 用例假失败
dart test --coverage=coverage
dart pub global run coverage:format_coverage \
  --lcov --in=coverage --out=coverage/lcov_full.info \
  --report-on=lib --packages=.dart_tool/package_config.json
# 注意：不要沿用 generate_coverage.sh 的 --ignore-files，否则看不到这两个 fork
```
