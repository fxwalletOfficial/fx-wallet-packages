/// Immutable credentials for a registered installation's business binding.
///
/// Obtain this snapshot explicitly through `FxPushClient.getBindingData()`.
/// Treat it as a bearer secret: send it only over HTTPS to the authenticated,
/// trusted business backend, keep it transient, and never log it or its JSON.
/// It does not prove user/wallet authority or current server-side validity.
final class FxPushBindingData {
  /// Creates a binding snapshot from one installation's registered identity.
  const FxPushBindingData({
    required this.subscriptionId,
    required this.installationId,
    required this.registrationKey,
  });

  /// Service subscription identifier.
  final String subscriptionId;

  /// Installation identifier used to register [subscriptionId].
  final String installationId;

  /// Bearer credential used to register this installation.
  ///
  /// Possession allows updating or disabling its subscription. Never persist
  /// this in business storage, diagnostics, analytics, or crash reports.
  final String registrationKey;

  /// Explicitly encodes sensitive fields for transient HTTPS submission.
  ///
  /// The returned map contains the bearer secret and must never be logged.
  Map<String, String> toJson() => <String, String>{
        'subscription_id': subscriptionId,
        'installation_id': installationId,
        'registration_key': registrationKey,
      };

  @override
  String toString() => 'FxPushBindingData(redacted)';
}
