import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'models.dart';

class CameraCatalog {
  static const List<CameraTemplate> all = <CameraTemplate>[
    // RICOH
    CameraTemplate(
      id: 'ricoh-gr4',
      asset: 'assets/cameras/ricoh-gr4.png',
      brand: 'RICOH',
      model: 'GR IV',
      displayName: 'Ricoh GR IV',
      aspect: 855 / 502,
      screen: Rect.fromLTWH(0.051990, 0.186895, 0.642220, 0.715795),
    ),

    // FUJIFILM
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
      id: 'fujifilm-gfx100-ii',
      asset: 'assets/cameras/fujifilm-gfx100-ii.png',
      brand: 'FUJIFILM',
      model: 'GFX100 II',
      displayName: 'Fujifilm GFX100 II',
      aspect: 825 / 660,
      screen: Rect.fromLTWH(0.065455, 0.460606, 0.506667, 0.443939),
    ),
    CameraTemplate(
      id: 'fujifilm-gfx100rf',
      asset: 'assets/cameras/fujifilm-gfx100rf.png',
      brand: 'FUJIFILM',
      model: 'GFX100RF',
      displayName: 'Fujifilm GFX100RF',
      aspect: 937 / 581,
      screen: Rect.fromLTWH(0.124867, 0.356282, 0.518677, 0.574871),
    ),
    CameraTemplate(
      id: 'fujifilm-x-e5',
      asset: 'assets/cameras/fujifilm-x-e5.png',
      brand: 'FUJIFILM',
      model: 'X-E5',
      displayName: 'Fujifilm X-E5',
      aspect: 921 / 505,
      screen: Rect.fromLTWH(0.081433, 0.295050, 0.575461, 0.600000),
    ),
    CameraTemplate(
      id: 'fujifilm-x-h2',
      asset: 'assets/cameras/fujifilm-x-h2.png',
      brand: 'FUJIFILM',
      model: 'X-H2',
      displayName: 'Fujifilm X-H2',
      aspect: 939 / 639,
      screen: Rect.fromLTWH(0.111821, 0.477308, 0.529286, 0.503912),
    ),
    CameraTemplate(
      id: 'fujifilm-x-h2s',
      asset: 'assets/cameras/fujifilm-x-h2s.png',
      brand: 'FUJIFILM',
      model: 'X-H2S',
      displayName: 'Fujifilm X-H2S',
      aspect: 923 / 628,
      screen: Rect.fromLTWH(0.114843, 0.485669, 0.534128, 0.514331),
    ),
    CameraTemplate(
      id: 'fujifilm-x-s10',
      asset: 'assets/cameras/fujifilm-x-s10.png',
      brand: 'FUJIFILM',
      model: 'X-S10',
      displayName: 'Fujifilm X-S10',
      aspect: 953 / 611,
      screen: Rect.fromLTWH(0.115425, 0.499182, 0.561385, 0.458265),
    ),
    CameraTemplate(
      id: 'fujifilm-x-s20',
      asset: 'assets/cameras/fujifilm-x-s20.png',
      brand: 'FUJIFILM',
      model: 'X-S20',
      displayName: 'Fujifilm X-S20',
      aspect: 1089 / 707,
      screen: Rect.fromLTWH(0.172635, 0.431400, 0.479339, 0.480905),
    ),
    CameraTemplate(
      id: 'fujifilm-x-t30-iii',
      asset: 'assets/cameras/fujifilm-x-t30-iii.png',
      brand: 'FUJIFILM',
      model: 'X-T30 III',
      displayName: 'Fujifilm X-T30 III',
      aspect: 921 / 593,
      screen: Rect.fromLTWH(0.115092, 0.413153, 0.597177, 0.539629),
    ),
    CameraTemplate(
      id: 'fujifilm-x-t5',
      asset: 'assets/cameras/fujifilm-x-t5.png',
      brand: 'FUJIFILM',
      model: 'X-T5',
      displayName: 'Fujifilm X-T5',
      aspect: 997 / 655,
      screen: Rect.fromLTWH(0.110331, 0.465649, 0.536610, 0.503817),
    ),
    CameraTemplate(
      id: 'fujifilm-x-t50',
      asset: 'assets/cameras/fujifilm-x-t50.png',
      brand: 'FUJIFILM',
      model: 'X-T50',
      displayName: 'Fujifilm X-T50',
      aspect: 923 / 602,
      screen: Rect.fromLTWH(0.130011, 0.373754, 0.574215, 0.573090),
    ),

