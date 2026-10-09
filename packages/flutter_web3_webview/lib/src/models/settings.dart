class Web3Settings {
  /// Wallet display name shared by EIP-6963 and Solana Wallet Standard.
  /// Defaults to `Web3Wallet` when omitted.
  final String? name;
  final Web3EthSettings? eth;
  final Web3SolSettings? sol;

  Web3Settings({this.name, this.eth, this.sol});
}

class Web3EthSettings {
  /// First init chain id. It will be 1(Ethereum Mainnet) if is set null.
  final int? chainId;

  /// Complete image data URI for EIP-6963, e.g. `data:image/png;base64,...`.
  /// Flutter asset paths are not supported. Defaults to the built-in FxWallet icon.
  final String? icon;

  /// EIP-6963 reverse-DNS identifier, e.g. `com.example.wallet`.
  /// Defaults to `io.web3wallet`; host apps should supply their own identifier.
  final String? rdns;

  /// When true, `window.ethereum.isMetaMask` reports `true`.
  ///
  /// Defaults to `false` — the wallet identifies as itself. Set it to `true`
  /// to impersonate MetaMask, which some DApps still require (they gate
  /// signing / advanced features on `isMetaMask`, e.g. the official
  /// MetaMask test dapp). This is a per-integration choice; the package
  /// does not impersonate by default.
  final bool overwriteMetamask;

  Web3EthSettings({
    this.chainId,
    this.icon,
    this.rdns,
    this.overwriteMetamask = false,
  });
}

class Web3SolSettings {
  /// Complete image data URI for Solana Wallet Standard, e.g. `data:image/png;base64,...`.
  /// Flutter asset paths are not supported. Defaults to the built-in FxWallet icon.
  final String? icon;

  Web3SolSettings({this.icon});
}
