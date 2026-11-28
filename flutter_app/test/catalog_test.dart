import 'package:flutter_test/flutter_test.dart';
import 'package:gearlab/domain/catalog.dart';

void main() {
  test('catalog contains the original and back-view templates', () {
    final ids = CameraCatalog.all.map((template) => template.id).toSet();
    expect(CameraCatalog.all.length, 37);
    expect(ids.length, CameraCatalog.all.length);
    expect(ids, contains('ricoh-gr4'));
    expect(ids, contains('canon-eos-6d'));
    expect(ids, contains('fujifilm-x-h2'));
    expect(ids, contains('nikon-z30'));
    expect(ids, contains('nikon-z5ii-c'));
    expect(ids, contains('sony-zv-e10'));
    expect(ids, contains('lumix-s5ii'));
  });

  test('every template has normalized screen bounds and a valid aspect', () {
    for (final template in CameraCatalog.all) {
      expect(template.aspect, greaterThan(0), reason: template.id);
      expect(template.screen.left, inInclusiveRange(0, 1), reason: template.id);
      expect(template.screen.top, inInclusiveRange(0, 1), reason: template.id);
      expect(
        template.screen.right,
        inInclusiveRange(0, 1),
        reason: template.id,
      );
      expect(
        template.screen.bottom,
        inInclusiveRange(0, 1),
        reason: template.id,
      );
      expect(template.screen.width, greaterThan(0), reason: template.id);
      expect(template.screen.height, greaterThan(0), reason: template.id);
      expect(
        template.asset,
        startsWith('assets/cameras/'),
        reason: template.id,
      );
    }
  });

  test('α7C II and S9 keep the original edge-to-edge screen', () {
    for (final id in <String>[
      'sony-a7c2',
      'sony-a7c2-s',
      'lumix-s9',
      'lumix-s9-s',
    ]) {
      expect(CameraCatalog.find(id).screenInset, 0, reason: id);
    }
    expect(CameraCatalog.find('nikon-z5ii-c').screenInset, 0.06);
  });
}
