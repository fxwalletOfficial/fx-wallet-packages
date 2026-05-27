import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';

/// Parse scanned UR object to displayable Map
/// key: field name, value: string value
Map<String, dynamic> parseUR(UR ur) {
  try {
    final type = ur.type.toLowerCase();

    switch (type) {
      // ── ETH ────────────────────────────────────────────
      case 'eth-sign-request':
        final req = EthSignRequestUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(req.uuid),
            'signData': hex.encode(req.data),
            'dataType': req.dataType.name,
            'chainId': req.chainId.toString(),
            'address': hex.encode(req.address),
            'xfp': req.xfp,
            'origin': req.origin,
            'to': req.to.isEmpty ? '—' : req.to,
            'value': req.value == BigInt.zero ? '—' : req.value.toString(),
          },
        };

      case 'eth-signature':
        final sig = EthSignatureUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(sig.uuid),
            'signature': hex.encode(sig.signature),
            'r': sig.r.toRadixString(16),
            's': sig.s.toRadixString(16),
            'v': sig.v.toString(),
          },
        };

      // ── Cosmos ─────────────────────────────────────────
      case 'cosmos-sign-request':
        try {
          final req = KeystoneCosmosSignRequest.fromUR(ur);
          return {
            'type': ur.type,
            'fields': {
              'variant': 'Keystone',
              'requestId': hex.encode(req.getRequestId()),
              'signData': hex.encode(req.signData),
              'dataType': req.dataType.name,
              'derivationPaths': req.getDerivationPaths().join(', '),
              'addresses': req.addresses?.join(', ') ?? '—',
              'origin': req.origin ?? '—',
            },
          };
        } catch (_) {
          final req = CosmosSignRequest.fromCBOR(ur.payload);
          return {
            'type': ur.type,
            'fields': {
              'variant': 'GoldShell',
              'requestId': hex.encode(req.getRequestId()),
              'signData': hex.encode(req.signData),
              'chain': req.chain,
              'derivationPath': req.derivationPath.getPath() ?? '—',
              'origin': req.origin ?? '—',
              'fee': req.fee?.toString() ?? '—',
            },
          };
        }

      case 'cosmos-signature':
        final sig = CosmosSignature.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': sig.uuid != null ? hex.encode(sig.uuid!) : '—',
            'signature': hex.encode(sig.signature),
            'origin': sig.origin ?? '—',
          },
        };

      // ── Solana ─────────────────────────────────────────
      case 'sol-sign-request':
        try {
          final req = KeystoneSolSignRequest.fromUR(ur);
          return {
            'type': ur.type,
            'fields': {
              'variant': 'Keystone',
              'requestId': hex.encode(req.getRequestId()),
              'signData': hex.encode(req.signData),
              'signType': req.signType.name,
              'derivationPath': req.derivationPath.getPath() ?? '—',
              'address': req.addressBytes == null ? '—' : utf8.decode(req.addressBytes!),
              'origin': req.origin ?? '—',
            },
          };
        } catch (_) {
          final req = SolSignRequest.fromCBOR(ur.payload);
          return {
            'type': ur.type,
            'fields': {
              'variant': 'GoldShell',
              'requestId': hex.encode(req.getRequestId()),
              'signData': hex.encode(req.signData),
              'signType': req.signType.name,
              'derivationPath': req.derivationPath.getPath() ?? '—',
              'outputAddress': req.outputAddress ?? '—',
              'contractAddress': req.contractAddress ?? '—',
              'origin': req.origin ?? '—',
              'fee': req.fee?.toString() ?? '—',
            },
          };
        }

      case 'sol-signature':
        final sig = SolSignature.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': sig.uuid != null ? hex.encode(sig.uuid!) : '—',
            'signature': hex.encode(sig.signature),
            'origin': sig.origin ?? '—',
          },
        };

      // ── Tron ───────────────────────────────────────────
      case 'tron-sign-request':
        final req = TronSignRequest.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(req.getRequestId()),
            'signData': hex.encode(req.signData),
            'derivationPath': req.getDerivationPath() ?? '—',
            'xfp': req.getSourceFingerprint() != null ? hex.encode(req.getSourceFingerprint()!) : '—',
            'origin': req.origin ?? '—',
            'fee': req.fee?.toString() ?? '—',
          },
        };

      case 'tron-signature':
        final sig = TronSignature.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': sig.uuid != null ? hex.encode(sig.uuid!) : '—',
            'signature': hex.encode(sig.signature),
            'origin': sig.origin ?? '—',
          },
        };

      // ── Alph ────────────────────────────────────
      case 'alph-sign-request':
        final req = AlphSignRequest.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(req.getRequestId()),
            'signData': hex.encode(req.signData),
            'dataType': req.dataType.name,
            'derivationPath': req.getDerivationPath() ?? '—',
            'xfp': req.getSourceFingerprint() != null ? hex.encode(req.getSourceFingerprint()!) : '—',
            'outputsCount': (req.outputs?.length ?? 0).toString(),
            'origin': req.origin ?? '—',
          },
        };

      case 'alph-signature':
        final sig = AlphSignature.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': sig.uuid != null ? hex.encode(sig.uuid!) : '—',
            'signature': hex.encode(sig.signature),
            'origin': sig.origin ?? '—',
          },
        };

      // ── PSBT (Bitcoin) ─────────────────────────────────
      case 'psbt-sign-request':
        final req = PsbtSignRequestUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(req.uuid),
            'psbt': req.psbt,
            'path': req.path,
            'xfp': req.xfp,
            'dataType': req.dataType.name,
          },
        };

      case 'psbt-signature':
        final sig = PsbtSignatureUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(sig.uuid),
            'signature': hex.encode(sig.signature),
          },
        };

      case 'crypto-psbt':
        final sig = BtcSignature.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'signature': hex.encode(sig.signature),
            'bytesLength': sig.signature.length.toString(),
          },
        };

      // ── GSPL (Bitcoin variant) ─────────────────────────
      case 'btc-sign-request':
        final req = GsplSignRequestUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(req.uuid),
            'path': req.path,
            'xfp': req.xfp,
            'dataType': req.gsplTxData.dataType.name,
            'hex': req.gsplTxData.hex,
          },
        };

      case 'btc-signature':
        final sig = GsplSignatureUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(sig.uuid),
            'signedHex': sig.gspl.hex,
            'dataType': sig.gspl.dataType.name,
          },
        };

      case 'keystone-sign-request':
        return _parseKeystoneSignRequest(ur);

      case 'keystone-sign-result':
        return _parseKeystoneSignResult(ur);

      case 'bytes':
        return _parseBytes(ur);

      // ── HD Key ─────────────────────────────────────────
      case 'crypto-hdkey':
        final key = CryptoHDKeyUR.fromUR(ur: ur);
        final publicKey = key.wallet?.publicKey ?? key.publicKey;
        final chainCode = key.wallet?.chainCode ?? key.chainCode;
        return {
          'type': ur.type,
          'fields': {
            'publicKey': publicKey == null ? '—' : hex.encode(publicKey),
            'chainCode': chainCode == null ? '—' : hex.encode(chainCode),
            'path': key.path,
            'name': key.name,
            'xfp': key.xfp ?? key.sourceFingerprint ?? '—',
            'parentFingerprint': key.wallet?.parentFingerprint.toRadixString(16) ?? '—',
          },
        };

      // ── Crypto Account ────────────────────────────────────
      case 'crypto-account':
        final account = CryptoAccountUR.fromUR(ur: ur);
        final outputDetails = account.outputs.map((output) {
          final wallet = output.wallet;
          final publicKey = wallet?.publicKey ?? output.publicKey;
          final chainCode = wallet?.chainCode ?? output.chainCode;

          return {
            'derivationPath': output.path,
            'name': output.name,
            'publicKey': publicKey == null ? '' : hex.encode(publicKey),
            'chainCode': chainCode == null ? '' : hex.encode(chainCode),
            'extendedPublicKey': wallet?.toBase58() ?? '',
            'sourceFingerprint': output.sourceFingerprint ?? '',
            'xfpFormat': output.xfpFormat ?? '',
          };
        }).toList();

        return {
          'type': ur.type,
          'fields': {
            'masterFingerprint': account.masterFingerprint,
            'xfpFormat': account.xfpFormat ?? '—',
            'outputsCount': account.outputs.length.toString(),
          },
          'chainDetails': outputDetails,
        };

      // ── Multi Accounts ─────────────────────────────────
      case 'crypto-multi-accounts':
        final accounts = CryptoMultiAccountsUR.fromUR(ur: ur);

        // Build detailed key info for each CryptoHDKeyUR.
        final chainDetails = accounts.chains.map((chain) {
          final wallet = chain.wallet;
          final publicKey = wallet?.publicKey ?? chain.publicKey;
          final chainCode = wallet?.chainCode ?? chain.chainCode;

          return {
            'derivationPath': chain.path,
            'name': chain.name,
            'publicKey': publicKey == null ? '' : hex.encode(publicKey),
            'chainCode': chainCode == null ? '' : hex.encode(chainCode),
            'extendedPublicKey': wallet?.toBase58() ?? '',
            'sourceFingerprint': chain.sourceFingerprint ?? '',
          };
        }).toList();

        return {
          'type': ur.type,
          'fields': {
            'masterFingerprint': accounts.masterFingerprint,
            'device': accounts.device,
            'walletName': accounts.walletName,
            'chainsCount': accounts.chains.length.toString(),
          },
          'chainDetails': chainDetails,
        };

      // ── Unknown Type ───────────────────────────────────────
      default:
        return {
          'type': ur.type,
          'fields': {
            'payload_hex': hex.encode(ur.payload),
            'note': 'Unknown UR type, showing raw payload',
          },
        };
    }
  } catch (e, stack) {
    return {
      'type': ur.type.isEmpty ? 'unknown' : ur.type,
      'fields': {
        'error': e.toString(),
        'stackTrace': stack.toString().split('\n').take(5).join('\n'),
        'hint': 'Check if UR data is complete or if fromCBOR() parameter matches this type',
      },
      'isError': true,
    };
  }
}

