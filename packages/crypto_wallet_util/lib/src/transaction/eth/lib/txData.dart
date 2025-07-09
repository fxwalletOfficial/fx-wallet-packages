class EthTxDataRaw {
  int nonce;
  int gasLimit;
  int maxPriorityFeePerGas;
  int maxFeePerGas;
  int gasPrice;
  String to;
  BigInt value;
  String data;
  int? v;
  BigInt? r;
  BigInt? s;

  EthTxDataRaw(
      {required this.nonce,
      required this.gasLimit,
      this.maxPriorityFeePerGas = 0,
      this.maxFeePerGas = 0,
      this.gasPrice = 0,
      this.to = '',
      required this.value,
      this.data = '',
      this.v,
      this.r,
      this.s});

  factory EthTxDataRaw.fromJson(Map<String, dynamic> json) {
    return EthTxDataRaw(
        nonce: json['nonce'],
        gasLimit: json['gasLimit'],
        maxPriorityFeePerGas: json['maxPriorityFeePerGas'],
        maxFeePerGas: json['maxFeePerGas'],
        gasPrice: json['gasPrice'],
        to: json['to'],
        value: BigInt.parse(json['value']),
        data: json['data']);
  }

  Map<String, dynamic> toJson() {
    return {
      'nonce': nonce,
      'gasLimit': gasLimit,
      'maxPriorityFeePerGas': maxPriorityFeePerGas,
      'maxFeePerGas': maxFeePerGas,
      'gasPrice': gasPrice,
      'to': to,
      'value': value.toString(),
      'data': data
    };
  }
}
