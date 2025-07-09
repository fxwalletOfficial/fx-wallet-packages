import 'package:crypto/crypto.dart' show sha256;
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'nacl.dart' as nacl show pubkeyLength;
import 'nacl_low_level.dart' as nacl_low_level;

/// Public Key
/// ------------------------------------------------------------------------------------------------

class Pubkey {
  /// Creates a [Pubkey] from an `ed25519` public key [value].
  const Pubkey(
    final BigInt value,
  ) : _value = value;

  /// The public key's `ed25519` value.
  final BigInt _value;

  /// Creates a default [Pubkey] (0 => '11111111111111111111111111111111').
  factory Pubkey.zero() {
    return Pubkey(BigInt.zero);
  }

  /// Creates a [Pubkey] from a `base-58` encoded [pubkey].
  factory Pubkey.fromString(final String pubkey) = Pubkey.fromBase58;

  /// Creates a [Pubkey] from a `base-58` encoded [pubkey].
  factory Pubkey.fromJson(final String pubkey) = Pubkey.fromBase58;

  /// Creates a [Pubkey] from a `base-58` encoded [pubkey].
  factory Pubkey.fromBase58(final String pubkey) {
    return Pubkey.fromUint8List(base58.decode(pubkey));
  }

  /// Creates a [Pubkey] from a `base-58` encoded [pubkey].
  ///
  /// Returns `null` if [pubkey] is omitted.
  static Pubkey? tryFromBase58(final String? pubkey) {
    return pubkey != null ? Pubkey.fromBase58(pubkey) : null;
  }

  /// Creates a [Pubkey] from a `base-64` encoded [pubkey].
  factory Pubkey.fromBase64(final String pubkey) {
    return Pubkey.fromUint8List(base64.decode(pubkey));
  }

  /// Creates a [Pubkey] from a `base-64` encoded [pubkey].
  ///
  /// Returns `null` if [pubkey] is omitted.
  static Pubkey? tryFromBase64(final String? pubkey) {
    return pubkey != null ? Pubkey.fromBase64(pubkey) : null;
  }

  /// Creates a [Pubkey] from a byte array [pubkey].
  factory Pubkey.fromUint8List(final Iterable<int> pubkey) {
    if (pubkey.length > nacl.pubkeyLength)
      throw Exception('Invalid public key length.');
    return Pubkey(FxBigInt.fromUint8List(pubkey));
  }

  /// Creates a [Pubkey] from a byte array [pubkey].
  ///
  /// Returns `null` if [pubkey] is omitted.
  static Pubkey? tryFromUint8List(final Iterable<int>? pubkey) {
    return pubkey != null ? Pubkey.fromUint8List(pubkey) : null;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Pubkey && _value == other._value;
  }

  /// Compares this [Pubkey] to [other].
  ///
  /// Returns a negative value if `this` is ordered before `other`, a positive value if `this` is
  /// ordered after `other`, or zero if `this` and `other` are equivalent. Ordering is based on the
  /// [BigInt] value of the public keys.
  int compareTo(final Pubkey other) {
    return _value.compareTo(other._value);
  }

  /// Returns true if this [Pubkey] is equal to the provided [pubkey].
  bool equals(final Pubkey pubkey) {
    return _value == pubkey._value;
  }

  /// Returns this [Pubkey] as a `base-58` encoded string.
  String toBase58() {
    return base58.encode(toBytes());
  }

  /// Returns this [Pubkey] as a `base-64` encoded string.
  String toBase64() {
    return base64.encode(toBytes());
  }

  /// Returns this [Pubkey] as a byte array.
  Uint8List toBytes() {
    return _value.toUint8List(nacl.pubkeyLength);
  }

  /// Returns this [Pubkey] as a byte buffer.
  ByteBuffer toBuffer() {
    return toBytes().buffer;
  }

  /// Returns this [Pubkey] as a `base-58` encoded string.
  @override
  String toString() {
    return toBase58();
  }

  /// Derives a [Pubkey] from another [pubkey], [seed], and [programId].
  ///
  /// The program Id will also serve as the owner of the public key, giving it permission to write
  /// data to the account.
  static Pubkey createWithSeed(
    final Pubkey pubkey,
    final String seed,
    final Pubkey programId,
  ) {
    final Uint8List seedBytes = Uint8List.fromList(utf8.encode(seed));
    final List<int> buffer = pubkey.toBytes() + seedBytes + programId.toBytes();
    return Pubkey.fromUint8List(sha256.convert(buffer).bytes);
  }

  /// Returns true if [pubkey] falls on the `ed25519` curve.
  static bool isOnCurve(final Uint8List pubkey) {
    return nacl_low_level.isOnCurve(pubkey) == 1;
  }
}