Map<String, dynamic> _parseKeystoneSignRequest(UR ur) {
  try {
    final req = KeystoneTronSignRequest.fromUR(ur);
    return {
      'type': ur.type,
      'fields': {
        'variant': 'Keystone Tron',
        'requestId': req.requestId,
        'path': req.path,
        'xfp': req.xfp,
        'from': req.tronTx.from,
        'to': req.tronTx.to,
        'value': req.tronTx.value,
        'token': req.tronTx.token.isEmpty ? '—' : req.tronTx.token,
        'contractAddress': req.tronTx.contractAddress.isEmpty ? '—' : req.tronTx.contractAddress,
        'fee': req.tronTx.fee.toString(),
        'origin': req.origin ?? '—',
      },
    };
  } catch (_) {
    final req = BchSignRequestUR.fromUR(ur: ur);
    return {
      'type': ur.type,
      'fields': {
        'variant': 'BCH',
        'requestId': req.requestId,
        'xfp': req.xfp,
        'hdPath': req.hdPath,
        'origin': req.origin ?? '—',
      },
    };
  }
}

Map<String, dynamic> _parseKeystoneSignResult(UR ur) {
  try {
    final result = KeystoneTronSignResult.fromUR(ur);
    return {
      'type': ur.type,
      'fields': {
        'variant': 'Keystone Tron',
        'requestId': result.requestId,
        'txId': result.txId,
        'rawTx': result.rawTx,
      },
    };
  } catch (_) {
    try {
      final sig = BchSignatureUR.fromUR(ur: ur);
      return {
        'type': ur.type,
        'fields': {
          'variant': 'BCH',
          'requestId': sig.requestId,
          'txId': sig.txId,
          'rawTx': sig.rawTx,
        },
      };
    } catch (_) {
      final data = ur.decodeCBOR() as CborMap;
      final bytes = Uint8List.fromList((data[CborSmallInt(1)] as CborBytes).bytes);
      final payload = _readMessageField(Uint8List.fromList(GZipCodec().decode(bytes)), 7);
      final result = _readStringFields(payload, {1, 2, 3});
      return {
        'type': ur.type,
        'fields': {
          'variant': 'BCH',
          'requestId': result[1] ?? '',
          'txId': result[2] ?? '',
          'rawTx': result[3] ?? '',
        },
      };
    }
  }
}

