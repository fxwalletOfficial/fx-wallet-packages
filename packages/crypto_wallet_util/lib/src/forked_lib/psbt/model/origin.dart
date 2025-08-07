import 'package:crypto_wallet_util/src/utils/number.dart';

class Origin {
  final String status;
  final int code;
  final double fee;
  final int rate;
  final int mtime;
  final int version;
  final List<OriginInput> inputs;
  final List<OriginOutput> outputs;
  final int locktime;
  final String hex;

  Origin({
    required this.status,
    required this.code,
    required this.fee,
    required this.rate,
    required this.mtime,
    required this.version,
    required this.inputs,
    required this.outputs,
    required this.locktime,
    required this.hex,
  });

  factory Origin.fromJson(Map<String, dynamic> json) {
    return Origin(
      status: json['status'],
      code: json['code'],
      fee: NumberUtil.toDouble(json['fee']),
      rate: json['rate'],
      mtime: json['mtime'],
      version: json['version'],
      inputs: (json['inputs'] as List)
          .map((input) => OriginInput.fromJson(input))
          .toList(),
      outputs: (json['outputs'] as List)
          .map((output) => OriginOutput.fromJson(output))
          .toList(),
      locktime: json['locktime'],
      hex: json['hex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'code': code,
      'fee': fee,
      'rate': rate,
      'mtime': mtime,
      'version': version,
      'inputs': inputs.map((input) => input.toJson()).toList(),
      'outputs': outputs.map((output) => output.toJson()).toList(),
      'locktime': locktime,
      'hex': hex,
    };
  }
}

class OriginInput {
  final Prevout prevout;
  final int sequence;
  final Coin coin;
  final Path path;

  OriginInput({
    required this.prevout,
    required this.sequence,
    required this.coin,
    required this.path,
  });

  factory OriginInput.fromJson(Map<String, dynamic> json) {
    return OriginInput(
      prevout: Prevout.fromJson(json['prevout']),
      sequence: json['sequence'],
      coin: Coin.fromJson(json['coin']),
      path: Path.fromJson(json['path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prevout': prevout.toJson(),
      'sequence': sequence,
      'coin': coin.toJson(),
      'path': path.toJson(),
    };
  }
}

class Prevout {
  final String hash;
  final int index;

  Prevout({
    required this.hash,
    required this.index,
  });

  factory Prevout.fromJson(Map<String, dynamic> json) {
    return Prevout(
      hash: json['hash'],
      index: json['index'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'index': index,
    };
  }
}

class Coin {
  final int version;
  final int height;
  final double value;
  final String address;
  final bool coinbase;

  Coin({
    required this.version,
    required this.height,
    required this.value,
    required this.address,
    required this.coinbase,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    return Coin(
      version: json['version'],
      height: json['height'],
      value: NumberUtil.toDouble(json['value']),
      address: json['address'],
      coinbase: json['coinbase'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'height': height,
      'value': value,
      'address': address,
      'coinbase': coinbase,
    };
  }
}

class Path {
  final String? account;
  final bool change;

  var derivation;

  Path({
    required this.account,
    required this.change,
  });

  factory Path.fromJson(Map<String, dynamic> json) {
    return Path(
      account: json['account'],
      change: json['change'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'change': change,
    };
  }
}

class OriginOutput {
  final String address;
  final double? amount;

  final String? path;

  final String? value;

  OriginOutput(
      {required this.address,
      required this.amount,
      required this.path,
      required this.value});

  factory OriginOutput.fromJson(Map<String, dynamic> json) {
    return OriginOutput(
        address: json['address'],
        amount: json['amount'] != null ? NumberUtil.toDouble(json['amount']) : null,
        path: json['path'],
        value: json['value']);
  }

  Map<String, dynamic> toJson() {
    return {'address': address, 'amount': amount, 'path': path, 'value': value};
  }
}
