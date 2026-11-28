// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GearLab Camera Lab';

  @override
  String get brandSubtitle => 'CAMERA LAB';

  @override
  String get localOnlyNote => 'Local only · photos stay on this device';

  @override
  String get importPhotos => 'Import photos';

  @override
  String get exportWork => 'Export';

  @override
  String exportAll(Object count) {
    return 'Export $count works';
  }

  @override
  String get exportAllOne => 'Export 1 work';

  @override
  String get exportCurrent => 'Export current';

  @override
  String get library => 'Library';

  @override
  String get preview => 'Preview';

  @override
  String get layoutSettings => 'Layout';

  @override
  String get syncAll => 'Sync all';

  @override
  String get reset => 'Reset';

  @override
  String get emptyLibraryTitle => 'No photos yet';

  @override
  String get emptyLibraryBody =>
      'Imported photos line up here like a contact sheet.';

  @override
  String get emptyStageTitle => 'Put your photos inside a camera';

  @override
  String get emptyStageBody =>
      'Import a photo, choose a camera body, and export a 1:1 composition.';

  @override
  String get sectionCamera => 'Camera';

  @override
  String get sectionText => 'Title & text';

  @override
  String get sectionLayout => 'Layout';

  @override
  String get sectionBackground => 'Camera band';

  @override
  String get sectionScreen => 'Screen';

  @override
  String get tabCamera => 'Camera';

  @override
  String get tabText => 'Text';

  @override
  String get tabLayout => 'Layout';

  @override
  String get tabBackground => 'Background';

  @override
  String get tabScreen => 'Screen';

  @override
  String cameraCount(Object count) {
    return '$count bodies';
  }

  @override
  String get cameraHint => 'Scroll to browse';

  @override
  String browseAllCameras(Object count) {
    return 'All $count';
  }

  @override
  String get cameraPanelNote => 'Pick a body to apply it to the current photo.';

  @override
  String get cameraSearchHint => 'Search brand or model';

  @override
  String get cameraAliasFujifilm => 'fuji';

  @override
  String get cameraAliasNikon => 'nikon';

  @override
  String get cameraAliasCanon => 'canon';

  @override
  String get cameraAliasSony => 'sony';

  @override
  String get cameraAliasLumix => 'panasonic';

  @override
  String get cameraAliasRicoh => 'ricoh';

  @override
  String get filterAll => 'All';

  @override
  String get filterRecent => 'Recent';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get favoriteCamera => 'Add to favorites';

  @override
  String get unfavoriteCamera => 'Remove from favorites';

  @override
  String get noCameraMatch => 'No matching body';

  @override
  String get previousPhoto => 'Previous photo';

  @override
  String get nextPhoto => 'Next photo';

  @override
  String get titleLabel => 'Title';

  @override
  String get showTitle => 'Show';

  @override
  String get titleHint => 'Defaults to the camera model';

  @override
  String get titleHelper =>
      'Leave empty to use the camera model. Up to 80 characters.';

  @override
  String get subtitleLabel => 'Subtitle';

  @override
  String get subtitleHint => 'Place · date · a line (optional)';

  @override
  String get subtitleHelper => 'Up to 120 characters.';

  @override
  String get photoRatio => 'Photo ratio';

  @override
  String get photoRatioValue => 'Original';

  @override
  String get split => 'Split';

  @override
  String get splitValue => '1:1 top/bottom';

  @override
  String get cameraSize => 'Camera size';

  @override
  String get layoutNote =>
      'Photos are never cropped; hiding the title keeps the 1:1 split.';

  @override
  String get backgroundLabel => 'Camera band color';

  @override
  String get backgroundNote =>
      'Affects the top half only; the title ink adapts automatically.';

  @override
  String get screenFit => 'Screen fit';

  @override
  String get fill => 'Fill';

  @override
  String get fit => 'Fit';

  @override
  String get glare => 'Glare';

  @override
  String get screenNote => 'Fill covers the screen; Fit keeps the black bezel.';

  @override
  String get exportTitle => 'Export';

  @override
  String get exportSubtitle =>
      'Each photo uses its own layout and exports locally.';

  @override
  String get scope => 'Scope';

  @override
  String get scopeCurrent => 'Current photo';

  @override
  String scopeAll(Object count) {
    return 'All $count';
  }

  @override
  String get scopeAllOne => 'All 1 photo';

  @override
  String get outputSize => 'Output size';

  @override
  String get size1080 => 'HD';

  @override
  String get size1440 => '2K';

  @override
  String get size2160 => 'Ultra';

  @override
  String get format => 'Format';

  @override
  String get formatJpg => 'JPG\nSmaller';

  @override
  String get formatPng => 'PNG\nLossless';

  @override
  String get quality => 'JPG quality';

  @override
  String get qualityHint => 'Default 100: highest quality, least compression.';

  @override
  String get saveTo => 'Save to';

  @override
  String get saveToGallery => 'Save to gallery';

  @override
  String get galleryFolder => 'Gallery · GearLab';

  @override
  String get galleryNote => 'Saved to the GearLab album in your gallery.';

  @override
  String get cancel => 'Cancel';

  @override
  String get startExport => 'Start export';

  @override
  String get exporting => 'Exporting';

  @override
  String get preparingExport => 'Preparing…';

  @override
  String exportFolderFallback(Object folder) {
    return 'That folder was not writable; saved to $folder';
  }

  @override
  String exportProgress(Object done, Object total) {
    return '$done / $total';
  }

  @override
  String get exportDone => 'Export complete';

  @override
  String exportDoneBody(Object count) {
    return '$count works exported.';
  }

  @override
  String get exportDoneBodyOne => '1 work exported.';

  @override
  String get exportOpenFolder => 'Open folder';

  @override
  String get exportShare => 'Share';

  @override
  String get exportClose => 'Done';

  @override
  String exportFailed(Object count) {
    return 'Exported with $count failures:';
  }

  @override
  String get exportGallerySaved => 'Saved to the GearLab album.';

  @override
  String get exportFolderLabel => 'Location';

  @override
  String get dismiss => 'Got it';

  @override
  String get resetConfirmTitle => 'Reset layout?';

  @override
  String get resetConfirmBody =>
      'Restores the current photo\'s template, text, color, and screen settings.';

  @override
  String get clearPhotos => 'Clear';

  @override
  String get clearConfirmTitle => 'Clear the library?';

  @override
  String get clearConfirmBody =>
      'Files stay on disk; they are only removed from the editor.';

  @override
  String get deletePhoto => 'Remove photo';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get more => 'More';

  @override
  String get preferences => 'Preferences';

  @override
  String get appearance => 'Appearance';

  @override
  String get done => 'Done';

  @override
  String allPhotos(Object count) {
    return '$count photos';
  }

  @override
  String get allPhotosOne => '1 photo';

  @override
  String photoMeta(Object camera, Object height, Object width) {
    return '$width × $height · $camera';
  }

  @override
  String get stageFooterSplit => '1:1 split';

  @override
  String get stageFooterFormat => 'JPG';

  @override
  String stageFooterWidth(Object width) {
    return '$width PX';
  }

  @override
  String currentOf(Object index, Object total) {
    return '$index / $total';
  }

  @override
  String get dropHint => 'Drop photos or a folder';

  @override
  String get emptyExport => 'No photos to export';

  @override
  String savedCount(Object count) {
    return '$count exported';
  }

  @override
  String get savedCountOne => '1 exported';

  @override
  String get unsupportedFormat => 'Unsupported format';

  @override
  String get couldNotReadImage => 'Could not read this image';

  @override
  String get exportFolderNotWritable => 'Export folder is not writable';

  @override
  String get themeChanged => 'Appearance updated';

  @override
  String get languageChanged => 'Language changed';

  @override
  String get preferencesNote =>
      'Preferences are saved on this device and restored next launch.';

  @override
  String get aboutLocal =>
      'Everything is processed on this device. No network, no upload.';
}
