import 'package:flutter_test/flutter_test.dart';
import 'package:gearlab/domain/catalog.dart';
import 'package:gearlab/domain/models.dart';
import 'package:gearlab/presentation/editor/camera_search.dart';

void main() {
  // Stand-in for the localized brand aliases the panel passes in.
  const Map<String, String> aliases = <String, String>{
    'FUJIFILM': '富士 富士胶片',
    'NIKON': '尼康',
    'CANON': '佳能',
    'SONY': '索尼',
    'LUMIX': '松下',
    'RICOH': '理光',
  };

  List<String> idsFor(String query) =>
      searchCameras(CameraCatalog.all, query, aliases: aliases)
          .map((CameraTemplate template) => template.id)
          .toList();

  test('an empty query keeps every body', () {
    expect(
      searchCameras(CameraCatalog.all, '').length,
      CameraCatalog.all.length,
    );
    expect(
      searchCameras(CameraCatalog.all, '   ').length,
      CameraCatalog.all.length,
    );
  });

  test('plain substrings still match', () {
    expect(idsFor('x100'), contains('fujifilm-x100vi'));
    expect(idsFor('SONY'), everyElement(startsWith('sony-')));
  });

  test('tokens may be split or reordered', () {
    expect(idsFor('fuji 100'), contains('fujifilm-x100vi'));
    expect(idsFor('100 fuji'), contains('fujifilm-x100vi'));
  });

  test('chars may match without being adjacent', () {
    expect(idsFor('fx100'), contains('fujifilm-x100vi'));
  });

  test('chinese brand names reach the latin brand', () {
    expect(idsFor('富士x100'), contains('fujifilm-x100vi'));
    expect(idsFor('索尼'), everyElement(startsWith('sony-')));
    expect(idsFor('尼康'), everyElement(startsWith('nikon-')));
    expect(idsFor('理光'), everyElement(startsWith('ricoh-')));
  });

  test('a query that matches nothing returns nothing', () {
    expect(idsFor('zzzz'), isEmpty);
    expect(idsFor('leica'), isEmpty);
  });

  test('results keep catalog order and never duplicate', () {
    final List<String> ids = idsFor('x');
    final List<String> catalogIds = CameraCatalog.all
        .map((CameraTemplate template) => template.id)
        .where(ids.contains)
        .toList();
    expect(ids, catalogIds);
    expect(ids.toSet().length, ids.length);
  });
}
