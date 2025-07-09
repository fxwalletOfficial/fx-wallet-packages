import 'dart:math';

import 'package:decimal/decimal.dart';

/// Handle number methods.
class NumberUtil {
  /// Handle the [value] to int.
  static int toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value.split('.')[0]);

    return 0;
  }

  /// Handle the [value] to double.
  static double toDouble(dynamic value, {int? decimal}) {
    if (value is BigInt) value = value.toString();
    if (value is double)
      return decimal == null ? value : value / pow(10, decimal);
    if (value is int)
      return decimal == null ? value.toDouble() : value / pow(10, decimal);
    if (value is String) value = value.replaceAll(',', '');
    if (value is String) {
      // Double only can handle 17 number.
      final safe = toSafeDoubleString(value);
      if (decimal == null) return double.parse(safe);
      final left = [];
      final right = [];
      for (var i = safe.length - 1; i >= 0; i--) {
        right.length < decimal ? right.add(safe[i]) : left.add(safe[i]);
      }

      if (right.length < decimal)
        right.addAll(List.filled(decimal - right.length, 0));

      final result = '0${left.reversed.join('')}.${right.reversed.join('')}';
      return double.parse(result);
    }

    return 0;
  }

  static String toSafeDoubleString(String value) {
    final parts = value.split('.');
    String left = parts[0];
    // double can't solve too big number. Or without right part, return directly.
    if (left.length > 16 || parts.length <= 1) return left;

    final space = 16 - left.length;
    final right = parts[1];
    left += '.';
    for (var i = 0; i < right.length; i++) {
      if (i > space - 1) break;
      left += right[i];
    }

    return left;
  }

  /// Fix double for specified digit. It returned double.
  static double toFixedDouble({required dynamic value, required int decimal}) {
    return double.parse(toDouble(value).toStringAsFixed(decimal));
  }

  static int numberPowToInt({required dynamic value, required int pow}) {
    if (value is int) {
      String str = value.toString();
      for (var i = 0; i < pow; i++) {
        str = '${str}0';
      }
      return int.parse(str);
    }

    if (value is Decimal) value = value.toDouble();
    if (value is String) value = double.parse(value);
    if (value is double) {
      String numString = value.toString();
      if (numString.contains('e')) numString = value.toStringAsFixed(pow);

      List numList = numString.split('.');
      String left = numList.first;
      String right = numList.last;
      String str = '';
      for (var i = 0; i < pow; i++) {
        if (i >= right.length) {
          str = '${str}0';
          continue;
        }

        str = str + right[i];
      }
      return int.parse(left + str);
    }
    return 0;
  }
}
