class JsTransactionObject {
  String? gas;
  String? value;
  String? from;
  String? to;
  String? data;

  JsTransactionObject({this.gas, this.value, this.from, this.to, this.data});

  JsTransactionObject.fromJson(Map<String, dynamic> json) {
    gas = json['gas'];
    value = json['value'];
    from = json['from'];
    to = json['to'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gas'] = gas;
    data['value'] = value;
    data['from'] = from;
    data['to'] = to;
    data['data'] = data;
    return data;
  }
}
