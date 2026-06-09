import 'package:flutter/widgets.dart';

/// A single entry in the "recently opened" list.
@immutable
class RecentVisit {
  final String url;
  final String title;
  final DateTime visitedAt;

  const RecentVisit({
    required this.url,
    required this.title,
    required this.visitedAt,
  });
}

/// In-memory most-recently-used list of opened DApps.
///
/// Kept in memory only (no `shared_preferences` dependency) so the demo
/// stays free of platform-channel setup — the list resets on restart,
/// which is fine for a within-session "jump back to what I was testing"
/// affordance. If persistence is ever wanted, swapping the backing store
/// here is the only change needed; the `*Scope` contract stays the same.
class RecentVisits extends ChangeNotifier {
  RecentVisits({this.capacity = 8});

  final int capacity;
  final List<RecentVisit> _visits = <RecentVisit>[];

  /// Most-recent-first snapshot.
  List<RecentVisit> get visits => List.unmodifiable(_visits);

  bool get isEmpty => _visits.isEmpty;

  /// Record a visit. If the URL is already present it is moved to the
  /// front (and its title refreshed) rather than duplicated, so the list
  /// behaves like a browser history MRU.
  void record({required String url, required String title}) {
    final normalized = url.trim();
    if (normalized.isEmpty) return;

    _visits.removeWhere((v) => v.url == normalized);
    _visits.insert(
      0,
      RecentVisit(
        url: normalized,
        title: title.trim().isEmpty ? normalized : title.trim(),
        visitedAt: DateTime.now(),
      ),
    );
    while (_visits.length > capacity) {
      _visits.removeLast();
    }
    notifyListeners();
  }

  void clear() {
    if (_visits.isEmpty) return;
    _visits.clear();
    notifyListeners();
  }
}

/// Inherited handle for [RecentVisits], matching the other service scopes.
class RecentVisitsScope extends InheritedNotifier<RecentVisits> {
  const RecentVisitsScope({
    super.key,
    required RecentVisits super.notifier,
    required super.child,
  });

  static RecentVisits of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RecentVisitsScope>();
    assert(scope != null, 'RecentVisitsScope missing in widget tree');
    return scope!.notifier!;
  }

  static RecentVisits read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<RecentVisitsScope>();
    assert(scope != null, 'RecentVisitsScope missing in widget tree');
    return scope!.notifier!;
  }
}
