/// Normalises whatever the user typed in the custom-URL bar into a
/// loadable `https://` (or `http://`) URL, or returns `null` if the input
/// can't be coerced into something sensible.
///
/// Rules:
///   * blank input → `null`
///   * already has an http/https scheme → trimmed as-is
///   * has some *other* scheme (ftp:, javascript:, …) → rejected (`null`)
///     so the demo never hands the WebView a non-web URL
///   * looks like a bare host / host+path (`uniswap.org`,
///     `app.uniswap.org/swap`) → prefixed with `https://`
///   * a single word with no dot (`uniswap`) → treated as a search-ish
///     host is *not* assumed; returns `null` so the caller can show an
///     error rather than navigate somewhere surprising
String? normalizeDAppUrl(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;

  final lower = input.toLowerCase();

  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    final uri = Uri.tryParse(input);
    if (uri == null || uri.host.isEmpty) return null;
    return input;
  }

  // Reject any other explicit scheme — only web URLs belong in the WebView.
  final schemeMatch = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*:').firstMatch(input);
  if (schemeMatch != null) return null;

  // Bare host / host+path. Require at least one dot so we don't navigate
  // to single-word junk; the host part must parse cleanly.
  if (!input.contains('.')) return null;

  final candidate = 'https://$input';
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) return null;
  return candidate;
}

/// Best-effort display label for a URL — the host without a leading
/// `www.`, used as the initial title before the page reports its own.
String hostLabel(String url) {
  final uri = Uri.tryParse(url);
  final host = uri?.host ?? url;
  return host.startsWith('www.') ? host.substring(4) : host;
}
