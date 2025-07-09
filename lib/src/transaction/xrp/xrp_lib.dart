class XrpAmountType {
  String? amount;
  String? currency;
  String? issuer;
  String? value;
  Map<String, dynamic> toJson() {
    return {};
  }
}

class XrpAmount extends XrpAmountType {
  @override
  final String amount;
  XrpAmount({required this.amount});
}

class XrpTokenAmount extends XrpAmountType {
  XrpTokenAmount(
      {required this.currency, required this.issuer, required this.value});
  @override
  final String currency;
  @override
  final String issuer;
  @override
  final String value;

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'currency': currency,
      'issuer': issuer,
      'value': value
    };
    return json;
  }
}

class XrpTransactionType {
  static const String payment = 'Payment';
  static const String trustSet = 'TrustSet';
}
