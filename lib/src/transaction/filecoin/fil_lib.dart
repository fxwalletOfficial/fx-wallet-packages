class FilTransaction {
  final String to;
  final String from;
  final String value;
  final int method;
  final String params;
  final int nonce;
  final int gasLimit;
  final String gasFeeCap;
  final String gasPremium;

  FilTransaction({
    required this.to,
    required this.from,
    required this.value,
    required this.method,
    required this.params,
    required this.nonce,
    required this.gasLimit,
    required this.gasFeeCap,
    required this.gasPremium,
  });

  Map<String, dynamic> toJson() {
    return {
      "To": to,
      "From": from,
      "Value": value,
      "Method": method,
      "Params": params,
      "Nonce": nonce,
      "GasLimit": gasLimit,
      "GasFeeCap": gasFeeCap,
      "GasPremium": gasPremium,
    };
  }

  factory FilTransaction.fromJson(Map<String, dynamic> json) {
    return FilTransaction(
      to: json['To'],
      from: json['From'],
      value: json['Value'],
      method: json['Method'],
      params: json['Params'],
      nonce: json['Nonce'],
      gasLimit: json['GasLimit'],
      gasFeeCap: json['GasFeeCap'],
      gasPremium: json['GasPremium'],
    );
  }
}
