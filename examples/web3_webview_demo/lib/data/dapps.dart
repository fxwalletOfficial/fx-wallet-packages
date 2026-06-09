import 'package:flutter/material.dart';

/// Category buckets used to group the bookmark grid.
enum DAppCategory {
  defi('DeFi'),
  nft('NFT'),
  solana('Solana'),
  tools('Tools & tests');

  final String label;
  const DAppCategory(this.label);
}

/// One bookmark in the home screen's dApp grid.
///
/// The icon is a [Material](https://fonts.google.com/icons) glyph rather
/// than a remote PNG so the demo stays dependency-free and offline-friendly;
/// the colour roughly matches each project's brand so the grid still looks
/// distinct at a glance.
@immutable
class DAppEntry {
  final String name;
  final String url;
  final DAppCategory category;
  final IconData icon;
  final Color color;

  /// One-line blurb shown under the tile.
  final String description;

  const DAppEntry({
    required this.name,
    required this.url,
    required this.category,
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// Curated bookmark catalogue. Intentionally compact — the goal is wide
/// coverage of the bridge surface (connect / sign / send / chain switch /
/// Solana wallet-standard) rather than an exhaustive dApp directory.
const List<DAppEntry> kDAppCatalog = <DAppEntry>[
  // ── DeFi ───────────────────────────────────────────────────────────
  DAppEntry(
    name: 'Uniswap',
    url: 'https://app.uniswap.org',
    category: DAppCategory.defi,
    icon: Icons.currency_exchange,
    color: Color(0xFFFF007A),
    description: 'EVM DEX — connect / swap / EIP-712 permit',
  ),
  DAppEntry(
    name: 'Aave',
    url: 'https://app.aave.com',
    category: DAppCategory.defi,
    icon: Icons.savings_outlined,
    color: Color(0xFFB6509E),
    description: 'Lending & borrowing on EVM L1 + L2s',
  ),
  DAppEntry(
    name: '1inch',
    url: 'https://app.1inch.io',
    category: DAppCategory.defi,
    icon: Icons.compare_arrows,
    color: Color(0xFF1B314F),
    description: 'EVM DEX aggregator',
  ),
  DAppEntry(
    name: 'Curve',
    url: 'https://curve.fi',
    category: DAppCategory.defi,
    icon: Icons.show_chart,
    color: Color(0xFF40649F),
    description: 'Stable-asset AMM',
  ),

  // ── NFT ────────────────────────────────────────────────────────────
  DAppEntry(
    name: 'OpenSea',
    url: 'https://opensea.io',
    category: DAppCategory.nft,
    icon: Icons.water,
    color: Color(0xFF2081E2),
    description: 'EVM NFT marketplace — personal_sign login',
  ),
  DAppEntry(
    name: 'Blur',
    url: 'https://blur.io',
    category: DAppCategory.nft,
    icon: Icons.blur_on_outlined,
    color: Color(0xFFFF8700),
    description: 'NFT marketplace — heavy signTypedData usage',
  ),

  // ── Solana ─────────────────────────────────────────────────────────
  DAppEntry(
    name: 'Jupiter',
    url: 'https://jup.ag',
    category: DAppCategory.solana,
    icon: Icons.public,
    color: Color(0xFFCFB668),
    description: 'Solana DEX — wallet-standard connect + signTransaction',
  ),
  DAppEntry(
    name: 'Magic Eden',
    url: 'https://magiceden.io',
    category: DAppCategory.solana,
    icon: Icons.castle_outlined,
    color: Color(0xFFE42575),
    description: 'NFT marketplace — Solana + EVM, signMessage login',
  ),
  DAppEntry(
    name: 'Drift',
    url: 'https://app.drift.trade',
    category: DAppCategory.solana,
    icon: Icons.timeline,
    color: Color(0xFF13C2C2),
    description: 'Solana perpetuals — multi-sign batched transactions',
  ),

  // ── Tools & test pages ────────────────────────────────────────────
  DAppEntry(
    name: 'MetaMask test dapp',
    url: 'https://metamask.github.io/test-dapp/',
    category: DAppCategory.tools,
    icon: Icons.bug_report_outlined,
    color: Color(0xFFF6851B),
    description: 'Every EIP-1193 method in one page — best for regression',
  ),
  DAppEntry(
    name: 'EIP-1193 test',
    url: 'https://eip1193.org/test',
    category: DAppCategory.tools,
    icon: Icons.fact_check_outlined,
    color: Color(0xFF455A64),
    description: 'Read-only provider-spec compliance checker',
  ),
  DAppEntry(
    name: 'WalletConnect debug',
    url: 'https://react-wallet.walletconnect.com',
    category: DAppCategory.tools,
    icon: Icons.qr_code_2_outlined,
    color: Color(0xFF3396FF),
    description: 'WC v2 sample — exercises eth_sign / sendTransaction paths',
  ),
];

/// Convenience grouping for the home grid.
Map<DAppCategory, List<DAppEntry>> groupedDApps() {
  final result = <DAppCategory, List<DAppEntry>>{};
  for (final entry in kDAppCatalog) {
    result.putIfAbsent(entry.category, () => <DAppEntry>[]).add(entry);
  }
  return result;
}
