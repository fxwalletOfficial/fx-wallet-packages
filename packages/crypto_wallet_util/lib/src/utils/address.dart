import 'package:crypto/crypto.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bitcoin;
import 'package:crypto_wallet_util/crypto_utils.dart';

/// Supported address types in this repository.
enum AddressType {
  BECH32,
  BASE58,
  REGULAR,
  BTC,
  ETH,
  KAS,
  FIL,
  TON,
  ALGO,
  NONE,
}

/// Provides series of address validation methods, integrated within [checkAddressValid].
class AddressUtils {
  static bool checkAddressValid(String address, WalletSetting conf) {
    switch (conf.addressType) {
      case AddressType.ETH:
        return checkEthAddress(address);
      case AddressType.BTC:
        return checkBtcAddress(address, conf.networkType);
      case AddressType.BECH32:
        return checkBech32Address(address, conf.prefix, conf.bech32Length);
      case AddressType.BASE58:
        return checkBase58Address(address, conf.regExp);
      case AddressType.KAS:
        return checkKasAddress(address, conf.prefix);
      case AddressType.FIL:
        return checkFilecoinAddress(address, conf);
      case AddressType.TON:
        return checkTonAddress(address);
      case AddressType.ALGO:
        return checkAlgoAddress(address, conf);
      case AddressType.REGULAR:
        return RegExp(conf.regExp).hasMatch(address);
      case AddressType.NONE:
        return RegExp(COMMON_REG).hasMatch(address);
      default:
        // ignore: avoid_print
        print('${getTypeName(conf.addressType)} address not fully support');
        return RegExp(COMMON_REG).hasMatch(address);
    }
  }

  static bool checkEthAddress(String address) {
    return RegExp(ETH_ADDRESS_REG).hasMatch(address);
  }

  static bool checkBtcAddress(String address,
      [bitcoin.NetworkType? networkType]) {
    try {
      if (networkType?.prefix == 'bitcoincash' &&
          !address.startsWith('1') &&
          !address.startsWith('3')) {
        return checkStandardBase32(address);
      }
      if (address.startsWith('bc')) {
        return checkBech32Address(address, 'bc', address.length - 3);
      }
      bitcoin.Address.addressToOutputScript(address, networkType);
      return true;
    } catch (error) {
      return false;
    }
  }

  static bool checkBech32Address(String address, String prefix, int length) {
    if (!RegExp('^${prefix}1[a-zA-Z0-9]{$length}\$').hasMatch(address)) {
      return false;
    }
    try {
      final result = checkBech32(address, prefix: prefix);
      return result;
    } catch (error) {
      return false;
    }
  }

  static bool checkBase58Address(String address, String regExp,
      [int length = 32]) {
    try {
      if (!RegExp(regExp).hasMatch(address)) {
        return false;
      }
      if (base58.decode(address)[0] != 1) {
        return base58.decode(address).sublist(1).length == length;
      } else {
        return base58.decode(address).sublist(1).length >= length;
      }
    } catch (error) {
      return false;
    }
  }

