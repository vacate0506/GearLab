import 'package:gearlab/presentation/editor/recent_cameras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records the exported body at the front', () {
    expect(mergeRecentCameras(const <String>[], <String>['a']), <String>['a']);
  });

  test('moves an existing body back to the front instead of duplicating it', () {
    final List<String> merged = mergeRecentCameras(
      const <String>['a', 'b', 'c'],
      <String>['c'],
    );
    expect(merged, <String>['c', 'a', 'b']);
  });

  test('keeps the batch order and drops duplicates inside the batch', () {
    final List<String> merged = mergeRecentCameras(
      const <String>['z'],
      <String>['a', 'b', 'a'],
    );
    expect(merged, <String>['a', 'b', 'z']);
  });

  test('keeps at most ten bodies, dropping the oldest first', () {
    final List<String> existing = List<String>.generate(
      10,
      (int i) => 'c$i',
    );
    final List<String> merged = mergeRecentCameras(existing, <String>['new']);
    expect(merged.length, kRecentCameraLimit);
    expect(merged.first, 'new');
    expect(merged.contains('c9'), isFalse);
    expect(merged.contains('c8'), isTrue);
  });

  test('leaves the list untouched when nothing was exported', () {
    const List<String> existing = <String>['a', 'b'];
    expect(mergeRecentCameras(existing, const <String>[]), existing);
  });
}
