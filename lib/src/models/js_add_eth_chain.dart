class JsAddEthereumChain {
  String? chainId;
  Map<String, dynamic>? data;

  JsAddEthereumChain({this.chainId, this.data});

  JsAddEthereumChain.fromJson(Map<String, dynamic> json) {
    chainId = json['chainId'];
    data = json;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> item = <String, dynamic>{};
    item['chainId'] = chainId;
    item['data'] = data;
    return item;
  }
}