  static bool checkKasAddress(String address, String prefix) {
    try {
      final eight0 = [0, 0, 0, 0, 0, 0, 0, 0];
      List<int> prefixDecode = [];
      switch (prefix) {
        case KAS_PREFIX:
          if (!address.startsWith(KAS_PREFIX)) return false;
          prefixDecode = KAS_DECODE;
          break;
        case KLS_PREFIX:
          if (!address.startsWith(KLS_PREFIX)) return false;
          prefixDecode = KLS_DECODE;
          break;
        default:
          return false;
      }
      // delete prefix
      final addressData = address.split(':').last;
      final addressBytes = Base32.decode(addressData);
      // split address
      final payloadData = addressBytes.sublist(0, addressBytes.length - 8);
      final decodedPolymodData = addressBytes.sublist(addressBytes.length - 8);
      // compute checksum
      final checksumData = [...prefixDecode, ...payloadData, ...eight0];
      final newPolymodData = checksumToArray(polymod(checksumData));
      // check
      for (int i = 0; i < 8; i++) {
        if (newPolymodData[i] != decodedPolymodData[i]) {
          return false;
        }
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  static bool checkFilecoinAddress(String address, conf) {
    if (address.startsWith('f410'))
      return RegExp(conf.regExp).hasMatch(address);
    if (address.startsWith('0x'))
      return RegExp(ETH_ADDRESS_REG).hasMatch(address);
    return checkRFC4648Base32(address, conf.prefix);
  }

  static bool checkTonAddress(addressString) {
    if (addressString.contains('-') || addressString.contains('_')) {
      addressString = addressString.replaceAll('-', '+').replaceAll('_', '/');
    }
    if (addressString.contains(':')) {
      List<String> arr = addressString.split(':');
      if (arr.length != 2) return false;
      int wc = int.tryParse(arr[0]) ?? -2;
      if (wc != 0 && wc != -1) return false;
      String hex = arr[1];
      if (hex.length != 64) return false;
    }

    if (addressString.length != 48) return false;

    final data = base64.decode(addressString);
    if (data.length != 36) return false;

    final addr = data.sublist(0, 34);
    final crc = data.sublist(34, 36);
    final calcedCrc = crc16(addr);

    if (!(calcedCrc[0] == crc[0] && calcedCrc[1] == crc[1])) return false;

    int tag = addr[0];

    const bounceableTag = 0x11;
    const nonBounceableTag = 0x51;
    const testFlag = 0x80;

    if ((tag & testFlag) != 0) tag = tag ^ testFlag;
    if (tag != bounceableTag && tag != nonBounceableTag) return false;

    int wc;
    if (addr[1] == 0xff) {
      wc = -1;
    } else {
      wc = addr[1];
    }

    if (wc != 0 && wc != -1) return false;

    return true;
  }

  static bool checkAlgoAddress(String address, conf) {
    if (!RegExp(conf.regExp).hasMatch(address.toLowerCase())) return false;

    final base32Data =
        Base32.decode(address.toLowerCase(), type: Base32Type.RFC4648);
    final data = base32Data.sublist(0, base32Data.length - 4);
    final checkSum = base32Data.sublist(base32Data.length - 4);
    final sha512data = getSHA512256(data.toUint8List());
    final dataCheckSum = sha512data.sublist(sha512data.length - 4);
    if (checkSum.toStr() != dataCheckSum.toStr()) return false;

    return true;
  }
}

Uint8List crc16(Uint8List data) {
  const int poly = 0x1021;
  int reg = 0;
  final message = Uint8List(data.length + 2);
  message.setAll(0, data);

  for (int byte in message) {
    int mask = 0x80;
    while (mask > 0) {
      reg <<= 1;
      if ((byte & mask) != 0) {
        reg += 1;
      }
      mask >>= 1;

      if (reg > 0xffff) {
        reg &= 0xffff;
        reg ^= poly;
      }
    }
  }

  return Uint8List.fromList([(reg >> 8) & 0xff, reg & 0xff]);
}

/// Check base32 address, such as bitcoincash.
bool checkStandardBase32(String address) {
  try {
    String addressData = address;
    if (address.startsWith('bitcoincash:'))
      addressData = address.substring(address.indexOf(':') + 1);
    
    // Basic validation: CashAddr addresses should be at least 14 characters
    if (addressData.length < 14) {
      return false;
    }
    
    final decoded = Base32.decode(addressData).toUint8List();
    final addressEncode = Base32.encode(decoded);
    return addressEncode == addressData;
  } catch (error) {
    return false;
  }
}

bool checkRFC4648Base32(String address, String prefix) {
  try {
    String addressData =
        address.substring(address.indexOf(prefix) + prefix.length);
    final decoded =
        Base32.decode(addressData, type: Base32Type.RFC4648).toUint8List();
    final addressEncode = Base32.encode(decoded, type: Base32Type.RFC4648);
    return addressEncode == addressData;
  } catch (error) {
    return false;
  }
}

/// Check base58 address with checksum, such as btc.
bool checkBase58(String address, {int length = 25}) {
  Uint8List decoded = base58.decode(address);
  if (decoded.length != length) {
    return false;
  }
  Uint8List data = decoded.sublist(0, decoded.length - 4);
  Uint8List checksum = decoded.sublist(decoded.length - 4);
  Uint8List midData = Uint8List.fromList(sha256.convert(data).bytes);
  Uint8List calculatedChecksum =
      Uint8List.fromList(sha256.convert(midData).bytes.sublist(0, 4));
  for (int i = 0; i < 4; i++) {
    if (checksum[i] != calculatedChecksum[i]) {
      return false;
    }
  }
  return true;
}

String getBase58Address(Uint8List bytes) {
  var doubleHash = getSHA256Digest(getSHA256Digest(bytes));
  final Uint8List checksum = Uint8List.fromList(doubleHash.sublist(0, 4));
  final Uint8List payload = Uint8List.fromList([...bytes, ...checksum]);
  return base58.encode(payload);
}

/// Check bech32 address with prefix, such as ckb.
bool checkBech32(String address, {String prefix = ''}) {
  Bech32 decoded = bech32.decode(address);
  if (decoded.hrp != prefix) return false;
  final checksum = createChecksum(decoded.hrp, decoded.data);
  final result = verifyChecksum(decoded.hrp, decoded.data + checksum);
  return result;
}

/// Check eth address with checksum.
String toEthChecksumAddress(String address) {
  final addressLowCase = address.toLowerCase().replaceFirst('0x', '');
  final bytes = utf8.encode(addressLowCase);
  final hash = getKeccakDigest(bytes).toStr();
  String checksumAddress = '0x';
  for (int i = 0; i < addressLowCase.length; i++) {
    if (int.parse(hash[i], radix: 16) > 7) {
      checksumAddress += addressLowCase[i].toUpperCase();
    } else {
      checksumAddress += addressLowCase[i];
    }
  }

  return checksumAddress;
}

/// A method to get [AddressType] by network name([String]).
AddressType getAddressType(network) {
  return AddressType.values.firstWhere(
      (e) => (e.toString().split(".").last) == network.toUpperCase(),
      orElse: () => AddressType.NONE);
}

/// [AddressType] enum to [String]
String getTypeName(AddressType network) {
  return network.toString().split(".").last;
}