Map<String, dynamic> _parseBytes(UR ur) {
  try {
    final account = KeystoneXrpAccountBytes.fromUR(ur);
    return {
      'type': ur.type,
      'fields': {
        'variant': 'XRP Account',
        'address': account.address,
        'publicKey': account.publicKey,
        'payload': const JsonEncoder.withIndent('  ').convert(account.payload),
      },
    };
  } catch (_) {}

  try {
    final signature = KeystoneXrpSignatureBytes.fromUR(ur);
    return {
      'type': ur.type,
      'fields': {
        'variant': 'XRP Signature',
        'signature': signature.signature.isEmpty ? '—' : signature.signature,
        'publicKey': signature.publicKey.isEmpty ? '—' : signature.publicKey,
        'signedBlob': signature.signedBlob.isEmpty ? '—' : signature.signedBlob,
        'txHash': signature.txHash.isEmpty ? '—' : signature.txHash,
        'payload': signature.payload == null ? '—' : const JsonEncoder.withIndent('  ').convert(signature.payload),
      },
    };
  } catch (_) {}

  try {
    final request = KeystoneXrpSignRequestBytes.fromUR(ur);
    return {
      'type': ur.type,
      'fields': {
        'variant': 'XRP Sign Request',
        'transaction': const JsonEncoder.withIndent('  ').convert(request.transaction),
        'payloadBytes': hex.encode(request.payloadBytes),
      },
    };
  } catch (_) {
    return {
      'type': ur.type,
      'fields': {
        'payload_hex': hex.encode(ur.payload),
        'note': 'Unknown bytes payload, showing raw payload',
      },
    };
  }
}

