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
        final req = CosmosSignRequest.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
            'requestId': hex.encode(req.getRequestId()),
            'signData': hex.encode(req.signData),
            'chain': req.chain,
            'derivationPath': req.derivationPath.getPath() ?? '—',
            'origin': req.origin ?? '—',
            'fee': req.fee?.toString() ?? '—',
          },
        };

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
        final req = SolSignRequest.fromCBOR(ur.payload);
        return {
          'type': ur.type,
          'fields': {
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

      // ── HD Key ─────────────────────────────────────────
      case 'crypto-hdkey':
        final key = CryptoHDKeyUR.fromUR(ur: ur);
        return {
          'type': ur.type,
          'fields': {
            'publicKey': hex.encode(key.wallet.publicKey),
            'chainCode': hex.encode(key.wallet.chainCode),
            'path': key.path,
            'name': key.name,
            'xfp': key.xfp ?? '—',
            'parentFingerprint': key.wallet.parentFingerprint.toRadixString(16),
          },
        };

      // ── Multi Accounts ─────────────────────────────────
      case 'crypto-multi-accounts':
        final accounts = CryptoMultiAccountsUR.fromUR(ur: ur);
        
        // Build detailed chain info for each CryptoAccountItemUR
        final chainDetails = accounts.chains.map((chain) {
          final wallet = chain.wallet;
          // wallet.fingerprint is Uint8List, need to convert to hex
          final xfp = wallet != null 
              ? hex.encode(wallet.fingerprint)
              : '';
          
          return {
            'derivationPath': chain.path,
            'chains': chain.chains.join(', '),
            'coin': chain.coin.isNotEmpty ? chain.coin : chain.chains.first,
            'publicKey': hex.encode(chain.publicKey),
            'chainCode': wallet != null ? hex.encode(wallet.chainCode) : '',
            'extendedPublicKey': wallet?.toBase58() ?? '',
            'masterFingerprint': xfp,
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
