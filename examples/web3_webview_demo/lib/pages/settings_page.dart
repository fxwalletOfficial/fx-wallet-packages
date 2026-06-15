// `RadioListTile` here intentionally uses the pre-3.32 `groupValue` /
// `onChanged` flow rather than the newer `RadioGroup` ancestor.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:web3_webview_demo/data/chains.dart';
import 'package:web3_webview_demo/services/bridge_log.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

/// Settings: active EVM / Solana account + chain pickers, the behaviour
/// toggles (auto-approve reads, real broadcast) and the bridge-log entry.
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
          const _SectionHeader('Behaviour'),
          SwitchListTile(
            value: wallet.autoApproveReadMethods,
            onChanged: (v) => wallet.autoApproveReadMethods = v,
            title: const Text('Auto-approve read-only methods'),
            subtitle: const Text(
                'eth_accounts / eth_chainId / solana_account resolve '
                'without a confirmation sheet.'),
          ),
          SwitchListTile(
            value: wallet.realBroadcast,
            onChanged: (v) => wallet.realBroadcast = v,
            title: const Text('Broadcast transactions over RPC'),
            isThreeLine: true,
            subtitle: Text(
              wallet.realBroadcast && !wallet.evmChain.isTestnet
                  ? '⚠️ Active chain (${wallet.evmChain.name}) is not a '
                      'testnet. These demo keys hold no funds, so a real '
                      'broadcast will just fail with insufficient balance.'
                  : 'When on, eth_sendTransaction is signed and submitted '
                      'through the active chain\'s RPC instead of returning '
                      'a mock hash. Use a testnet.',
            ),
          ),

          const Divider(),
          const _SectionHeader('Diagnostics'),
          _BridgeLogTile(),
        ],
      ),
    );
  }
}

/// Bridge-log entry with a live count badge, navigating to the full
/// log viewer.
class _BridgeLogTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final log = BridgeLogScope.of(context);
    return ListTile(
      leading: const Icon(Icons.receipt_long_outlined),
      title: const Text('Bridge call log'),
      subtitle: const Text(
          'Every request the WebView bridge issues, with the wallet '
          'response — replay a failed DApp interaction from the JSON.'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (log.entries.isNotEmpty)
            Chip(
              label: Text('${log.entries.length}'),
              visualDensity: VisualDensity.compact,
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.of(context).pushNamed('/log'),
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

