import 'package:path/path.dart' as p;

/// File-system safe export naming, shared by the controller and tests.
///
/// Export names are part of the product contract:
/// `GearLab_<index>_<photo>_<camera>.<ext>`, with `_2`, `_3` suffixes when a
/// name already exists. Keep this logic independent of Flutter so it can be
/// unit tested without a widget binding.
String safeFilePart(String value) {
  final String cleaned = value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.isEmpty ? 'photo' : cleaned;
}

String exportFileStem({
  required int index,
  required String photoName,
  required String cameraModel,
}) {
  final String base = safeFilePart(p.basenameWithoutExtension(photoName));
  final String model = safeFilePart(cameraModel.replaceAll(' ', ''));
  return 'GearLab_${(index + 1).toString().padLeft(2, '0')}_${base}_$model';
}

String uniqueExportFileName({
  required String stem,
  required String extension,
  required bool Function(String fileName) exists,
}) {
  String candidate = '$stem.$extension';
  int duplicate = 2;
  while (exists(candidate)) {
    candidate = '${stem}_$duplicate.$extension';
    duplicate += 1;
  }
  return candidate;
}
