/// Secure storage used by the client for its installation identity, enrollment
/// credential, desired active state, and the last server response.
///
/// Implementations must use platform-backed secure storage (Keychain on iOS and
/// encrypted Keystore-backed storage on Android). SharedPreferences and other
/// plaintext stores are not suitable because the enrollment credential is a
/// bearer secret.
abstract interface class FxPushSecureStorage {
  /// Reads a value for [key], or `null` when it is absent.
  Future<String?> read(String key);

  /// Atomically persists [value] for [key].
  Future<void> write(String key, String value);

  /// Deletes [key] when present.
  Future<void> delete(String key);
}
