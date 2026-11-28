import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'GearLab 器材研究所'**
  String get appTitle;

  /// No description provided for @brandSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'器材研究所'**
  String get brandSubtitle;

  /// No description provided for @localOnlyNote.
  ///
  /// In zh, this message translates to:
  /// **'本地处理 · 照片不离开设备'**
  String get localOnlyNote;

  /// No description provided for @importPhotos.
  ///
  /// In zh, this message translates to:
  /// **'导入照片'**
  String get importPhotos;

  /// No description provided for @exportWork.
  ///
  /// In zh, this message translates to:
  /// **'导出作品'**
  String get exportWork;

  /// No description provided for @exportAll.
  ///
  /// In zh, this message translates to:
  /// **'导出 {count} 张作品'**
  String exportAll(Object count);

  /// No description provided for @exportAllOne.
  ///
  /// In zh, this message translates to:
  /// **'导出 1 张作品'**
  String get exportAllOne;

  /// No description provided for @exportCurrent.
  ///
  /// In zh, this message translates to:
  /// **'导出当前'**
  String get exportCurrent;

  /// No description provided for @library.
  ///
  /// In zh, this message translates to:
  /// **'照片库'**
  String get library;

  /// No description provided for @preview.
  ///
  /// In zh, this message translates to:
  /// **'预览'**
  String get preview;

  /// No description provided for @layoutSettings.
  ///
  /// In zh, this message translates to:
  /// **'版面设置'**
  String get layoutSettings;

  /// No description provided for @syncAll.
  ///
  /// In zh, this message translates to:
  /// **'同步全部'**
  String get syncAll;

  /// No description provided for @reset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get reset;

  /// No description provided for @emptyLibraryTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有照片'**
  String get emptyLibraryTitle;

  /// No description provided for @emptyLibraryBody.
  ///
  /// In zh, this message translates to:
  /// **'导入照片后，它们会在这里排成胶片条。'**
  String get emptyLibraryBody;

  /// No description provided for @emptyStageTitle.
  ///
  /// In zh, this message translates to:
  /// **'把照片装进相机里'**
  String get emptyStageTitle;

  /// No description provided for @emptyStageBody.
  ///
  /// In zh, this message translates to:
  /// **'导入照片，选一台机身，1:1 排版后导出。'**
  String get emptyStageBody;

  /// No description provided for @sectionCamera.
  ///
  /// In zh, this message translates to:
  /// **'相机模板'**
  String get sectionCamera;

  /// No description provided for @sectionText.
  ///
  /// In zh, this message translates to:
  /// **'标题与文字'**
  String get sectionText;

  /// No description provided for @sectionLayout.
  ///
  /// In zh, this message translates to:
  /// **'版面'**
  String get sectionLayout;

  /// No description provided for @sectionBackground.
  ///
  /// In zh, this message translates to:
  /// **'相机背景'**
  String get sectionBackground;

  /// No description provided for @sectionScreen.
  ///
  /// In zh, this message translates to:
  /// **'相机屏幕'**
  String get sectionScreen;

  /// No description provided for @tabCamera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get tabCamera;

  /// No description provided for @tabText.
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get tabText;

  /// No description provided for @tabLayout.
  ///
  /// In zh, this message translates to:
  /// **'版面'**
  String get tabLayout;

  /// No description provided for @tabBackground.
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get tabBackground;

  /// No description provided for @tabScreen.
  ///
  /// In zh, this message translates to:
  /// **'屏幕'**
  String get tabScreen;

  /// No description provided for @cameraCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 款'**
  String cameraCount(Object count);

  /// No description provided for @cameraHint.
  ///
  /// In zh, this message translates to:
  /// **'左右滑动浏览'**
  String get cameraHint;

  /// No description provided for @browseAllCameras.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 款'**
  String browseAllCameras(Object count);

  /// No description provided for @cameraPanelNote.
  ///
  /// In zh, this message translates to:
  /// **'点选机身立即套用到当前照片。'**
  String get cameraPanelNote;

  /// No description provided for @cameraSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索品牌或型号'**
  String get cameraSearchHint;

  /// No description provided for @cameraAliasFujifilm.
  ///
  /// In zh, this message translates to:
  /// **'富士 富士胶片'**
  String get cameraAliasFujifilm;

  /// No description provided for @cameraAliasNikon.
  ///
  /// In zh, this message translates to:
  /// **'尼康'**
  String get cameraAliasNikon;

  /// No description provided for @cameraAliasCanon.
  ///
  /// In zh, this message translates to:
  /// **'佳能'**
  String get cameraAliasCanon;

  /// No description provided for @cameraAliasSony.
  ///
  /// In zh, this message translates to:
  /// **'索尼'**
  String get cameraAliasSony;

  /// No description provided for @cameraAliasLumix.
  ///
  /// In zh, this message translates to:
  /// **'松下'**
  String get cameraAliasLumix;

  /// No description provided for @cameraAliasRicoh.
  ///
  /// In zh, this message translates to:
  /// **'理光'**
  String get cameraAliasRicoh;

  /// No description provided for @filterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get filterAll;

  /// No description provided for @filterRecent.
  ///
  /// In zh, this message translates to:
  /// **'最近'**
  String get filterRecent;

  /// No description provided for @filterFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get filterFavorites;

  /// No description provided for @favoriteCamera.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get favoriteCamera;

  /// No description provided for @unfavoriteCamera.
  ///
  /// In zh, this message translates to:
  /// **'取消收藏'**
  String get unfavoriteCamera;

  /// No description provided for @noCameraMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的机身'**
  String get noCameraMatch;

  /// No description provided for @previousPhoto.
  ///
  /// In zh, this message translates to:
  /// **'上一张'**
  String get previousPhoto;

  /// No description provided for @nextPhoto.
  ///
  /// In zh, this message translates to:
  /// **'下一张'**
  String get nextPhoto;

  /// No description provided for @titleLabel.
  ///
  /// In zh, this message translates to:
  /// **'标题'**
  String get titleLabel;

  /// No description provided for @showTitle.
  ///
  /// In zh, this message translates to:
  /// **'显示'**
  String get showTitle;

  /// No description provided for @titleHint.
  ///
  /// In zh, this message translates to:
  /// **'留空则使用相机型号'**
  String get titleHint;

  /// No description provided for @titleHelper.
  ///
  /// In zh, this message translates to:
  /// **'留空时使用相机型号作为标题。标题最多 80 字。'**
  String get titleHelper;

  /// No description provided for @subtitleLabel.
  ///
  /// In zh, this message translates to:
  /// **'副标题'**
  String get subtitleLabel;

  /// No description provided for @subtitleHint.
  ///
  /// In zh, this message translates to:
  /// **'地点 · 日期 · 一句话（可选）'**
  String get subtitleHint;

  /// No description provided for @subtitleHelper.
  ///
  /// In zh, this message translates to:
  /// **'副标题最多 120 字。'**
  String get subtitleHelper;

  /// No description provided for @photoRatio.
  ///
  /// In zh, this message translates to:
  /// **'照片比例'**
  String get photoRatio;

  /// No description provided for @photoRatioValue.
  ///
  /// In zh, this message translates to:
  /// **'跟随原图'**
  String get photoRatioValue;

  /// No description provided for @split.
  ///
  /// In zh, this message translates to:
  /// **'版面分配'**
  String get split;

  /// No description provided for @splitValue.
  ///
  /// In zh, this message translates to:
  /// **'上下 1:1'**
  String get splitValue;

  /// No description provided for @cameraSize.
  ///
  /// In zh, this message translates to:
  /// **'相机大小'**
  String get cameraSize;

  /// No description provided for @layoutNote.
  ///
  /// In zh, this message translates to:
  /// **'照片完整不裁切，隐藏标题也保持上下 1:1。'**
  String get layoutNote;

  /// No description provided for @backgroundLabel.
  ///
  /// In zh, this message translates to:
  /// **'相机背景'**
  String get backgroundLabel;

  /// No description provided for @backgroundNote.
  ///
  /// In zh, this message translates to:
  /// **'只影响上半幅，标题会自动选择深色或浅色。'**
  String get backgroundNote;

  /// No description provided for @screenFit.
  ///
  /// In zh, this message translates to:
  /// **'屏幕显示'**
  String get screenFit;

  /// No description provided for @fill.
  ///
  /// In zh, this message translates to:
  /// **'填满'**
  String get fill;

  /// No description provided for @fit.
  ///
  /// In zh, this message translates to:
  /// **'完整'**
  String get fit;

  /// No description provided for @glare.
  ///
  /// In zh, this message translates to:
  /// **'反光'**
  String get glare;

  /// No description provided for @screenNote.
  ///
  /// In zh, this message translates to:
  /// **'填满时照片铺满屏幕，完整时保留屏幕黑边。'**
  String get screenNote;

  /// No description provided for @exportTitle.
  ///
  /// In zh, this message translates to:
  /// **'导出作品'**
  String get exportTitle;

  /// No description provided for @exportSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'使用每张照片自己的设置，生成本地作品。'**
  String get exportSubtitle;

  /// No description provided for @scope.
  ///
  /// In zh, this message translates to:
  /// **'导出范围'**
  String get scope;

  /// No description provided for @scopeCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前单张'**
  String get scopeCurrent;

  /// No description provided for @scopeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 张'**
  String scopeAll(Object count);

  /// No description provided for @scopeAllOne.
  ///
  /// In zh, this message translates to:
  /// **'全部 1 张'**
  String get scopeAllOne;

  /// No description provided for @outputSize.
  ///
  /// In zh, this message translates to:
  /// **'输出尺寸'**
  String get outputSize;

  /// No description provided for @size1080.
  ///
  /// In zh, this message translates to:
  /// **'高清'**
  String get size1080;

  /// No description provided for @size1440.
  ///
  /// In zh, this message translates to:
  /// **'2K'**
  String get size1440;

  /// No description provided for @size2160.
  ///
  /// In zh, this message translates to:
  /// **'超清'**
  String get size2160;

  /// No description provided for @format.
  ///
  /// In zh, this message translates to:
  /// **'格式'**
  String get format;

  /// No description provided for @formatJpg.
  ///
  /// In zh, this message translates to:
  /// **'JPG\n体积小'**
  String get formatJpg;

  /// No description provided for @formatPng.
  ///
  /// In zh, this message translates to:
  /// **'PNG\n无损'**
  String get formatPng;

  /// No description provided for @quality.
  ///
  /// In zh, this message translates to:
  /// **'JPG 画质'**
  String get quality;

  /// No description provided for @qualityHint.
  ///
  /// In zh, this message translates to:
  /// **'默认 100：最高质量、最低压缩。'**
  String get qualityHint;

  /// No description provided for @saveTo.
  ///
  /// In zh, this message translates to:
  /// **'保存到'**
  String get saveTo;

  /// No description provided for @saveToGallery.
  ///
  /// In zh, this message translates to:
  /// **'保存到相册'**
  String get saveToGallery;

  /// No description provided for @galleryFolder.
  ///
  /// In zh, this message translates to:
  /// **'系统相册 · GearLab'**
  String get galleryFolder;

  /// No description provided for @galleryNote.
  ///
  /// In zh, this message translates to:
  /// **'默认保存到系统相册 GearLab，可在相册中直接查看。'**
  String get galleryNote;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @startExport.
  ///
  /// In zh, this message translates to:
  /// **'开始导出'**
  String get startExport;

  /// No description provided for @exporting.
  ///
  /// In zh, this message translates to:
  /// **'正在导出'**
  String get exporting;

  /// No description provided for @preparingExport.
  ///
  /// In zh, this message translates to:
  /// **'正在准备…'**
  String get preparingExport;

  /// No description provided for @exportFolderFallback.
  ///
  /// In zh, this message translates to:
  /// **'所选目录不可写，已改存到 {folder}'**
  String exportFolderFallback(Object folder);

  /// No description provided for @exportProgress.
  ///
  /// In zh, this message translates to:
  /// **'{done} / {total}'**
  String exportProgress(Object done, Object total);

  /// No description provided for @exportDone.
  ///
  /// In zh, this message translates to:
  /// **'导出完成'**
  String get exportDone;

  /// No description provided for @exportDoneBody.
  ///
  /// In zh, this message translates to:
  /// **'已生成 {count} 张作品。'**
  String exportDoneBody(Object count);

  /// No description provided for @exportDoneBodyOne.
  ///
  /// In zh, this message translates to:
  /// **'已生成 1 张作品。'**
  String get exportDoneBodyOne;

  /// No description provided for @exportOpenFolder.
  ///
  /// In zh, this message translates to:
  /// **'打开文件夹'**
  String get exportOpenFolder;

  /// No description provided for @exportShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get exportShare;

  /// No description provided for @exportClose.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get exportClose;

  /// No description provided for @exportFailed.
  ///
  /// In zh, this message translates to:
  /// **'导出完成，但有 {count} 张失败：'**
  String exportFailed(Object count);

  /// No description provided for @exportGallerySaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存到系统相册 GearLab。'**
  String get exportGallerySaved;

  /// No description provided for @exportFolderLabel.
  ///
  /// In zh, this message translates to:
  /// **'保存位置'**
  String get exportFolderLabel;

  /// No description provided for @dismiss.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get dismiss;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置版面？'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'会把当前照片的模板、文字、颜色和屏幕设置恢复为默认。'**
  String get resetConfirmBody;

  /// No description provided for @clearPhotos.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clearPhotos;

  /// No description provided for @clearConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空照片库？'**
  String get clearConfirmTitle;

  /// No description provided for @clearConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'照片仍保留在磁盘上，只从编辑区移除。'**
  String get clearConfirmBody;

  /// No description provided for @deletePhoto.
  ///
  /// In zh, this message translates to:
  /// **'移除照片'**
  String get deletePhoto;

  /// No description provided for @theme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @more.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// No description provided for @preferences.
  ///
  /// In zh, this message translates to:
  /// **'偏好设置'**
  String get preferences;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @allPhotos.
  ///
  /// In zh, this message translates to:
  /// **'{count} 张'**
  String allPhotos(Object count);

  /// No description provided for @allPhotosOne.
  ///
  /// In zh, this message translates to:
  /// **'1 张'**
  String get allPhotosOne;

  /// No description provided for @photoMeta.
  ///
  /// In zh, this message translates to:
  /// **'{width} × {height} · {camera}'**
  String photoMeta(Object camera, Object height, Object width);

  /// No description provided for @stageFooterSplit.
  ///
  /// In zh, this message translates to:
  /// **'上下 1:1'**
  String get stageFooterSplit;

  /// No description provided for @stageFooterFormat.
  ///
  /// In zh, this message translates to:
  /// **'JPG'**
  String get stageFooterFormat;

  /// No description provided for @stageFooterWidth.
  ///
  /// In zh, this message translates to:
  /// **'{width} PX'**
  String stageFooterWidth(Object width);

  /// No description provided for @currentOf.
  ///
  /// In zh, this message translates to:
  /// **'{index} / {total}'**
  String currentOf(Object index, Object total);

  /// No description provided for @dropHint.
  ///
  /// In zh, this message translates to:
  /// **'拖入照片或文件夹'**
  String get dropHint;

  /// No description provided for @emptyExport.
  ///
  /// In zh, this message translates to:
  /// **'没有可导出的照片'**
  String get emptyExport;

  /// No description provided for @savedCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 张已导出'**
  String savedCount(Object count);

  /// No description provided for @savedCountOne.
  ///
  /// In zh, this message translates to:
  /// **'1 张已导出'**
  String get savedCountOne;

  /// No description provided for @unsupportedFormat.
  ///
  /// In zh, this message translates to:
  /// **'不支持的格式'**
  String get unsupportedFormat;

  /// No description provided for @couldNotReadImage.
  ///
  /// In zh, this message translates to:
  /// **'无法读取这张图片'**
  String get couldNotReadImage;

  /// No description provided for @exportFolderNotWritable.
  ///
  /// In zh, this message translates to:
  /// **'导出目录不可写'**
  String get exportFolderNotWritable;

  /// No description provided for @themeChanged.
  ///
  /// In zh, this message translates to:
  /// **'外观已更新'**
  String get themeChanged;

  /// No description provided for @languageChanged.
  ///
  /// In zh, this message translates to:
  /// **'语言已切换'**
  String get languageChanged;

  /// No description provided for @preferencesNote.
  ///
  /// In zh, this message translates to:
  /// **'偏好会保存到本机，并在下次启动时恢复。'**
  String get preferencesNote;

  /// No description provided for @aboutLocal.
  ///
  /// In zh, this message translates to:
  /// **'全部处理都在本机完成，不联网、不上传。'**
  String get aboutLocal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
