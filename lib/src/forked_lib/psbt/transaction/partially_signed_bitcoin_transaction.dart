import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto_wallet_util/src/forked_lib/psbt/model/origin.dart';

import '../../bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:crypto_wallet_util/config.dart';
import 'package:crypto_wallet_util/src/utils/number.dart';
import '../model/transfer_info.dart' as fx;
import '../model/transfer_info.dart';
import '../transaction/script_public_key.dart';
import 'package:hex/hex.dart';

import '../transaction/transaction.dart';
import '../transaction/transaction_output.dart';
import '../utils/address_type.dart';
import '../utils/converter.dart';
import '../utils/varints.dart';

const PSBT_IN_TAP_KEY_SIG = "13";
const PSBT_IN_TAP_SCRIPT_SIG = "14";
const PSBT_IN_TAP_BIP32_DERIVATION = "16";
const PSBT_IN_TAP_INTERNAL_KEY = "17";

enum WalletType { SingleSignatureWallet, MultisignatureWallet }

/// Represents a PSBT(BIP-0174).
class PSBT {
  /// @nodoc
  Map<String, dynamic> psbtMap;

  /// Get transaction not signed yet.
  Transaction? unsignedTransaction;

  /// @nodoc
  List<PsbtInput> inputs = [];

  /// @nodoc
  List<PsbtOutput> outputs = [];

  /// @nodoc
  DerivationPath? derivationPath;

  /// Get the fee of the transaction.
  int get fee => () {
        int totalInput = 0;
        int totalOutput = 0;

        for (int i = 0; i < inputs.length; i++) {
          PsbtInput input = inputs[i];

          if (input.witnessUtxo != null) {
            //  witnessUtxo (PSBT key type 01)
            int amount = input.witnessUtxo!.amount;
            totalInput += amount;
          } else if (input.previousTransaction != null) {
            // nonWitnessUtxo (PSBT key type 00)
            Transaction prevTx = input.previousTransaction!;
            int outputIndex = unsignedTransaction!.inputs[i].index;
            if (outputIndex < prevTx.outputs.length) {
              int amount = prevTx.outputs[outputIndex].amount;
              totalInput += amount;
            } else {
              throw Exception(
                  'Invalid output index $outputIndex in previous transaction');
            }
          } else {
            throw Exception('No UTXO information found for input $i');
          }
        }

        for (int i = 0; i < unsignedTransaction!.outputs.length; i++) {
          int amount = unsignedTransaction!.outputs[i].amount;
          totalOutput += amount;
        }
        int fee = totalInput - totalOutput;

        return fee;
      }();

  List<String> get inputAddresses => () {
        List<String> inputAddresses = [];
        for (int i = 0; i < inputs.length; i++) {
          PsbtInput input = inputs[i];

          if (input.witnessUtxo != null) {
            //  witnessUtxo (PSBT key type 01)
            inputAddresses.add(input.witnessUtxo!.getAddress());
          } else if (input.previousTransaction != null) {
            // nonWitnessUtxo (PSBT key type 00)
            Transaction prevTx = input.previousTransaction!;
            int outputIndex = unsignedTransaction!.inputs[i].index;
            if (outputIndex < prevTx.outputs.length) {
              inputAddresses.add(prevTx.outputs[outputIndex].getAddress());
            } else {
              throw Exception(
                  'Invalid output index $outputIndex in previous transaction');
            }
          } else {
            throw Exception('No UTXO information found for input $i');
          }
        }
        return inputAddresses;
      }();

  /// Get the transfer amount of the transaction.
  int get transferAmount => () {
        int totalAmount = 0;
        int sameCount = 0;
        for (int i = 0; i < unsignedTransaction!.outputs.length; i++) {
          String outputAddress = unsignedTransaction!.outputs[i].getAddress();
          if (!inputAddresses.contains(outputAddress)) {
            totalAmount += unsignedTransaction!.outputs[i].amount;
          } else {
            sameCount++;
          }
        }
        if (sameCount > 0 && sameCount == unsignedTransaction!.outputs.length) {
          return unsignedTransaction!.outputs[0].amount;
        }

        return totalAmount;
      }();

