class JsTransactionObject {
  String? gas;
  String? value;
  String? from;
  String? to;
  String? data;
  Map<String, dynamic> _rawData = {};

  JsTransactionObject({this.gas, this.value, this.from, this.to, this.data});

  JsTransactionObject.fromJson(Map<String, dynamic> json) {
    _rawData = Map<String, dynamic>.from(json);
    gas = json['gas'] is String ? json['gas'] as String : null;
    value = json['value'] is String ? json['value'] as String : null;
    from = json['from'] is String ? json['from'] as String : null;
    to = json['to'] is String ? json['to'] as String : null;
    data = json['data'] is String ? json['data'] as String : null;
  }

  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(_rawData)
      ..['gas'] = gas
      ..['value'] = value
      ..['from'] = from
      ..['to'] = to
      ..['data'] = data;
  }
}
