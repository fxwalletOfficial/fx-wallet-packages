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

  Web3EthSettings({this.chainId, this.icon, this.rdns});
}

class Web3SolSettings {
  final String? icon;

  Web3SolSettings({this.icon});
}
