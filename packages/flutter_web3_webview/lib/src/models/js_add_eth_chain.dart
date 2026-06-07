class JsAddEthereumChain {
  String? chainId;
  Map<String, dynamic>? data;

  JsAddEthereumChain({this.chainId, this.data});

  JsAddEthereumChain.fromJson(Map<String, dynamic> json) {
    chainId = json['chainId'] is String ? json['chainId'] as String : null;
    data = Map<String, dynamic>.from(json);
  }

  Map<String, dynamic> toJson() {
    final item = Map<String, dynamic>.from(data ?? {});
    item['chainId'] = chainId;
    return item;
  }
}
