// ignore_for_file: non_constant_identifier_names

class ExtendedRegistryType extends RegistryType {
  ExtendedRegistryType(super._type, super._tag);

  static RegistryType GS_SIGNATURE = RegistryType("gs-signature", 6102);

  static RegistryType SOL_SIGN_REQUEST = RegistryType("sol-sign-request", 1101);
  static RegistryType SOL_SIGNATURE = RegistryType("sol-signature", 1102);
  static RegistryType SOL_NFT_ITEM = RegistryType("sol-nft-item", 1104);

  static RegistryType COSMOS_SIGN_REQUEST = RegistryType("cosmos-sign-request", 1201);
  static RegistryType COSMOS_SIGNATURE = RegistryType("cosmos-signature", 1202);

  static RegistryType TRON_SIGN_REQUEST = RegistryType("tron-sign-request", 1301);
  static RegistryType TRON_SIGNATURE = RegistryType("tron-signature", 1302);
}

class RegistryType {
  final String _type;
  final int? _tag;

  get type => _type;
  get tag => _tag;
  RegistryType(this._type, this._tag);
  @override
  String toString() {
    return "type: $type, tag: $tag";
  }

  static RegistryType UUID = RegistryType('uuid', 37);
  static RegistryType BYTES = RegistryType('bytes', null);
  static RegistryType CRYPTO_HDKEY = RegistryType('crypto-hdkey', 40303);
  static RegistryType CRYPTO_KEYPATH = RegistryType('crypto-keypath', 40304);
  static RegistryType CRYPTO_COIN_INFO = RegistryType('crypto-coin-info', 40305);
  static RegistryType CRYPTO_ECKEY = RegistryType('crypto-eckey', 40306);
  static RegistryType CRYPTO_ADDRESS = RegistryType('crypto-address', 40307);
  static RegistryType CRYPTO_OUTPUT = RegistryType('crypto-output', 40308);
  static RegistryType CRYPTO_PSBT = RegistryType('crypto-psbt', 40310);
  static RegistryType CRYPTO_ACCOUNT = RegistryType('crypto-account', 40311);
}
