import '../cosmos_dart.dart';

/// Contains the data of a specific coin amount.
extension CoinExt on CosmosCoin {
  bool get isPositive {
    if (amount.isEmpty == true) return false;
    return double.parse(amount) > 0;
  }

  bool get isValid {
    return validate() == null;
  }

  Exception? validate() {
    final regEx = RegExp(r'^[a-z][a-z0-9]{2,15}$');

    if (!regEx.hasMatch(denom)) {
      return Exception('invalid denom: $denom');
    }

    if (!isPositive) {
      return Exception('negative coin amount: $amount');
    }

    return null;
  }
}

/// Useful method on list of coins.
extension CoinsExt on List<CosmosCoin> {
  bool get isValid {
    return isNotEmpty && !any((element) => !element.isValid);
  }

  bool get isPositive {
    if (isEmpty) {
      return false;
    }

    return !any((element) => !element.isPositive);
  }
}