Uint8List _readMessageField(Uint8List message, int targetField) {
  final reader = _ProtoReader(message);
  while (reader.hasMore()) {
    final tag = reader.readVarint();
    final fieldNumber = tag >> 3;
    final wireType = tag & 0x7;
    if (fieldNumber == targetField && wireType == 2) {
      return reader.readLengthDelimited();
    }
    reader.skipField(wireType);
  }
  return Uint8List(0);
}

Map<int, String> _readStringFields(Uint8List message, Set<int> fields) {
  final values = <int, String>{};
  final reader = _ProtoReader(message);
  while (reader.hasMore()) {
    final tag = reader.readVarint();
    final fieldNumber = tag >> 3;
    final wireType = tag & 0x7;
    if (fields.contains(fieldNumber) && wireType == 2) {
      values[fieldNumber] = utf8.decode(reader.readLengthDelimited());
    } else {
      reader.skipField(wireType);
    }
  }
  return values;
}

class _ProtoReader {
  final Uint8List _data;
  int _offset = 0;

  _ProtoReader(this._data);

  bool hasMore() => _offset < _data.length;

  int readVarint() {
    var result = 0;
    var shift = 0;
    while (_offset < _data.length) {
      final value = _data[_offset++];
      result |= (value & 0x7f) << shift;
      if ((value & 0x80) == 0) return result;
      shift += 7;
    }
    return result;
  }

  Uint8List readLengthDelimited() {
    final length = readVarint();
    final end = (_offset + length).clamp(0, _data.length);
    final bytes = _data.sublist(_offset, end);
    _offset = end;
    return Uint8List.fromList(bytes);
  }

  void skipField(int wireType) {
    switch (wireType) {
      case 0:
        readVarint();
        return;
      case 1:
        _offset = (_offset + 8).clamp(0, _data.length);
        return;
      case 2:
        _offset = (_offset + readVarint()).clamp(0, _data.length);
        return;
      case 5:
        _offset = (_offset + 4).clamp(0, _data.length);
        return;
      default:
        _offset = _data.length;
    }
  }
}

/// Calculate multi-frame UR scan progress (0.0 ~ 1.0)
/// UR class doesn't expose progress directly, use received frames / total frames
double calcProgress(UR ur) {
  final total = ur.seq.length;
  if (total <= 0) {
    // Single-frame UR: isComplete = 100%
    return ur.isComplete ? 1.0 : 0.0;
  }
  final received = ur.receivedPartIndexes.length;
  return (received / total).clamp(0.0, 1.0);
}
