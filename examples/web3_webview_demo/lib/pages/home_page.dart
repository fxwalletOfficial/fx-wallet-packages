import 'package:flutter/material.dart';

import 'package:web3_webview_demo/data/dapps.dart';
import 'package:web3_webview_demo/pages/browser_page.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

/// Bookmark-grid landing page.
///
/// The bookmark grid is filled in by Phase 2 — at the skeleton stage the
/// page only proves that the routing wiring is in place: the `Settings`
/// destination round-trips, the active-account chip reads from
/// [WalletState] (and would rebuild on `notifyListeners()`), and the
/// catalogue groupings come from [groupedDApps] so subsequent phases just
/// have to render the cards.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = WalletStateScope.of(context);
    final groups = groupedDApps();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Web3 WebView Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActiveIdentityCard(wallet: wallet),
          const SizedBox(height: 16),
          for (final entry in groups.entries) ...[
            Text(
              entry.key.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _CategoryRow(entries: entry.value),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _ActiveIdentityCard extends StatelessWidget {
  const _ActiveIdentityCard({required this.wallet});

  final WalletState wallet;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(wallet.evmChain.icon, color: wallet.evmChain.color),
                const SizedBox(width: 8),
                Text(wallet.evmChain.name,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(wallet.evmAccount.label,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_short(wallet.evmAccount.evmAddress)} · '
              'sol:${_short(wallet.solanaAccount.solanaAddress)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _short(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.entries});

  final List<DAppEntry> entries;

  @override
  Widget build(BuildContext context) {
    // Two-column grid; the bookmark tiles get their full rendering in
    // Phase 2, but skeleton stage exercises the data wiring + navigation
    // hand-off to the browser page.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          color: entry.color.withValues(alpha: 0.08),
          child: InkWell(
            onTap: () => Navigator.of(context).pushNamed(
              '/browser',
              arguments: BrowserPageArgs(url: entry.url, title: entry.name),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(entry.icon, color: entry.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.name,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(entry.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

