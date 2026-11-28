import 'package:flutter_test/flutter_test.dart';
import 'package:gearlab/domain/export_naming.dart';

void main() {
  test('export stem keeps the product naming contract', () {
    expect(
      exportFileStem(
        index: 0,
        photoName: 'DSC_2441_Gold_200_Portra_Endura3.jpg',
        cameraModel: 'Fujifilm X-M5',
      ),
      'GearLab_01_DSC_2441_Gold_200_Portra_Endura3_FujifilmX-M5',
    );
    expect(
      exportFileStem(index: 9, photoName: 'a.png', cameraModel: 'Lumix S9'),
      'GearLab_10_a_LumixS9',
    );
  });

  test('illegal path characters are replaced and empty names fall back', () {
    expect(safeFilePart('a/b:c*?'), 'a_b_c__');
    expect(safeFilePart('   '), 'photo');
    expect(
      exportFileStem(index: 2, photoName: '', cameraModel: ''),
      'GearLab_03_photo_photo',
    );
  });

  test('duplicate names get a stable numeric suffix', () {
    final Set<String> existing = <String>{
      'GearLab_01_a_S9.jpg',
      'GearLab_01_a_S9_2.jpg',
    };
    expect(
      uniqueExportFileName(
        stem: 'GearLab_01_a_S9',
        extension: 'jpg',
        exists: existing.contains,
      ),
      'GearLab_01_a_S9_3.jpg',
    );
  });
}