    // NIKON
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
      id: 'nikon-z5ii-c',
      asset: 'assets/cameras/nikon-z5ii-c.png',
      brand: 'NIKON',
      model: 'Z5II C',
      displayName: 'Nikon Z5II C',
      aspect: 686 / 410,
      screen: Rect.fromLTWH(108 / 686, 122 / 410, 367 / 686, 256 / 410),
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
      id: 'nikon-fe',
      asset: 'assets/cameras/nikon-fe.png',
      brand: 'NIKON',
      model: 'FE',
      displayName: 'Nikon FE',
      aspect: 642 / 422,
      screen: Rect.fromLTWH(0.320872, 0.575829, 0.236760, 0.293839),
    ),
    CameraTemplate(
      id: 'nikon-z30',
      asset: 'assets/cameras/nikon-z30.png',
      brand: 'NIKON',
      model: 'Z30',
      displayName: 'Nikon Z30',
      aspect: 678 / 400,
      screen: Rect.fromLTWH(0.081121, 0.262500, 0.597345, 0.655000),
    ),
    CameraTemplate(
      id: 'nikon-z50ii',
      asset: 'assets/cameras/nikon-z50ii.png',
      brand: 'NIKON',
      model: 'Z50II',
      displayName: 'Nikon Z50II',
      aspect: 686 / 493,
      screen: Rect.fromLTWH(0.142857, 0.409736, 0.553936, 0.525355),
    ),
    CameraTemplate(
      id: 'nikon-zf',
      asset: 'assets/cameras/nikon-zf.png',
      brand: 'NIKON',
      model: 'Zf',
      displayName: 'Nikon Zf',
      aspect: 686 / 476,
      screen: Rect.fromLTWH(0.131195, 0.451681, 0.498542, 0.478992),
    ),
    CameraTemplate(
      id: 'nikon-zfc',
      asset: 'assets/cameras/nikon-zfc.png',
      brand: 'NIKON',
      model: 'Zfc',
      displayName: 'Nikon Zfc',
      aspect: 672 / 452,
      screen: Rect.fromLTWH(0.148810, 0.435841, 0.495536, 0.497788),
    ),

    // SONY
    CameraTemplate(
      id: 'sony-a7c2',
      asset: 'assets/cameras/sony-a7c2.png',
      brand: 'SONY',
      model: 'α7C II',
      displayName: 'Sony α7C II',
      aspect: 518 / 290,
      screen: Rect.fromLTWH(0.1795, 0.3552, 0.4517, 0.5448),
      screenInset: 0,
    ),
    CameraTemplate(
      id: 'sony-a7c2-s',
      asset: 'assets/cameras/sony-a7c2-silver.png',
      brand: 'SONY',
      model: 'α7C II',
      displayName: 'Sony α7C II',
      aspect: 632 / 353,
      screen: Rect.fromLTWH(0.1804, 0.3569, 0.4525, 0.5382),
      screenInset: 0,
    ),
    CameraTemplate(
      id: 'sony-zv-e10',
      asset: 'assets/cameras/sony-zv-e10.png',
      brand: 'SONY',
      model: 'ZV-E10',
      displayName: 'Sony ZV-E10',
      aspect: 639 / 350,
      screen: Rect.fromLTWH(0.133020, 0.148571, 0.560250, 0.702857),
    ),
    CameraTemplate(
      id: 'sony-a7-iv',
      asset: 'assets/cameras/sony-a7-iv.png',
      brand: 'SONY',
      model: 'α7 IV',
      displayName: 'Sony α7 IV',
      aspect: 642 / 450,
      screen: Rect.fromLTWH(0.115265, 0.413333, 0.518692, 0.484444),
    ),

    // LUMIX
    CameraTemplate(
      id: 'lumix-s9',
      asset: 'assets/cameras/lumix-s9.png',
      brand: 'LUMIX',
      model: 'S9',
      displayName: 'Lumix S9',
      aspect: 624 / 359,
      screen: Rect.fromLTWH(0.1827, 0.3593, 0.4679, 0.5432),
      screenInset: 0,
    ),
    CameraTemplate(
      id: 'lumix-s9-s',
      asset: 'assets/cameras/lumix-s9-silver.png',
      brand: 'LUMIX',
      model: 'S9',
      displayName: 'Lumix S9',
      aspect: 1704 / 981,
      screen: Rect.fromLTWH(0.1837, 0.3588, 0.4654, 0.5423),
      screenInset: 0,
    ),
    CameraTemplate(
      id: 'lumix-s5ii',
      asset: 'assets/cameras/lumix-s5ii.png',
      brand: 'LUMIX',
      model: 'S5II',
      displayName: 'Lumix S5II',
      aspect: 642 / 490,
      screen: Rect.fromLTWH(0.115265, 0.489796, 0.549844, 0.465306),
    ),

    // CANON
    CameraTemplate(
      id: 'canon-eos-6d',
      asset: 'assets/cameras/canon-eos-6d.png',
      brand: 'CANON',
      model: 'EOS 6D',
      displayName: 'Canon EOS 6D',
      aspect: 642 / 499,
      screen: Rect.fromLTWH(0.161994, 0.454910, 0.431464, 0.382766),
    ),
    CameraTemplate(
      id: 'canon-eos-r5',
      asset: 'assets/cameras/canon-eos-r5.png',
      brand: 'CANON',
      model: 'EOS R5',
      displayName: 'Canon EOS R5',
      aspect: 725 / 535,
      screen: Rect.fromLTWH(0.095172, 0.409346, 0.543448, 0.543925),
    ),
    CameraTemplate(
      id: 'canon-eos-r5-mark-ii',
      asset: 'assets/cameras/canon-eos-r5-mark-ii.png',
      brand: 'CANON',
      model: 'EOS R5 Mark II',
      displayName: 'Canon EOS R5 Mark II',
      aspect: 536 / 407,
      screen: Rect.fromLTWH(0.128731, 0.429975, 0.507463, 0.501229),
    ),
    CameraTemplate(
      id: 'canon-eos-r6-mark-iii',
      asset: 'assets/cameras/canon-eos-r6-mark-iii.png',
      brand: 'CANON',
      model: 'EOS R6 Mark III',
      displayName: 'Canon EOS R6 Mark III',
      aspect: 513 / 383,
      screen: Rect.fromLTWH(0.099415, 0.441253, 0.510721, 0.501305),
    ),
    CameraTemplate(
      id: 'canon-eos-r6-v',
      asset: 'assets/cameras/canon-eos-r6-v.png',
      brand: 'CANON',
      model: 'EOS R6 V',
      displayName: 'Canon EOS R6 V',
      aspect: 517 / 326,
      screen: Rect.fromLTWH(0.127660, 0.303681, 0.473888, 0.585890),
    ),
    CameraTemplate(
      id: 'canon-eos-r8',
      asset: 'assets/cameras/canon-eos-r8.png',
      brand: 'CANON',
      model: 'EOS R8',
      displayName: 'Canon EOS R8',
      aspect: 569 / 393,
      screen: Rect.fromLTWH(0.172232, 0.452926, 0.441125, 0.424936),
    ),
    CameraTemplate(
      id: 'canon-eos-r8-mark-ii',
      asset: 'assets/cameras/canon-eos-r8-mark-ii.png',
      brand: 'CANON',
      model: 'EOS R8 Mark II',
      displayName: 'Canon EOS R8 Mark II',
      aspect: 504 / 353,
      screen: Rect.fromLTWH(0.156746, 0.427762, 0.521825, 0.498584),
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
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
      );
      final ui.FrameInfo frame = await codec.getNextFrame();
      images[template.id] = frame.image;
      codec.dispose();
    }
  }
}
