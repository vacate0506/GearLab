/// Recently used camera bodies, newest first.
///
/// A body only counts as "used" once an export containing it finished — merely
/// previewing a template must not push it to the front of the 最近 list.
library;

/// How many bodies the 最近 filter keeps. Anything older falls off the end.
const int kRecentCameraLimit = 10;

/// Merges [used] (oldest first inside the batch) to the front of [current]
/// and trims the tail so the list never exceeds [kRecentCameraLimit].
///
/// Duplicates inside [used] collapse, and ids already in [current] move to the
/// front instead of appearing twice.
List<String> mergeRecentCameras(List<String> current, Iterable<String> used) {
  final List<String> ordered = <String>[];
  for (final String id in used) {
    if (!ordered.contains(id)) ordered.add(id);
  }
  if (ordered.isEmpty) return current;
  final Set<String> added = ordered.toSet();
  return <String>[
    ...ordered,
    ...current.where((String id) => !added.contains(id)),
  ].take(kRecentCameraLimit).toList(growable: false);
}
