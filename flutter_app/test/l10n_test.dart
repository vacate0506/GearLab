import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String path) {
  final Map<String, dynamic> json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return json.keys.where((String key) => !key.startsWith('@')).toSet();
}

void main() {
  test('zh/en ARB files expose the same message keys', () {
    final Set<String> zh = _keys('lib/l10n/app_zh.arb');
    final Set<String> en = _keys('lib/l10n/app_en.arb');
    expect(zh.length, greaterThan(100));
    expect(zh.difference(en), isEmpty);
    expect(en.difference(zh), isEmpty);
  });

  test('runtime layers contain no hardcoded CJK copy', () {
    final RegExp cjk = RegExp(r'[\u4e00-\u9fff]');
    final List<String> offenders = <String>[];
    for (final String root in <String>[
      'lib/app',
      'lib/design',
      'lib/domain',
      'lib/platform',
      'lib/presentation',
    ]) {
      for (final FileSystemEntity entity
          in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final List<String> lines = entity.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i].trimLeft();
          if (line.startsWith('//')) continue;
          if (cjk.hasMatch(lines[i])) {
            offenders.add('${entity.path}:${i + 1}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
