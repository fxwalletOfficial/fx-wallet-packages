import 'package:flutter/material.dart';

import 'package:web3_webview_demo/data/dapps.dart';
import 'package:web3_webview_demo/data/url_utils.dart';
import 'package:web3_webview_demo/pages/browser_page.dart';
import 'package:web3_webview_demo/services/recent_visits.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';
import 'package:web3_webview_demo/widgets/dapp_bookmark_grid.dart';

/// Bookmark-grid landing page.
///
/// Phase 2 adds the custom-URL bar, live search filtering, and a
/// recently-opened row. Tapping any bookmark / recent / typed URL routes
/// to the [BrowserPage] and records the visit in [RecentVisits].
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openUrl(String url, String title) {
    RecentVisitsScope.read(context).record(url: url, title: title);
    Navigator.of(context).pushNamed(
      '/browser',
      arguments: BrowserPageArgs(url: url, title: title),
    );
  }

  void _submitCustomUrl() {
    final normalized = normalizeDAppUrl(_urlController.text);
    if (normalized == null) {
      setState(() => _urlError = 'Enter a valid http(s) URL or host');
      return;
    }
    setState(() => _urlError = null);
    _openUrl(normalized, hostLabel(normalized));
  }

  @override
  Widget build(BuildContext context) {
    final wallet = WalletStateScope.of(context);
    final searching = _searchQuery.trim().isNotEmpty;

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
          _CustomUrlBar(
            controller: _urlController,
            errorText: _urlError,
            onSubmit: _submitCustomUrl,
          ),
          const SizedBox(height: 12),
          _SearchField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 16),
          if (!searching) ...[
            _RecentRow(onOpen: _openUrl),
            ..._buildGroupedSections(),
          ] else
            _buildSearchResults(),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSections() {
    final groups = groupedDApps();
    final widgets = <Widget>[];
    for (final entry in groups.entries) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(entry.key.label,
            style: Theme.of(context).textTheme.titleMedium),
      ));
      widgets.add(DAppBookmarkGrid(
        entries: entry.value,
        onTap: (e) => _openUrl(e.url, e.name),
      ));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }

  Widget _buildSearchResults() {
    final results = filterDApps(_searchQuery);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('No dApps match "${_searchQuery.trim()}"',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('${results.length} result(s)',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        DAppBookmarkGrid(
          entries: results,
          onTap: (e) => _openUrl(e.url, e.name),
        ),
      ],
    );
  }
}

class _CustomUrlBar extends StatelessWidget {
  const _CustomUrlBar({
    required this.controller,
    required this.errorText,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.url,
      autocorrect: false,
      textInputAction: TextInputAction.go,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        labelText: 'Open a custom URL',
        hintText: 'app.uniswap.org  or  https://…',
        errorText: errorText,
        prefixIcon: const Icon(Icons.public),
        suffixIcon: IconButton(
          icon: const Icon(Icons.arrow_forward),
          tooltip: 'Open',
          onPressed: onSubmit,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Search bookmarks',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({required this.onOpen});

  final void Function(String url, String title) onOpen;

  @override
  Widget build(BuildContext context) {
    final recent = RecentVisitsScope.of(context);
    if (recent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: recent.clear,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recent.visits.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final visit = recent.visits[index];
              return ActionChip(
                avatar: const Icon(Icons.history, size: 18),
                label: Text(visit.title),
                onPressed: () => onOpen(visit.url, visit.title),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
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
