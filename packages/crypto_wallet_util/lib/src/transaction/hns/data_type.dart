import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Provides data types required in [FxHnsSign]
class UTXO {
  final Prevout prevout;
  final List<String> witness;
  final int sequence;
  final Coin coin;
  final Path path;
  final bool market;

  UTXO(
      {required this.prevout,
      required this.witness,
      required this.sequence,
      required this.coin,
      required this.path,
      required this.market});

  UTXO.fromJson(Map<String, dynamic> json)
      : prevout = Prevout.fromJson(json['prevout'] ?? {}),
        witness = ((json['witness'] ?? []) as List).cast<String>(),
        sequence = NumberUtil.toInt(json['sequence']),
        coin = Coin.fromJson(json['coin'] ?? {}),
        path = Path.fromJson(json['path'] ?? {}),
        market = json['market'] ?? false;
}

class Coin {
  final int version;
  final int? height;
  final int value;
  final String address;
  final Covenant covenant;
  final bool coinbase;
  final int? satoshis;

  Coin(
      {required this.version,
      this.height,
      required this.value,
      required this.address,
      required this.covenant,
      required this.coinbase,
      this.satoshis});

  Coin.fromJson(Map<String, dynamic> json)
      : version = NumberUtil.toInt(json['version']),
        height = NumberUtil.toInt(json['height']),
        value = NumberUtil.toInt(json['value']),
        address = json['address'] ?? '',
        covenant = Covenant.fromJson(json['covenant'] ?? {}),
        coinbase = json['coinbase'] ?? false,
        satoshis = NumberUtil.toInt(json['satoshis']);
}

class Prevout {
  final String hash;
  final int index;

  Prevout({required this.hash, required this.index});

  Prevout.fromJson(Map<String, dynamic> json)
      : hash = json['hash'] ?? '',
        index = NumberUtil.toInt(json['index']);
}

class Path {
  final int account;
  final bool change;
  final String derivation;
  final String publicKey;
  final String? script;

  Path(
      {required this.account,
      required this.change,
      required this.derivation,
      required this.publicKey,
      this.script});

  Path.fromJson(Map<String, dynamic> json)
      : account = NumberUtil.toInt(json['account']),
        change = json['change'] ?? false,
        derivation = json['derivation'] ?? '',
        publicKey = json['publicKey'] ?? '',
        script = json['script'] ?? '';
}

class Vout {
  final int value;
  final double amount;
  final String address;
  final Covenant covenant;
  final String encode;
  final String script;

  Vout.fromJson(Map<String, dynamic> json)
      : value = NumberUtil.toInt(json['value']),
        amount = NumberUtil.toDouble(json['amount']),
        address = json['address'] ?? '',
        covenant = Covenant.fromJson(json['covenant'] ?? {}),
        encode = json['encode'] ?? '',
        script = json['script'] ?? '';
}

class Covenant {
  final int type;
  final String action;
  final List<String> items;

  Covenant({required this.type, required this.action, required this.items});

  Covenant.fromJson(Map<String, dynamic> json)
      : type = NumberUtil.toInt(json['type']),
        action = json['action'] ?? 'NONE',
        items = ((json['items'] ?? []) as List).cast<String>();
}

class TrxMessageToSign {
  final bool visible;
  final String txID;
  final TrxRawData rawData;
  final String rawDataHex;
  final String initTokenAddress;
  final String transaction;
  final String blockHash;
  final String lastValidBlockHeight;
  final String stakeAccountPriv;
  final String stakeAccountPub;

  TrxMessageToSign.fromJson(Map<String, dynamic> json)
      : visible = json['visible'] ?? false,
        txID = json['txID'] ?? '',
        rawData = TrxRawData.fromJson(json['raw_data'] ?? {}),
        rawDataHex = json['raw_data_hex'] ?? '',
        initTokenAddress = json['initTokenAddress'] ?? '',
        transaction = json['transaction'] ?? '',
        blockHash = json['blockhash'] ?? '',
        lastValidBlockHeight = json['lastValidBlockHeight'] ?? '',
        stakeAccountPriv = json['stakeAccountPriv'] ?? '',
        stakeAccountPub = json['stakeAccountPub'] ?? '';
}

class TrxRawData {
  final List<TrxContract> contract;
  final String refBlockBytes;
  final String refBlockHash;
  final int expiration;
  final int timestamp;

  TrxRawData.fromJson(Map<String, dynamic> json)
      : contract = ((json['contract'] ?? []) as List)
            .map((e) => TrxContract.fromJson(e))
            .toList(),
        refBlockBytes = json['ref_block_bytes'] ?? '',
        refBlockHash = json['ref_block_hash'] ?? '',
        expiration = NumberUtil.toInt(json['expiration']),
        timestamp = NumberUtil.toInt(json['timestamp']);
}

class TrxContract {
  final TrxParameter parameter;
  final String type;

  TrxContract.fromJson(Map<String, dynamic> json)
      : parameter = TrxParameter.fromJson(json['parameter'] ?? {}),
        type = json['type'] ?? '';
}

class TrxParameter {
  final TrxValue value;
  final String typeUrl;

  TrxParameter.fromJson(Map<String, dynamic> json)
      : value = TrxValue.fromJson(json['value'] ?? {}),
        typeUrl = json['type_url'] ?? '';
}

class TrxValue {
  final int amount;
  final String ownerAddress;
  final String toAddress;

  TrxValue.fromJson(Map<String, dynamic> json)
      : amount = NumberUtil.toInt(json['amount']),
        ownerAddress = json['owner_address'] ?? '',
        toAddress = json['to_address'] ?? '';
}

