// `RadioListTile` here intentionally uses the pre-3.32 `groupValue` /
// `onChanged` flow. Phase 6 of the demo plan rebuilds this whole screen
// around the new `RadioGroup` widget along with the auto-approve / real-
// broadcast switches, so this scoped ignore stays in lock-step with the
// rewrite rather than churning the file twice.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:web3_webview_demo/data/chains.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

/// Skeleton settings page.
///
/// Phase 6 fills in the auto-approve / real-broadcast toggles plus the
/// bridge-log viewer; today the page just exposes the picker for the
/// active EVM account / chain so the rest of the demo has a way to
/// exercise the `WalletState` listeners and prove the `InheritedNotifier`
/// rebuild path works.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = WalletStateScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Active EVM account'),
          for (var i = 0; i < kDemoAccounts.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: wallet.evmAccountIndex,
              onChanged: (value) {
                if (value != null) wallet.evmAccountIndex = value;
              },
              title: Text(kDemoAccounts[i].label),
              subtitle: Text(kDemoAccounts[i].evmAddress,
                  style: const TextStyle(fontFamily: 'monospace')),
            ),

          const _SectionHeader('Active EVM chain'),
          for (final chain in kEvmChains)
            RadioListTile<int>(
              value: chain.chainId,
              groupValue: wallet.evmChainId,
              onChanged: (value) {
                if (value != null) wallet.evmChainId = value;
              },
              title: Row(
                children: [
                  Icon(chain.icon, color: chain.color, size: 18),
                  const SizedBox(width: 8),
                  Text(chain.name),
                  const Spacer(),
                  if (chain.isTestnet)
                    const Chip(
                      label: Text('testnet'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              subtitle: Text('chainId ${chain.chainId} · ${chain.symbol}'),
            ),

          const _SectionHeader('Active Solana account'),
          for (var i = 0; i < kDemoAccounts.length; i++)
            RadioListTile<int>(
              value: i,
              groupValue: wallet.solanaAccountIndex,
              onChanged: (value) {
                if (value != null) wallet.solanaAccountIndex = value;
              },
              title: Text(kDemoAccounts[i].label),
              subtitle: Text(kDemoAccounts[i].solanaAddress,
                  style: const TextStyle(fontFamily: 'monospace')),
            ),

          const _SectionHeader('Active Solana cluster'),
          for (final cluster in kSolanaClusters)
            RadioListTile<String>(
              value: cluster.id,
              groupValue: wallet.solanaClusterId,
              onChanged: (value) {
                if (value != null) wallet.solanaClusterId = value;
              },
              title: Row(
                children: [
                  Icon(cluster.icon, color: cluster.color, size: 18),
                  const SizedBox(width: 8),
                  Text(cluster.name),
                  const Spacer(),
                  if (cluster.isTestnet)
                    const Chip(
                      label: Text('devnet'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

          const Divider(),
          const _PendingSection(
            label: 'Auto-approve read-only methods',
            description:
                'Phase 6 — toggles whether eth_accounts / eth_chainId / '
                'solana_account resolve without a confirmation sheet.',
          ),
          const _PendingSection(
            label: 'Broadcast transactions over RPC',
            description:
                'Phase 6 — when enabled (testnets only), eth_sendTransaction '
                'and Solana signAndSendTransaction will be broadcast through '
                "the active chain's public endpoint instead of returning a "
                'mock tx hash.',
          ),
          const _PendingSection(
            label: 'Bridge call log',
            description:
                'Phase 3+ — every request the WebView bridge issues plus '
                'the wallet response will land here so you can reproduce a '
                'failed DApp interaction by replaying the JSON.',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              )),
    );
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.construction, color: Colors.grey),
      title: Text(label, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(description,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      enabled: false,
    );
  }
}
