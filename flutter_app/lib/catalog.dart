import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'models.dart';

class CameraCatalog {
  static const List<CameraTemplate> all = <CameraTemplate>[
    CameraTemplate(
      id: 'ricoh-gr4',
      asset: 'assets/cameras/ricoh-gr4.png',
      brand: 'RICOH',
      model: 'GR IV',
      displayName: 'Ricoh GR IV',
      aspect: 855 / 502,
      screen: Rect.fromLTWH(0.051990, 0.186895, 0.642220, 0.715795),
    ),
    CameraTemplate(
      id: 'fujifilm-x100vi',
      asset: 'assets/cameras/fujifilm-x100vi-silver.png',
      brand: 'FUJIFILM',
      model: 'X100VI',
      displayName: 'Fujifilm X100VI',
      aspect: 632 / 362,
      screen: Rect.fromLTWH(0.1076, 0.3011, 0.5301, 0.6215),
    ),
    CameraTemplate(
      id: 'fujifilm-xm5',
      asset: 'assets/cameras/fujifilm-xm5-silver.png',
      brand: 'FUJIFILM',
      model: 'X-M5',
      displayName: 'Fujifilm X-M5',
      aspect: 632 / 367,
      screen: Rect.fromLTWH(0.1277, 0.2343, 0.6044, 0.6894),
    ),
    CameraTemplate(
      id: 'nikon-z5ii',
      asset: 'assets/cameras/nikon-z5ii.png',
      brand: 'NIKON',
      model: 'Z5II',
      displayName: 'Nikon Z5II',
      aspect: 678 / 494,
      screen: Rect.fromLTWH(0.1327, 0.4251, 0.5383, 0.5020),
    ),
    CameraTemplate(
      id: 'nikon-z6iii',
      asset: 'assets/cameras/nikon-z6iii.png',
      brand: 'NIKON',
      model: 'Z6III',
      displayName: 'Nikon Z6III',
      aspect: 678 / 481,
      screen: Rect.fromLTWH(0.1490, 0.4595, 0.4985, 0.4449),
    ),
    CameraTemplate(
      id: 'nikon-z8',
      asset: 'assets/cameras/nikon-z8.png',
      brand: 'NIKON',
      model: 'Z8',
      displayName: 'Nikon Z8',
      aspect: 586 / 459,
      screen: Rect.fromLTWH(0.1134, 0.4227, 0.5573, 0.5054),
    ),
    CameraTemplate(
      id: 'nikon-zr',
      asset: 'assets/cameras/nikon-zr.png',
      brand: 'NIKON',
      model: 'ZR',
      displayName: 'Nikon ZR',
      aspect: 678 / 435,
      screen: Rect.fromLTWH(0.1372, 0.1563, 0.6460, 0.7379),
    ),
    CameraTemplate(
      id: 'sony-a7c2',
      asset: 'assets/cameras/sony-a7c2.png',
      brand: 'SONY',
      model: 'α7C II',
      displayName: 'Sony α7C II',
      aspect: 518 / 290,
      screen: Rect.fromLTWH(0.1795, 0.3552, 0.4517, 0.5448),
    ),
    CameraTemplate(
      id: 'sony-a7c2-s',
      asset: 'assets/cameras/sony-a7c2-silver.png',
      brand: 'SONY',
      model: 'α7C II',
      displayName: 'Sony α7C II',
      aspect: 632 / 353,
      screen: Rect.fromLTWH(0.1804, 0.3569, 0.4525, 0.5382),
    ),
    CameraTemplate(
      id: 'lumix-s9',
      asset: 'assets/cameras/lumix-s9.png',
      brand: 'LUMIX',
      model: 'S9',
      displayName: 'Lumix S9',
      aspect: 624 / 359,
      screen: Rect.fromLTWH(0.1827, 0.3593, 0.4679, 0.5432),
    ),
    CameraTemplate(
      id: 'lumix-s9-s',
      asset: 'assets/cameras/lumix-s9-silver.png',
      brand: 'LUMIX',
      model: 'S9',
      displayName: 'Lumix S9',
      aspect: 1704 / 981,
      screen: Rect.fromLTWH(0.1837, 0.3588, 0.4654, 0.5423),
    ),
  ];

  static final Map<String, ui.Image> images = <String, ui.Image>{};

  static CameraTemplate find(String id) {
    for (final CameraTemplate template in all) {
      if (template.id == id) return template;
    }
    return all.first;
  }

  static Future<void> load() async {
    for (final CameraTemplate template in all) {
      if (images.containsKey(template.id)) continue;
      final ByteData data = await rootBundle.load(template.asset);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      images[template.id] = frame.image;
      codec.dispose();
    }
  }
}
