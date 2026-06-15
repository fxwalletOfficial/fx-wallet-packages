import 'package:flutter/material.dart';

import 'package:web3_webview_demo/data/dapps.dart';

/// Two-column bookmark grid for one category. Pulled out of the home page
/// so Phase 2's search filtering can reuse the same tile rendering for
/// both the grouped and the flat (search-results) layouts.
class DAppBookmarkGrid extends StatelessWidget {
  const DAppBookmarkGrid({
    super.key,
    required this.entries,
    required this.onTap,
  });

  final List<DAppEntry> entries;
  final void Function(DAppEntry entry) onTap;

  @override
  Widget build(BuildContext context) {
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
      itemBuilder: (context, index) => DAppBookmarkTile(
        entry: entries[index],
        onTap: () => onTap(entries[index]),
      ),
    );
  }
}

/// One bookmark card.
class DAppBookmarkTile extends StatelessWidget {
  const DAppBookmarkTile({
    super.key,
    required this.entry,
    required this.onTap,
  });

  final DAppEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: entry.color.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(entry.icon, color: entry.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
  }
}

/// Case-insensitive substring filter over name + description + host.
/// Lives next to the grid so the home page and any future search surface
/// share the exact same matching rules.
List<DAppEntry> filterDApps(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kDAppCatalog;
  return kDAppCatalog.where((entry) {
    final host = Uri.tryParse(entry.url)?.host ?? '';
    return entry.name.toLowerCase().contains(q) ||
        entry.description.toLowerCase().contains(q) ||
        host.toLowerCase().contains(q) ||
        entry.category.label.toLowerCase().contains(q);
  }).toList();
}