  /// Get the sending amount of the transaction.
  int get sendingAmount => () {
        int sendingAmount = 0;
        for (PsbtOutput output in outputs) {
          if (output.derivationPath != null && output.isChange) continue;
          sendingAmount += output.amount!;
        }

        return sendingAmount;
      }();

  /// @nodoc
  PSBT(this.psbtMap) {
    unsignedTransaction =
        Transaction.parsePsbtTransaction(psbtMap["global"]["00"]);

    psbtMap["global"].keys.forEach((key) {
      if (key.startsWith('01')) {
        String publicKey = key.substring(2);
        String parentFingerprint = psbtMap["global"][key].substring(0, 8);
        String derivationPath = _parseDerivationPath(
            Converter.hexToBytes(psbtMap["global"][key].substring(8)));
        this.derivationPath =
            DerivationPath(publicKey, parentFingerprint, derivationPath);
      }
    });

    for (int i = 0; i < psbtMap["inputs"].length; i++) {
      Transaction? prevTx;
      if (psbtMap["inputs"][i].containsKey("00")) {
        prevTx = Transaction.parse(psbtMap["inputs"][i]["00"]);
      }
      TransactionOutput? witnessUtxo;
      String? taprootKeySpendSignature;
      String? taprootKeyBip32DerivationPath;
      String? taprootInternalKey;
      if (psbtMap["inputs"][i].containsKey("01")) {
        witnessUtxo = TransactionOutput.parse(psbtMap["inputs"][i]["01"]);
      }
      if (psbtMap["inputs"][i].containsKey(PSBT_IN_TAP_KEY_SIG)) {
        taprootKeySpendSignature = psbtMap["inputs"][i][PSBT_IN_TAP_KEY_SIG];
      }
      if (psbtMap["inputs"][i].containsKey(PSBT_IN_TAP_INTERNAL_KEY)) {
        taprootInternalKey = psbtMap["inputs"][i][PSBT_IN_TAP_INTERNAL_KEY];
      }
      DerivationPath? inputDerivationPath;
      List<String> partialSigs = [];
      psbtMap["inputs"][i].keys.forEach((key) {
        if (key.startsWith('06')) {
          String publicKey = key.substring(2);
          String parentFingerprint = psbtMap["inputs"][i][key].substring(0, 8);
          String derivationPath = _parseDerivationPath(
              Converter.hexToBytes(psbtMap["inputs"][i][key].substring(8)));
          inputDerivationPath =
              DerivationPath(publicKey, parentFingerprint, derivationPath);
        }
        if (key.startsWith('02')) {
          String publicKey = key.substring(2);
          String signature = psbtMap["inputs"][i][key];
          partialSigs.add(signature);
          partialSigs.add(publicKey);
        }
        if (key.startsWith(PSBT_IN_TAP_BIP32_DERIVATION)) {
          String xonlypubkey = key.substring(2);
          taprootInternalKey = taprootInternalKey ?? xonlypubkey;
        }
      });
      inputs.add(PsbtInput(
          prevTx,
          witnessUtxo,
          inputDerivationPath,
          partialSigs,
          taprootKeySpendSignature,
          taprootKeyBip32DerivationPath,
          taprootInternalKey));
    }

    for (int i = 0; i < psbtMap["outputs"].length; i++) {
      int? amount;
      String? script;
      if (psbtMap["outputs"][i].containsKey("03")) {
        amount = Converter.littleEndianToInt(
            Converter.hexToBytes(psbtMap["outputs"][i]["03"]));
      }

      if (psbtMap["outputs"][i].containsKey("04")) {
        script = psbtMap["outputs"][i]["04"];
      }

      DerivationPath? outputDerivationPath;
      psbtMap["outputs"][i].keys.forEach((key) {
        if (key.startsWith('02')) {
          String publicKey = key.substring(2);
          String parentFingerprint = psbtMap["outputs"][i][key].substring(0, 8);
          String derivationPath = _parseDerivationPath(
              Converter.hexToBytes(psbtMap["outputs"][i][key].substring(8)));
          outputDerivationPath =
              DerivationPath(publicKey, parentFingerprint, derivationPath);
        }
      });
      outputs.add(PsbtOutput(outputDerivationPath, amount, script));
    }
  }

