import 'dart:math';

import 'package:ffi/ffi.dart';

import 'package:aleo_dart/src/rust_lib/record_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:aleo_dart/src/aleo_utils.dart';

class AleoRecord {
  late RecordRustFFI recordRustFFI;
  int decimal = 6;

  AleoRecord(dyLib, [String network_raw = 'testnet']) {
    this.recordRustFFI = RecordRustFFI(dyLib, network_raw);
  }

  String encryptPrivateKey(privateKeyRaw, secretRaw) {
    AleoUtils.checkPrivateKey(privateKeyRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    final secret = dartStrToC(secretRaw);
    final result = recordRustFFI.encryptPrivateKey(privateKey, secret);
    final ciphertext = takeNativeString(recordRustFFI.dyLib, result);
    malloc.free(privateKey);
    malloc.free(secret);
    return ciphertext;
  }

  String decryptToPrivateKey(ciphertextRaw, secretRaw) {
    final ciphertext = dartStrToC(ciphertextRaw);
    final secret = dartStrToC(secretRaw);
    final result = recordRustFFI.decryptToPrivateKey(ciphertext, secret);
    final privateKey = takeNativeString(recordRustFFI.dyLib, result);
    malloc.free(ciphertext);
    malloc.free(secret);
    return privateKey;
  }

  RecordPlainText decryptCipherText(String record, String viewKey) {
    return processRecord(decryptCipherTextRaw(record, viewKey));
  }

  String decryptCipherTextRaw(String record, String viewKey) {
    AleoUtils.checkRecord(record);
    AleoUtils.checkViewKey(viewKey);
    final flag = isOwner(record, viewKey);
    if (!flag) {
      throw Exception('Record is not owned by the view key');
    }
    final recordPtr = dartStrToC(record);
    final viewKeyPtr = dartStrToC(viewKey);
    final result = recordRustFFI.decryptCipherText(recordPtr, viewKeyPtr);
    final plaintext = takeNativeString(recordRustFFI.dyLib, result);
    malloc.free(recordPtr);
    malloc.free(viewKeyPtr);
    return plaintext;
  }

  bool isOwner(String record, String viewKey) {
    AleoUtils.checkRecord(record);
    AleoUtils.checkViewKey(viewKey);
    final recordPtr = dartStrToC(record);
    final viewKeyPtr = dartStrToC(viewKey);
    final owned = recordRustFFI.isOwner(recordPtr, viewKeyPtr);
    malloc.free(recordPtr);
    malloc.free(viewKeyPtr);
    return owned;
  }

  /// 解密 sender_ciphertext 字段，获取发送方地址
  /// 这是 Aleo snarkOS v4.0.0 中的新功能，允许接收方解密发送方地址
  ///
  /// [record] - 加密的 record 字符串
  /// [viewKey] - 接收方的 view key
  /// [senderCiphertext] - sender_ciphertext 字段值
  ///
  /// 返回解密后的发送方地址信息，如果解密失败则抛出异常
  String decryptSenderCiphertext(
      String record, String viewKey, String senderCiphertext) {
    AleoUtils.checkRecord(record);
    AleoUtils.checkViewKey(viewKey);

    // 首先检查 record 是否属于该 view key
    final isOwned = isOwner(record, viewKey);
    if (!isOwned) {
      throw Exception('Record is not owned by the provided view key');
    }

    // 调用 Rust FFI 解密 sender_ciphertext
    final recordPtr = dartStrToC(record);
    final viewKeyPtr = dartStrToC(viewKey);
    final senderCiphertextPtr = dartStrToC(senderCiphertext);
    final result = recordRustFFI.decryptSenderCiphertext(
        recordPtr, viewKeyPtr, senderCiphertextPtr);
    final senderInfo = takeNativeString(recordRustFFI.dyLib, result);
    malloc.free(recordPtr);
    malloc.free(viewKeyPtr);
    malloc.free(senderCiphertextPtr);
    return senderInfo;
  }

  String serialNumberString(String recordCipherTextRaw, String privateKeyRaw,
      {String programIdRaw = 'credits.aleo',
      String recordNameRaw = 'credits'}) {
    AleoUtils.checkRecord(recordCipherTextRaw);
    AleoUtils.checkPrivateKey(privateKeyRaw);
    final recordPlainText = dartStrToC(recordCipherTextRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    final programId = dartStrToC(programIdRaw);
    final recordName = dartStrToC(recordNameRaw);
    final result = recordRustFFI.serialNumberString(
        recordPlainText, privateKey, programId, recordName);
    final serialNumber = takeNativeString(recordRustFFI.dyLib, result);
    malloc.free(recordPlainText);
    malloc.free(privateKey);
    malloc.free(programId);
    malloc.free(recordName);
    return serialNumber;
  }

  List<String> serialNumberStrings(
      List<String> recordCipherTexts, String privateKey, String viewKey) {
    final List<String> list = [];
    AleoUtils.checkViewKey(viewKey);
    AleoUtils.checkPrivateKey(privateKey);
    for (final recordCipherText in recordCipherTexts) {
      AleoUtils.checkRecord(recordCipherText);
      final result = isOwner(recordCipherText, viewKey);
      if (result) {
        final numberString = serialNumberString(recordCipherText, privateKey);
        list.add(numberString);
      }
    }
    return list;
  }

  String findRecord(List<String> recordCipherTexts, String targetNumberString,
      String privateKey, String viewKey) {
    AleoUtils.checkViewKey(viewKey);
    AleoUtils.checkPrivateKey(privateKey);
    for (final recordCipherText in recordCipherTexts) {
      final result = isOwner(recordCipherText, viewKey);
      if (result) {
        final numberString = serialNumberString(recordCipherText, privateKey);
        if (numberString == targetNumberString) {
          return recordCipherText;
        }
      }
    }
    return '';
  }

  Future<double> getPrivateBalance(
      List<String> recordCipherTexts, String viewKey) async {
    BigInt balance = BigInt.from(0);
    for (final recordCipherText in recordCipherTexts) {
      final record = decryptCipherText(recordCipherText, viewKey);
      balance += BigInt.parse(record.getMicrocredits());
    }
    return balance.toDouble() / pow(10, 6);
  }

  RecordPlainText processRecord(String recordRaw) {
    final map = stringToMap(recordRaw);
    return RecordPlainText(
        owner: map['owner'],
        microcredits: map['microcredits'],
        nonce: map['_nonce'],
        version: map['_version']);
  }
}

Map<String, dynamic> stringToMap(String string) {
  final record = string
      .replaceAll('\n', '')
      .replaceAll(' ', '')
      .replaceAll('{', '')
      .replaceAll('}', '');
  final fields = record.split(',');
  Map<String, dynamic> map = {};
  for (final field in fields) {
    final key = field.split(':');
    map[key[0]] = key[1];
  }
  return map;
}

class RecordPlainText {
  String owner;
  String microcredits;
  String nonce;
  String version;

  RecordPlainText(
      {required this.owner,
      required this.microcredits,
      required this.nonce,
      required this.version});

  factory RecordPlainText.fromJson(Map<String, dynamic> json) =>
      RecordPlainText(
          owner: json['owner'],
          microcredits: json['microcredits'],
          nonce: json['_nonce'],
          version: json['_version']);

  String getMicrocredits() {
    final credits = this.microcredits.split('.');
    return credits[0].split('u')[0];
  }

  String getOwner() {
    return this.owner.split('.')[0];
  }

  String getNonce() {
    return this.nonce.split('.')[0];
  }

  String getVersion() {
    return this.version.split('.')[0];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'owner': owner,
        'microcredits': microcredits,
        '_nonce': nonce,
        '_version': version
      };
}
