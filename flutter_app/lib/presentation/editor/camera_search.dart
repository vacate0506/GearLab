import '../../domain/models.dart';

// Fuzzy camera-body search used by the full template panel.
//
// Matching is deliberately forgiving: the query is split into tokens, each
// token has to appear in the brand/model text in order (adjacent or not), and
// localized brand names (see [searchCameras]) map onto the latin ones the
// templates carry. So "x100", "fuji 100" and "fx100" all reach FUJIFILM X100VI.

/// Returns [source] filtered by [query], preserving the original order.
///
/// [aliases] maps a template brand onto extra searchable names in the current
/// locale, so a Chinese UI can also find SONY by typing 索尼.
List<CameraTemplate> searchCameras(
  Iterable<CameraTemplate> source,
  String query, {
  Map<String, String> aliases = const <String, String>{},
}) {
  final List<String> tokens = _tokenize(query);
  if (tokens.isEmpty) return source.toList(growable: false);
  return source
      .where((CameraTemplate template) => _matches(template, tokens, aliases))
      .toList(growable: false);
}

/// Splits the query on spaces, punctuation and CJK/latin boundaries, so both
/// "fuji 100" and "富士x100" become separate tokens.
List<String> _tokenize(String raw) {
  final List<String> tokens = <String>[];
  final StringBuffer buffer = StringBuffer();
  bool? cjk;
  void flush() {
    final String value = _normalize(buffer.toString());
    if (value.isNotEmpty) tokens.add(value);
    buffer.clear();
  }

  for (final int rune in raw.toLowerCase().runes) {
    final String char = String.fromCharCode(rune);
    if (char.trim().isEmpty || '-_·/.,+*'.contains(char)) {
      flush();
      cjk = null;
      continue;
    }
    final bool isCjk = rune >= 0x4E00 && rune <= 0x9FFF;
    if (cjk != null && cjk != isCjk) flush();
    cjk = isCjk;
    buffer.write(char);
  }
  flush();
  return tokens;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[\s\-_·/.,+*]'), '');

bool _matches(
  CameraTemplate template,
  List<String> tokens,
  Map<String, String> aliases,
) {
  final String haystack = _normalize(
    '${template.brand}${template.model}${aliases[template.brand] ?? ''}',
  );
  for (final String token in tokens) {
    if (haystack.contains(token)) continue;
    if (_isSubsequence(haystack, token)) continue;
    return false;
  }
  return true;
}

/// True when [needle] appears inside [haystack] in order but not adjacently,
/// so "fx100" still finds FUJIFILM X100VI.
bool _isSubsequence(String haystack, String needle) {
  int index = 0;
  for (int i = 0; i < haystack.length && index < needle.length; i++) {
    if (haystack[i] == needle[index]) index++;
  }
  return index == needle.length;
}