  /// Generate the PSBT to base64 string.
  String serialize() {
    List<int> psbtBytes = [0x70, 0x73, 0x62, 0x74, 0xff];
    //Global
    psbtBytes.addAll(_serializeKeyMap(psbtMap["global"]));
    psbtBytes.add(0x00);
    List<dynamic> inputList = psbtMap["inputs"];
    for (int i = 0; i < inputList.length; i++) {
      psbtBytes.addAll(_serializeKeyMap(inputList[i]));
      psbtBytes.add(0x00);
    }
    //psbtBytes.add(0x00);
    List<dynamic> outputList = psbtMap["outputs"];
    for (int i = 0; i < outputList.length; i++) {
      psbtBytes.addAll(_serializeKeyMap(outputList[i]));
      psbtBytes.add(0x00);
    }

    psbtBytes.add(0x00);
    // return base64Encode(psbtBytes);
    return HEX.encode(psbtBytes);
  }

  List<int> _serializeKeyMap(Map<String, dynamic> map) {
    List<int> globalBytes = [];
    map.forEach((key, value) {
      List<int> keyBytes = Converter.hexToBytes(key);
      globalBytes += Varints.encode(keyBytes.length);
      globalBytes += keyBytes;
      List<int> valueBytes = Converter.hexToBytes(value);
      globalBytes += Varints.encode(valueBytes.length);
      globalBytes += valueBytes;
    });
    return globalBytes;
  }

  static int _calculateEstimationFee(int numberOfInput, int numberOfOutput,
      int feeRate, BtcAddressType addressType) {
    int baseByte = 10;
    int perOutputByte = 0;
    int perInputByte = 0;

    if (addressType == BtcAddressType.p2pkh) {
      perOutputByte = 34;
      perInputByte = 148;
    } else if (addressType == BtcAddressType.p2wpkh) {
      perOutputByte = 31;
      perInputByte = 68;
      baseByte += 2;
    } else if (addressType == BtcAddressType.p2sh) {
      perOutputByte = 32;
      perInputByte = 91;
    }
    int totalByte = baseByte +
        perOutputByte * numberOfOutput +
        perInputByte * numberOfInput;
    return totalByte * feeRate;
  }

  static Uint8List psbtToBytes(String psbtBase64) {
    Uint8List psbtBytes;
    if (psbtBase64.contains("=") || psbtBase64.contains("/")) {
      psbtBytes = base64Decode(psbtBase64);
    } else {
      psbtBytes = Uint8List.fromList(HEX.decode(psbtBase64));
    }
    final version = psbtBytes.sublist(0, 5);
    if (version[0] != 0x70 ||
        version[1] != 0x73 ||
        version[2] != 0x62 ||
        version[3] != 0x74 ||
        version[4] != 0xff) {
      throw Exception('Invalid PSBT');
    }
    return psbtBytes;
  }

