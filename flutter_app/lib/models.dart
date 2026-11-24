import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

enum ScreenFitMode { fill, fit }

enum ExportFormat { jpg, png }

enum ExportScope { current, selected, all }

class CameraTemplate {
  const CameraTemplate({
    required this.id,
    required this.asset,
    required this.brand,
    required this.model,
    required this.displayName,
    required this.aspect,
    required this.screen,
  });

  final String id;
  final String asset;
  final String brand;
  final String model;
  final String displayName;
  final double aspect;

  /// Normalized screen rectangle inside the camera artwork.
  final Rect screen;
}

class StyleSettings {
  StyleSettings({
    this.cameraId = 'ricoh-gr4',
    this.cameraScale = 0.50,
    this.showTitle = true,
    this.title = '',
    this.subtitle = '',
    this.screenFit = ScreenFitMode.fill,
    this.screenGlare = false,
    this.topColor = const Color(0xFFFFFFFF),
  });

  String cameraId;
  double cameraScale;
  bool showTitle;
  String title;
  String subtitle;
  ScreenFitMode screenFit;
  bool screenGlare;
  Color topColor;

  StyleSettings clone() => StyleSettings(
    cameraId: cameraId,
    cameraScale: cameraScale,
    showTitle: showTitle,
    title: title,
    subtitle: subtitle,
    screenFit: screenFit,
    screenGlare: screenGlare,
    topColor: topColor,
  );

  void copyFrom(StyleSettings other) {
    cameraId = other.cameraId;
    cameraScale = other.cameraScale;
    showTitle = other.showTitle;
    title = other.title;
    subtitle = other.subtitle;
    screenFit = other.screenFit;
    screenGlare = other.screenGlare;
    topColor = other.topColor;
  }

  void clamp() {
    cameraScale = cameraScale.clamp(0.34, 0.72);
    if (title.length > 80) title = title.substring(0, 80);
    if (subtitle.length > 120) subtitle = subtitle.substring(0, 120);
  }

  String resolvedTitle(CameraTemplate template) {
    final String value = title.trim();
    return value.isEmpty ? template.displayName : value;
  }
}

class PhotoItem {
  PhotoItem({
    required this.path,
    required this.name,
    required this.image,
    required this.style,
  });

  final String path;
  final String name;
  final ui.Image image;
  StyleSettings style;
  bool exportSelected = true;
  bool managed = false;

  double get aspect => image.width / image.height;

  void dispose() {
    image.dispose();
  }
}

class ExportOptions {
  ExportOptions({
    this.scope = ExportScope.current,
    this.width = 2160,
    this.format = ExportFormat.jpg,
    this.quality = 100,
    this.folder = '',
  });

  final ExportScope scope;
  final int width;
  final ExportFormat format;
  final int quality;
  final String folder;

  ExportOptions copyWith({
    ExportScope? scope,
    int? width,
    ExportFormat? format,
    int? quality,
    String? folder,
  }) {
    return ExportOptions(
      scope: scope ?? this.scope,
      width: width ?? this.width,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      folder: folder ?? this.folder,
    );
  }
}

class ExportProgress {
  const ExportProgress({
    this.done = 0,
    this.total = 1,
    this.message = '',
    this.currentFile = '',
  });

  final int done;
  final int total;
  final String message;
  final String currentFile;

  double get value => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

class ExportResult {
  ExportResult({
    required this.files,
    required this.folder,
    this.errors = const [],
    this.gallerySaved = 0,
    this.notice,
  });

  final List<String> files;
  final String folder;
  final List<String> errors;
  final int gallerySaved;
  final String? notice;

  bool get success => files.isNotEmpty && errors.isEmpty;
}
