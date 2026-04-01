class RegistryType {
  final String _type;
  final int? _tag;

  String get type => _type;
  get tag => _tag;

  const RegistryType(this._type, this._tag);

  @override
  String toString() => "type: $type, tag: $tag";

  // =========================
  // BC-UR 标准类型
  // =========================
  static const RegistryType UUID = RegistryType('uuid', 37);
  static const RegistryType BYTES = RegistryType('bytes', null);
  static const RegistryType CRYPTO_HDKEY = RegistryType('crypto-hdkey', 40303);
  static const RegistryType CRYPTO_KEYPATH =
      RegistryType('crypto-keypath', 40304);
  static const RegistryType CRYPTO_COIN_INFO =
      RegistryType('crypto-coin-info', 40305);
  static const RegistryType CRYPTO_ECKEY = RegistryType('crypto-eckey', 40306);
  static const RegistryType CRYPTO_ADDRESS =
      RegistryType('crypto-address', 40307);
  static const RegistryType CRYPTO_OUTPUT =
      RegistryType('crypto-output', 40308);
  static const RegistryType CRYPTO_PSBT = RegistryType('crypto-psbt', 40310);
  static const RegistryType CRYPTO_ACCOUNT =
      RegistryType('crypto-account', 40311);
  static const RegistryType CRYPTO_MULTI_ACCOUNTS =
      RegistryType("crypto-multi-accounts", 1103);

  // =========================
  // GsWallet 基础扩展类型
  // =========================
  static const RegistryType GS_SIGNATURE = RegistryType("gs-signature", 6102);
  static const RegistryType CRYPTO_TXENTITY =
      RegistryType("crypto-txentity", 6112);

  // RegistryType 补充
  static const RegistryType ETH_SIGN_REQUEST =
      RegistryType('eth-sign-request', 401);
  static const RegistryType ETH_SIGNATURE = RegistryType('eth-signature', 402);

  static const RegistryType PSBT_SIGN_REQUEST =
      RegistryType('psbt-sign-request', 501);
  static const RegistryType PSBT_SIGNATURE =
      RegistryType('psbt-signature', 502);

  static const RegistryType BTC_SIGN_REQUEST =
      RegistryType('btc-sign-request', 601);
  static const RegistryType BTC_SIGNATURE = RegistryType('btc-signature', 602);

  static const RegistryType KEYSTONE_SIGN_REQUEST =
      RegistryType('keystone-sign-request', 6101);
  static const RegistryType KEYSTONE_SIGNATURE =
      RegistryType('keystone-sign-result', 6102);

  static const RegistryType BCH_SIGN_REQUEST =
      RegistryType('keystone-sign-request', 6101);
  static const RegistryType BCH_SIGNATURE =
      RegistryType('keystone-sign-result', 6102);

  static const RegistryType SOL_SIGN_REQUEST =
      RegistryType("sol-sign-request", 1101);
  static const RegistryType SOL_SIGNATURE = RegistryType("sol-signature", 1102);
  static const RegistryType SOL_NFT_ITEM = RegistryType("sol-nft-item", 1104);

  static const RegistryType COSMOS_SIGN_REQUEST =
      RegistryType("cosmos-sign-request", 1201);
  static const RegistryType COSMOS_SIGNATURE =
      RegistryType("cosmos-signature", 1202);

  static const RegistryType TRON_SIGN_REQUEST =
      RegistryType("tron-sign-request", 1301);
  static const RegistryType TRON_SIGNATURE =
      RegistryType("tron-signature", 1302);

  static const RegistryType ALPH_SIGN_REQUEST =
      RegistryType("alph-sign-request", 8110);
  static const RegistryType ALPH_SIGNATURE =
      RegistryType("alph-signature", 8111);
}
