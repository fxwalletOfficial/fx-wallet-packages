class Web3Settings {
  final String? name;
  final Web3EthSettings? eth;
  final Web3SolSettings? sol;

  Web3Settings({this.name, this.eth, this.sol});
}

class Web3EthSettings {
  /// First init chain id. It will be 1(Ethereum Mainnet) if is set null.
  final int? chainId;

  /// Icon display for EIP-6369.
  final String? icon;

  /// Rdns display for EIP-6369.
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
  final String? icon;

  Web3SolSettings({this.icon});
}
