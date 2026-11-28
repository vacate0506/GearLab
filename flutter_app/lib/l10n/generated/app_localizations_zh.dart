// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'GearLab 器材研究所';

  @override
  String get brandSubtitle => '器材研究所';

  @override
  String get localOnlyNote => '本地处理 · 照片不离开设备';

  @override
  String get importPhotos => '导入照片';

  @override
  String get exportWork => '导出作品';

  @override
  String exportAll(Object count) {
    return '导出 $count 张作品';
  }

  @override
  String get exportAllOne => '导出 1 张作品';

  @override
  String get exportCurrent => '导出当前';

  @override
  String get library => '照片库';

  @override
  String get preview => '预览';

  @override
  String get layoutSettings => '版面设置';

  @override
  String get syncAll => '同步全部';

  @override
  String get reset => '重置';

  @override
  String get emptyLibraryTitle => '还没有照片';

  @override
  String get emptyLibraryBody => '导入照片后，它们会在这里排成胶片条。';

  @override
  String get emptyStageTitle => '把照片装进相机里';

  @override
  String get emptyStageBody => '导入照片，选一台机身，1:1 排版后导出。';

  @override
  String get sectionCamera => '相机模板';

  @override
  String get sectionText => '标题与文字';

  @override
  String get sectionLayout => '版面';

  @override
  String get sectionBackground => '相机背景';

  @override
  String get sectionScreen => '相机屏幕';

  @override
  String get tabCamera => '相机';

  @override
  String get tabText => '文字';

  @override
  String get tabLayout => '版面';

  @override
  String get tabBackground => '背景';

  @override
  String get tabScreen => '屏幕';

  @override
  String cameraCount(Object count) {
    return '$count 款';
  }

  @override
  String get cameraHint => '左右滑动浏览';

  @override
  String browseAllCameras(Object count) {
    return '全部 $count 款';
  }

  @override
  String get cameraPanelNote => '点选机身立即套用到当前照片。';

  @override
  String get cameraSearchHint => '搜索品牌或型号';

  @override
  String get cameraAliasFujifilm => '富士 富士胶片';

  @override
  String get cameraAliasNikon => '尼康';

  @override
  String get cameraAliasCanon => '佳能';

  @override
  String get cameraAliasSony => '索尼';

  @override
  String get cameraAliasLumix => '松下';

  @override
  String get cameraAliasRicoh => '理光';

  @override
  String get filterAll => '全部';

  @override
  String get filterRecent => '最近';

  @override
  String get filterFavorites => '收藏';

  @override
  String get favoriteCamera => '收藏';

  @override
  String get unfavoriteCamera => '取消收藏';

  @override
  String get noCameraMatch => '没有匹配的机身';

  @override
  String get previousPhoto => '上一张';

  @override
  String get nextPhoto => '下一张';

  @override
  String get titleLabel => '标题';

  @override
  String get showTitle => '显示';

  @override
  String get titleHint => '留空则使用相机型号';

  @override
  String get titleHelper => '留空时使用相机型号作为标题。标题最多 80 字。';

  @override
  String get subtitleLabel => '副标题';

  @override
  String get subtitleHint => '地点 · 日期 · 一句话（可选）';

  @override
  String get subtitleHelper => '副标题最多 120 字。';

  @override
  String get photoRatio => '照片比例';

  @override
  String get photoRatioValue => '跟随原图';

  @override
  String get split => '版面分配';

  @override
  String get splitValue => '上下 1:1';

  @override
  String get cameraSize => '相机大小';

  @override
  String get layoutNote => '照片完整不裁切，隐藏标题也保持上下 1:1。';

  @override
  String get backgroundLabel => '相机背景';

  @override
  String get backgroundNote => '只影响上半幅，标题会自动选择深色或浅色。';

  @override
  String get screenFit => '屏幕显示';

  @override
  String get fill => '填满';

  @override
  String get fit => '完整';

  @override
  String get glare => '反光';

  @override
  String get screenNote => '填满时照片铺满屏幕，完整时保留屏幕黑边。';

  @override
  String get exportTitle => '导出作品';

  @override
  String get exportSubtitle => '使用每张照片自己的设置，生成本地作品。';

  @override
  String get scope => '导出范围';

  @override
  String get scopeCurrent => '当前单张';

  @override
  String scopeAll(Object count) {
    return '全部 $count 张';
  }

  @override
  String get scopeAllOne => '全部 1 张';

  @override
  String get outputSize => '输出尺寸';

  @override
  String get size1080 => '高清';

  @override
  String get size1440 => '2K';

  @override
  String get size2160 => '超清';

  @override
  String get format => '格式';

  @override
  String get formatJpg => 'JPG\n体积小';

  @override
  String get formatPng => 'PNG\n无损';

  @override
  String get quality => 'JPG 画质';

  @override
  String get qualityHint => '默认 100：最高质量、最低压缩。';

  @override
  String get saveTo => '保存到';

  @override
  String get saveToGallery => '保存到相册';

  @override
  String get galleryFolder => '系统相册 · GearLab';

  @override
  String get galleryNote => '默认保存到系统相册 GearLab，可在相册中直接查看。';

  @override
  String get cancel => '取消';

  @override
  String get startExport => '开始导出';

  @override
  String get exporting => '正在导出';

  @override
  String get preparingExport => '正在准备…';

  @override
  String exportFolderFallback(Object folder) {
    return '所选目录不可写，已改存到 $folder';
  }

  @override
  String exportProgress(Object done, Object total) {
    return '$done / $total';
  }

  @override
  String get exportDone => '导出完成';

  @override
  String exportDoneBody(Object count) {
    return '已生成 $count 张作品。';
  }

  @override
  String get exportDoneBodyOne => '已生成 1 张作品。';

  @override
  String get exportOpenFolder => '打开文件夹';

  @override
  String get exportShare => '分享';

  @override
  String get exportClose => '完成';

  @override
  String exportFailed(Object count) {
    return '导出完成，但有 $count 张失败：';
  }

  @override
  String get exportGallerySaved => '已保存到系统相册 GearLab。';

  @override
  String get exportFolderLabel => '保存位置';

  @override
  String get dismiss => '知道了';

  @override
  String get resetConfirmTitle => '重置版面？';

  @override
  String get resetConfirmBody => '会把当前照片的模板、文字、颜色和屏幕设置恢复为默认。';

  @override
  String get clearPhotos => '清空';

  @override
  String get clearConfirmTitle => '清空照片库？';

  @override
  String get clearConfirmBody => '照片仍保留在磁盘上，只从编辑区移除。';

  @override
  String get deletePhoto => '移除照片';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '中文';

  @override
  String get languageEn => 'English';

  @override
  String get more => '更多';

  @override
  String get preferences => '偏好设置';

  @override
  String get appearance => '外观';

  @override
  String get done => '完成';

  @override
  String allPhotos(Object count) {
    return '$count 张';
  }

  @override
  String get allPhotosOne => '1 张';

  @override
  String photoMeta(Object camera, Object height, Object width) {
    return '$width × $height · $camera';
  }

  @override
  String get stageFooterSplit => '上下 1:1';

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
  String get dropHint => '拖入照片或文件夹';

  @override
  String get emptyExport => '没有可导出的照片';

  @override
  String savedCount(Object count) {
    return '$count 张已导出';
  }

  @override
  String get savedCountOne => '1 张已导出';

  @override
  String get unsupportedFormat => '不支持的格式';

  @override
  String get couldNotReadImage => '无法读取这张图片';

  @override
  String get exportFolderNotWritable => '导出目录不可写';

  @override
  String get themeChanged => '外观已更新';

  @override
  String get languageChanged => '语言已切换';

  @override
  String get preferencesNote => '偏好会保存到本机，并在下次启动时恢复。';

  @override
  String get aboutLocal => '全部处理都在本机完成，不联网、不上传。';
}
