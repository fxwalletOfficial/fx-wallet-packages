import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';

import 'package:aleo_dart/src/rust_lib/record_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';

class AleoRecord {
  late RecordRustFFI recordRustFFI;
  String _host = "http://23.20.9.85:3033";
  int decimal = 6;

  AleoRecord(dyLib) {
    this.recordRustFFI = RecordRustFFI(dyLib);
  }

  String encryptPrivateKey(privateKeyRaw, secretRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final secret = dartStrToC(secretRaw);
    final ciphertext = recordRustFFI.encryptPrivateKey(privateKey, secret);
    return ciphertext.toDartString();
  }

  String decryptToPrivateKey(ciphertextRaw, secretRaw) {
    final ciphertext = dartStrToC(ciphertextRaw);
    final secret = dartStrToC(secretRaw);
    final privateKey = recordRustFFI.decryptToPrivateKey(ciphertext, secret);
    return privateKey.toDartString();
  }

  RecordPlainText decryptCipherText(String record, String viewKey) {
    final result = recordRustFFI.decryptCipherText(
        dartStrToC(record), dartStrToC(viewKey));
    return processRecord(result.toDartString());
  }

  bool isOwner(String record, String viewKey) {
    return recordRustFFI.isOwner(dartStrToC(record), dartStrToC(viewKey));
  }

  String serialNumberString(String recordCipherTextRaw, String privateKeyRaw,
      String programIdRaw, String recordNameRaw) {
    final recordPlainText = dartStrToC(recordCipherTextRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    final programId = dartStrToC(programIdRaw);
    final recordName = dartStrToC(recordNameRaw);
    final result = recordRustFFI.serialNumberString(
        recordPlainText, privateKey, programId, recordName);
    return result.toDartString();
  }

  Future<String> getPrivateBalance(
      List<String> recordCipherTexts, String privateKey, String viewKey) async {
    final programId = "credits.aleo";
    final recordName = "credits";
    final dio = Dio();
    BigInt balance = BigInt.from(0);
    for (final recordCipherText in recordCipherTexts) {
      final transactionId = serialNumberString(
          recordCipherText, privateKey, programId, recordName);
      try {
        await dio.get(this._host + '/find/transitionID/' + transactionId);
      } catch (error) {
        final record = decryptCipherText(recordCipherText, viewKey);
        balance += BigInt.parse(record.getMicrocredits());
      }
    }
    return balance.toString();
  }

  RecordPlainText processRecord(String recordRaw) {
    final record = recordRaw
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
    return RecordPlainText(
        owner: map['owner'],
        microcredits: map['microcredits'],
        nonce: map['_nonce']);
  }
}

class RecordPlainText {
  String owner;
  String microcredits;
  String nonce;

  RecordPlainText(
      {required this.owner, required this.microcredits, required this.nonce});

  factory RecordPlainText.fromJson(Map<String, dynamic> json) =>
      RecordPlainText(
          owner: json['owner'],
          microcredits: json['microcredits'],
          nonce: json['_nonce']);

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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'owner': owner,
        'microcredits': microcredits,
        '_nonce': nonce
      };
}
