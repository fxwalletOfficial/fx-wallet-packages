import 'dart:typed_data' show Uint8List;

import '../crypto/pubkey.dart';

class SignaturePubkeyPair {
  /// A signature and its corresponding public key.
  const SignaturePubkeyPair({this.signature, required this.pubkey});

  /// The signature.
  final Uint8List? signature;

  /// The public key.
  final Pubkey pubkey;

  /// Creates a copy of this class applying the provided parameters to the new instance.
  SignaturePubkeyPair copyWith({
    final Uint8List? signature,
    final Pubkey? pubkey,
  }) =>
      SignaturePubkeyPair(
        signature: signature ?? this.signature,
        pubkey: pubkey ?? this.pubkey,
      );
}
