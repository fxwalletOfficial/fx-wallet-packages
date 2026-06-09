import 'package:flutter/material.dart';

/// Description of an EVM chain the demo knows how to advertise to a DApp.
///
/// `chainId` is the canonical EIP-155 numeric id; the demo expresses it as
/// the integer so `flutter_web3_webview` can hex-encode it on the wire,
/// matching what the Dart `Web3RequestDispatcher` already does for
/// `wallet_switchEthereumChain`.
@immutable
class EvmChain {
  /// EIP-155 numeric chain id (e.g. `1` for mainnet, `137` for Polygon).
  final int chainId;

  /// Short symbol used in compact UI affordances (e.g. `ETH`, `MATIC`).
  final String symbol;

  /// Human-readable name shown in lists / pickers.
  final String name;

  /// Default JSON-RPC URL the demo will use when "real broadcast" mode is
  /// enabled. Public endpoints; expected to be rate-limited.
  final String rpcUrl;

  /// Block explorer base URL used by the bridge log to deep-link tx hashes.
  final String explorerUrl;

  /// Material icon shown next to the chain name. We deliberately stick to
  /// Material icons rather than shipping logo PNGs so the demo stays
  /// dependency-free.
  final IconData icon;

  /// Accent colour used by the AppBar chip when this chain is active.
  final Color color;

  /// Whether this chain is a testnet — used to gate the "real broadcast"
  /// toggle so we only ever broadcast against test networks.
  final bool isTestnet;

  const EvmChain({
    required this.chainId,
    required this.symbol,
    required this.name,
    required this.rpcUrl,
    required this.explorerUrl,
    required this.icon,
    required this.color,
    this.isTestnet = false,
  });
}

/// Description of a Solana cluster.
@immutable
class SolanaCluster {
  /// Identifier used in the wallet-standard `solana:<cluster>` namespace.
  final String id;

  /// Human-readable name shown in lists.
  final String name;

  /// Default RPC endpoint.
  final String rpcUrl;

  final IconData icon;
  final Color color;
  final bool isTestnet;

  const SolanaCluster({
    required this.id,
    required this.name,
    required this.rpcUrl,
    required this.icon,
    required this.color,
    this.isTestnet = false,
  });
}

/// EVM chains advertised in the demo's chain picker.
///
/// Anything not in this list will still work end-to-end (the wallet would
/// just see the raw chain id flow through), but the picker only surfaces
/// what we know how to label cleanly.
const List<EvmChain> kEvmChains = <EvmChain>[
  EvmChain(
    chainId: 1,
    symbol: 'ETH',
    name: 'Ethereum',
    rpcUrl: 'https://ethereum-rpc.publicnode.com',
    explorerUrl: 'https://etherscan.io',
    icon: Icons.diamond_outlined,
    color: Color(0xFF627EEA),
  ),
  EvmChain(
    chainId: 137,
    symbol: 'MATIC',
    name: 'Polygon',
    rpcUrl: 'https://polygon-bor-rpc.publicnode.com',
    explorerUrl: 'https://polygonscan.com',
    icon: Icons.hexagon_outlined,
    color: Color(0xFF8247E5),
  ),
  EvmChain(
    chainId: 10,
    symbol: 'OP',
    name: 'Optimism',
    rpcUrl: 'https://optimism-rpc.publicnode.com',
    explorerUrl: 'https://optimistic.etherscan.io',
    icon: Icons.bolt_outlined,
    color: Color(0xFFFF0420),
  ),
  EvmChain(
    chainId: 42161,
    symbol: 'ARB',
    name: 'Arbitrum One',
    rpcUrl: 'https://arbitrum-one-rpc.publicnode.com',
    explorerUrl: 'https://arbiscan.io',
    icon: Icons.layers_outlined,
    color: Color(0xFF28A0F0),
  ),
  EvmChain(
    chainId: 8453,
    symbol: 'BASE',
    name: 'Base',
    rpcUrl: 'https://base-rpc.publicnode.com',
    explorerUrl: 'https://basescan.org',
    icon: Icons.foundation,
    color: Color(0xFF0052FF),
  ),
  EvmChain(
    chainId: 56,
    symbol: 'BNB',
    name: 'BNB Smart Chain',
    rpcUrl: 'https://bsc-rpc.publicnode.com',
    explorerUrl: 'https://bscscan.com',
    icon: Icons.local_fire_department_outlined,
    color: Color(0xFFF3BA2F),
  ),
  EvmChain(
    chainId: 11155111,
    symbol: 'SEP',
    name: 'Sepolia (testnet)',
    rpcUrl: 'https://ethereum-sepolia-rpc.publicnode.com',
    explorerUrl: 'https://sepolia.etherscan.io',
    icon: Icons.science_outlined,
    color: Color(0xFFB388FF),
    isTestnet: true,
  ),
];

/// Solana clusters surfaced in the cluster picker.
const List<SolanaCluster> kSolanaClusters = <SolanaCluster>[
  SolanaCluster(
    id: 'mainnet-beta',
    name: 'Solana Mainnet',
    rpcUrl: 'https://api.mainnet-beta.solana.com',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xFF9945FF),
  ),
  SolanaCluster(
    id: 'devnet',
    name: 'Solana Devnet',
    rpcUrl: 'https://api.devnet.solana.com',
    icon: Icons.cloud_outlined,
    color: Color(0xFF14F195),
    isTestnet: true,
  ),
];

/// Lookup helper used by the AppBar chip / settings picker. Falls back to
/// the mainnet entry when the chain id is unknown so we still render a
/// recognisable label instead of an empty string.
EvmChain evmChainById(int chainId) {
  for (final chain in kEvmChains) {
    if (chain.chainId == chainId) return chain;
  }
  return kEvmChains.first;
}

SolanaCluster solanaClusterById(String id) {
  for (final cluster in kSolanaClusters) {
    if (cluster.id == id) return cluster;
  }
  return kSolanaClusters.first;
}