  static Map<String, String> psbtToGlobalMap(Uint8List psbtBytes, int offset) {
    Map<String, String> globalMap = {};
    while (true) {
      int keyLen = Varints.read(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      if (keyLen == 0) {
        break;
      }
      Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
      offset += keyLen;
      int valueLen = Varints.read(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
      offset += valueLen;
      globalMap[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
    }
    return globalMap;
  }

  factory PSBT.fromTransferPsbt(BtcTransferInfo btcInfo,
      {WalletType walletType = WalletType.SingleSignatureWallet}) {
    String xpubkey = btcInfo.xpubkey;
    final chainConf = getChainConfig(btcInfo.chain).mainnet;
    final hdWallet =
        bitcoin.HDWallet.fromBase58(xpubkey, network: chainConf.networkType);
    final Origin btcTxData = btcInfo.origin;

    int offset = 0;
    Uint8List psbtBytes = psbtToBytes(btcTxData.hex);
    offset += 5;

    Map<String, dynamic> psbtData = {"global": {}, "inputs": [], "outputs": []};

    // Global
    Map<String, String> globalMap = {};
    while (true) {
      int keyLen = Varints.read(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      if (keyLen == 0) {
        break;
      }
      Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
      offset += keyLen;
      int valueLen = Varints.read(psbtBytes, offset);
      offset += _getOffset(psbtBytes[offset]);
      Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
      offset += valueLen;
      globalMap[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
    }
    psbtData["global"] = globalMap;
    // Inputs

    if (psbtData["global"]["00"] == null) {
      throw Exception('Invalid PSBT');
    }
    Transaction globalTx =
        Transaction.parsePsbtTransaction(psbtData["global"]["00"]);

    for (int i = 0; i < globalTx.inputs.length; i++) {
      Map<String, String> inputData = {};
      while (true) {
        int keyLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        inputData[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
      }
      //derivation path
      String bip32DerivationKeyType =
          getKeyType(inputKeyType, 'BIP32_DERIVATION');
      String derivationPath =
          btcTxData.inputs[i].path.derivation ?? btcInfo.path;
      if (walletType == WalletType.SingleSignatureWallet) {
        final List<int> pathList = getHDPath(derivationPath);
        final child = hdWallet.derive(pathList[3]).derive(pathList[4]);

        String publicKey = child.pubKey!;
        String toxonlypub = child.pubKey!.length == 64
            ? child.pubKey!
            : child.pubKey!.substring(2);
        Uint8List fingerPrint = hdWallet.fingerprint!;
        if (btcInfo.txType != fx.BtcTxType.TAPROOT) {
          inputData[bip32DerivationKeyType + publicKey] = Converter.bytesToHex(
                  fingerPrint) +
              Converter.bytesToHex(_serializeDerivationPath(derivationPath));
        } else {
          inputData[PSBT_IN_TAP_BIP32_DERIVATION + toxonlypub] =
              '00${Converter.bytesToHex(fingerPrint)}${Converter.bytesToHex(_serializeDerivationPath(derivationPath))}';
        }
      }
      psbtData["inputs"].add(inputData);
    }

    // Change
    String receiveAddress = btcInfo.outputAddress;
    final outputs = btcTxData.outputs;
    final result = outputs.firstWhere((e) => e.address == receiveAddress);
    num actualAmount =
        result.amount ?? NumberUtil.toDouble(result.value) / 1000000;
    List<int> outputsIndex = List.generate(outputs.length, (index) => index);
    String inputAddress = btcInfo.inputAddress;
    for (var i = 0; i < outputs.length; i++) {
      if (outputs[i].address == receiveAddress) {
        if (outputs[i].amount == actualAmount) {
          outputsIndex.remove(i);
        }
      }
    }
    int changeIndex = -1; // total - payoff;
    if (outputsIndex.isNotEmpty &&
        (outputs[outputsIndex[0]].address == inputAddress ||
            (btcInfo.chain.toLowerCase() == 'bch' &&
                (outputs[outputsIndex[0]].address ==
                        bitcoin.Address.bchToLegacy(inputAddress) ||
                    outputs[outputsIndex[0]].address ==
                        bitcoin.Address.legacyToBch(
                            address: inputAddress, prefix: 'bitcoincash'))))) {
      changeIndex = outputsIndex[0];
    }

    // Outputs
    for (int i = 0; i < globalTx.outputs.length; i++) {
      Map<String, String> outputData = {};
      while (true) {
        int keyLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Varints.read(psbtBytes, offset);

        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);

        offset += valueLen;
        outputData[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
      }
      if (i == changeIndex) {
        String bip32DerivationKeyType =
            getKeyType(outputKeyType, 'BIP32_DERIVATION');
        String derivationPath = btcTxData.outputs[i].path ?? btcInfo.path;
        final List<int> pathList = getHDPath(derivationPath);
        final child = hdWallet.derive(pathList[3]).derive(pathList[4]);
        String publicKey = child.pubKey!;
        Uint8List fingerPrint = hdWallet.fingerprint!;
        outputData[bip32DerivationKeyType + publicKey] =
            Converter.bytesToHex(fingerPrint) +
                Converter.bytesToHex(_serializeDerivationPath(derivationPath));
      }
      psbtData["outputs"].add(outputData);
    }

    return PSBT(psbtData);
  }

  /// Parse a PSBT from a base64 string.
  factory PSBT.parse(String psbtBase64) {
    int offset = 0;
    Uint8List psbtBytes = psbtToBytes(psbtBase64);
    offset += 5;

    Map<String, dynamic> psbtData = {"global": {}, "inputs": [], "outputs": []};

    // Global
    Map<String, String> globalMap = {};

    while (true) {
      int keyLen = Varints.read(psbtBytes, offset);

      offset += _getOffset(psbtBytes[offset]);
      if (keyLen == 0) {
        break;
      }

      Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
      offset += keyLen;
      int valueLen = Varints.read(psbtBytes, offset);

      offset += _getOffset(psbtBytes[offset]);
      Uint8List value = psbtBytes.sublist(offset, offset + valueLen);

      offset += valueLen;
      globalMap[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
    }
    psbtData["global"] = globalMap;
    // Inputs
    if (psbtData["global"]["00"] == null) {
      throw Exception('Invalid PSBT');
    }
    Transaction globalTx =
        Transaction.parsePsbtTransaction(psbtData["global"]["00"]);

    for (int i = 0; i < globalTx.inputs.length; i++) {
      Map<String, String> inputData = {};
      while (true) {
        int keyLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        inputData[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
      }
      psbtData["inputs"].add(inputData);
    }

    // Outputs
    for (int i = 0; i < globalTx.outputs.length; i++) {
      Map<String, String> outputData = {};
      while (true) {
        int keyLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        if (keyLen == 0) {
          break;
        }
        Uint8List key = psbtBytes.sublist(offset, offset + keyLen);
        offset += keyLen;
        int valueLen = Varints.read(psbtBytes, offset);
        offset += _getOffset(psbtBytes[offset]);
        Uint8List value = psbtBytes.sublist(offset, offset + valueLen);
        offset += valueLen;
        outputData[Converter.bytesToHex(key)] = Converter.bytesToHex(value);
      }
      psbtData["outputs"].add(outputData);
    }

    return PSBT(psbtData);
  }

  /// @nodoc
  PsbtInput getPsbtInput(String txHash) {
    return inputs.firstWhere(
        (element) => element.previousTransaction!.transactionHash == txHash);
  }

  /// Add a signature to the PSBT.
  void addSignature(int inputIndex, String signature, String publicKey) {
    inputs[inputIndex]._addSignature(signature, publicKey);
    psbtMap["inputs"][inputIndex]["02$publicKey"] = signature;
  }

  /// @nodoc
  @override
  String toString() {
    return jsonEncode(psbtMap);
  }

  static int _getOffset(int prefix) {
    if (prefix == 0xfd) {
      return 3;
    } else if (prefix == 0xfe) {
      return 5;
    } else if (prefix == 0xff) {
      return 9;
    }
    return 1;
  }

  /// @nodoc
  static Map<int, String> globalKeyType = {
    0: 'UNSIGNED_TX',
    1: 'XPUB',
    2: 'TX_VERSION',
    3: 'LOCKTIME',
    4: 'TX_IN_COUNT',
    5: 'TX_OUT_COUNT',
    6: 'TX_MODIFIABLE',
    251: 'VERSION',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static Map<int, String> inputKeyType = {
    0: 'NON_WITNESS_UTXO',
    1: 'WITNESS_UTXO',
    2: 'PARTIAL_SIG',
    3: 'SIGHASH_TYPE',
    4: 'REDEEM_SCRIPT',
    5: 'WITNESS_SCRIPT',
    6: 'BIP32_DERIVATION',
    7: 'FINAL_SCRIPTSIG',
    8: 'FINAL_SCRIPTWITNESS',
    9: 'POR_COMMITMENT',
    10: 'RIPEMD160',
    11: 'SHA256',
    12: 'HASH160',
    13: 'HASH256',
    14: 'PREVIOUS_TXID',
    15: 'OUTPUT_INDEX',
    16: 'SEQUENCE',
    17: 'REQUIRED_TIME_LOCKTIME',
    18: 'REQUIRED_HEIGHT_LOCKTIME',
    19: 'TAP_KEY_SIG',
    20: 'TAP_SCRIPT_SIG',
    21: 'TAP_LEAF_SCRIPT',
    22: 'TAP_BIP32_DERIVATION',
    23: 'TAP_INTERNAL_KEY',
    24: 'TAP_MERKLE_ROOT',
    25: 'REQUIRED_HEIGHT_LOCKTIME',
    26: 'REQUIRED_HEIGHT_LOCKTIME',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static Map<int, String> outputKeyType = {
    0: 'REDEEM_SCRIPT',
    1: 'WITNESS_SCRIPT',
    2: 'BIP32_DERIVATION',
    3: 'AMOUNT',
    4: 'SCRIPT',
    5: 'TAP_INTERNAL_KEY',
    6: 'TAP_TREE',
    7: 'TAP_BIP32_DERIVATION',
    252: 'PROPRIETARY'
  };

  /// @nodoc
  static String getKeyType(Map<int, String> keyTypeMap, String typeName) {
    return Converter.decToHexWithPadding(
        globalKeyType.keys
            .firstWhere((element) => keyTypeMap[element] == typeName),
        2);
  }

  /// @nodoc
  static Uint8List _serializeDerivationPath(String derivationPath) {
    final path = derivationPath.split('/').sublist(1).map((e) {
      if (e.contains('\'')) {
        return int.parse(e.replaceAll('\'', '')) + 0x80000000;
      } else {
        return int.parse(e);
      }
    }).toList();

    List<int> serializedPath = [];

    for (var index in path) {
      serializedPath.addAll(Converter.intToLittleEndianBytes(index, 4));
    }
    return Uint8List.fromList(serializedPath);
  }

  /// @nodoc
  static String _parseDerivationPath(Uint8List serializedPath) {
    if (serializedPath.length % 4 != 0) {
      throw ArgumentError('Serialized path length must be a multiple of 4');
    }

    List<String> pathSegments = ['m'];

    for (int i = 0; i < serializedPath.length; i += 4) {
      Uint8List valueBytes = serializedPath.sublist(i, i + 4);
      int value = Converter.littleEndianToInt(valueBytes);

      if (value & 0x80000000 != 0) {
        value &= ~0x80000000;
        pathSegments.add('$value\'');
      } else {
        pathSegments.add('$value');
      }
    }

    return pathSegments.join('/');
  }

  /// Get the transaction if all inputs are signed.
  Transaction getSignedTransaction(BtcAddressType addressType) {
    Transaction signedTransaction =
        Transaction.parsePsbtTransaction(unsignedTransaction!.serialize());
    //every input should have 2 partial sigs
    for (int i = 0; i < inputs.length; i++) {
      if (inputs[i].partialSigs!.length != 2 ||
          inputs[i].taprootKeySpendSignature != null) {
        throw Exception('Not enough signatures');
      }
      if (inputs[i].partialSigs!.length == 2) {
        signedTransaction.inputs[i].setSignature(
            addressType, inputs[i].partialSigs![0], inputs[i].partialSigs![1]);
      } else if (inputs[i].taprootKeySpendSignature != null) {
        signedTransaction.inputs[i].setSignature(addressType,
            inputs[i].taprootKeySpendSignature!, inputs[i].taprootInternalKey!);
      }

      if (inputs[i].witnessUtxo == null ||
          signedTransaction.validateSignature(
              i, inputs[i].witnessUtxo!.serialize(), addressType)) {
        continue;
      } else {
        throw Exception('Invalid Signatures');
      }
    }

    signedTransaction.setIsSegwit(addressType.isSegwit);
    return signedTransaction;
  }

  /// Get estimated fee for the transaction.
  int estimateFee(int feeRate, BtcAddressType addressType) {
    return _calculateEstimationFee(unsignedTransaction!.inputs.length,
        unsignedTransaction!.outputs.length, feeRate, addressType);
  }
}

/// @nodoc
class PsbtInput {
  final Transaction? _previousTransaction;
  final TransactionOutput? _witnessUtxo;
  final DerivationPath? _derivationPath;
  final List<String> _partialSigs;
  String? _taprootKeySpendSignature;
  String? _taprootKeyBip32DerivationPath;
  final String? _taprootInternalKey;
  String? _xonlypubkey;

  Transaction? get previousTransaction => _previousTransaction;
  TransactionOutput? get witnessUtxo => _witnessUtxo;
  DerivationPath? get derivationPath => _derivationPath;
  List<String>? get partialSigs => _partialSigs;
  String? get taprootKeySpendSignature => _taprootKeySpendSignature;
  String? get xonlypubkey => _taprootInternalKey ?? _xonlypubkey;
  String? get taprootKeyBip32DerivationPath => _taprootKeyBip32DerivationPath;
  String? get taprootInternalKey => _taprootInternalKey;

  PsbtInput(
      this._previousTransaction,
      this._witnessUtxo,
      this._derivationPath,
      this._partialSigs,
      this._taprootKeySpendSignature,
      this._taprootKeyBip32DerivationPath,
      this._taprootInternalKey);

  _addSignature(String signature, String publicKey) {
    _partialSigs.add(signature);
    _partialSigs.add(publicKey);
  }

  setTaprootKeySpendSignature(String taprootKeySpendSignature) {
    _taprootKeySpendSignature = taprootKeySpendSignature;
  }

  setXonlypubkey(String xonlypubkey) {
    _xonlypubkey = xonlypubkey;
  }

  setTaprootKeyBip32DerivationPath(String taprootKeyBip32DerivationPath) {
    _taprootKeyBip32DerivationPath = taprootKeyBip32DerivationPath;
  }
}

/// @nodoc
class PsbtOutput {
  final DerivationPath? _derivationPath;
  final int? _amount;
  final String? _script;

  DerivationPath? get derivationPath => _derivationPath;
  int? get amount => _amount;
  String? get script => _script;

  String getAddress() {
    ScriptPublicKey script = ScriptPublicKey.parse(_script!);
    return script.getAddress();
  }

  /// @nodoc
  bool get isChange {
    if (derivationPath == null) {
      return false;
    } else if (derivationPath!.path.split('/')[4] == '1') {
      return true;
    } else {
      return false;
    }
  }

  PsbtOutput(this._derivationPath, this._amount, this._script);
}

/// @nodoc
class DerivationPath {
  final String _publicKey;
  final String _parentFingerprint;
  final String _path;

  DerivationPath(this._publicKey, this._parentFingerprint, this._path);

  String get publicKey => _publicKey;
  String get parentFingerprint => _parentFingerprint.toUpperCase();
  String get path => _path;
}

List<int> getHDPath(String path) {
  List<String> parts = path.replaceAll('-', '/').toLowerCase().split('/');
  return parts.where((p) => p != 'm' && p != '').map((p) {
    if (p.endsWith("'")) {
      p = p.substring(0, p.length - 1);
    }
    int? n = int.tryParse(p);
    if (n == null) {
      throw 'PATH_NOT_VALID';
    } else if (n < 0) {
      throw 'PATH_NEGATIVE_VALUES';
    }
    return n;
  }).toList();
}
