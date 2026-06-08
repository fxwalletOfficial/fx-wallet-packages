/// A transaction payload received from a DApp through the Web3 provider.
///
/// The model keeps a single source of truth in [_rawData] so that fields the
/// model does not strongly type (e.g. EIP-1559's `maxFeePerGas`, `nonce`,
/// `chainId`, `accessList`, …) are preserved end-to-end. The strongly typed
/// accessors (`gas`, `value`, `from`, `to`, `data`) are convenience wrappers
/// that always read / write back to [_rawData]:
///
///   * reading returns the underlying value only when it is a `String`,
///     otherwise it returns `null`;
///   * assigning a non-null value updates the raw map;
///   * assigning `null` deletes the key from the raw map, so downstream
///     wallets see the field cleared rather than the original DApp value.
class JsTransactionObject {
  final Map<String, dynamic> _rawData;

  JsTransactionObject({
    String? gas,
    String? value,
    String? from,
    String? to,
    String? data,
  }) : _rawData = <String, dynamic>{} {
    if (gas != null) _rawData['gas'] = gas;
    if (value != null) _rawData['value'] = value;
    if (from != null) _rawData['from'] = from;
    if (to != null) _rawData['to'] = to;
    if (data != null) _rawData['data'] = data;
  }

  JsTransactionObject.fromJson(Map<String, dynamic> json)
      : _rawData = Map<String, dynamic>.from(json);

  String? get gas => _stringField('gas');
  set gas(String? value) => _setField('gas', value);

  String? get value => _stringField('value');
  set value(String? v) => _setField('value', v);

  String? get from => _stringField('from');
  set from(String? value) => _setField('from', value);

  String? get to => _stringField('to');
  set to(String? value) => _setField('to', value);

  String? get data => _stringField('data');
  set data(String? value) => _setField('data', value);

  String? _stringField(String key) {
    final v = _rawData[key];
    return v is String ? v : null;
  }

  void _setField(String key, String? value) {
    if (value == null) {
      _rawData.remove(key);
    } else {
      _rawData[key] = value;
    }
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_rawData);
}
