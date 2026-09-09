// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get welcome1Title => '这是你的状态卡';

  @override
  String get welcome1Desc => '贴在手机背面，无电池、不充电，\n画面一旦刷新就永久保持。';

  @override
  String get welcome2Title => '翻转即写';

  @override
  String get welcome2Desc => '选一个状态，翻转手机贴住卡片，\n几秒后卡片就是你现在的状态。';

  @override
  String get welcome3Title => '自动成账本';

  @override
  String get welcome3Desc => '每次切换都会留下一条记录，\n专注多久，一目了然。';

  @override
  String get skip => '跳过';

  @override
  String get next => '下一页';

  @override
  String get start => '开始';

  @override
  String get bindDiscovering => '认识你的卡片';

  @override
  String get bindDiscoverHint => '把手机贴住卡片…';

  @override
  String get bindMockNote => '（演示模式：模拟发现过程）';

  @override
  String get bindFound => '发现卡片';

  @override
  String get bindUidPrefix => '编号';

  @override
  String get bindNameLabel => '给它起个名字';

  @override
  String get bindNameHelper => '跳过则用默认名';

  @override
  String get bindDefaultName => '我的专注卡';

  @override
  String get bindComplete => '完成绑定';

  @override
  String get bindDone => '绑定完成';

  @override
  String get bindDoneSub => '这张卡现在是你的了';

  @override
  String get demoBanner => '演示模式 · 模拟写入，未连接真实卡片';

  @override
  String get tabStatus => '状态';

  @override
  String get tabRecords => '记录';

  @override
  String get statusTitle => '状态';

  @override
  String get nowLabel => '现在';

  @override
  String get notWritten => '还没写过卡';

  @override
  String get notWrittenHint => '选一个状态，翻转贴卡开始';

  @override
  String writtenAt(String time) {
    return '$time 写入';
  }

  @override
  String get switchTitle => '切换状态';

  @override
  String get onCard => '卡上';

  @override
  String since(String time) {
    return '$time 起';
  }

  @override
  String get flipHint => '翻转即写入';

  @override
  String get menuAbout => '关于';

  @override
  String get menuProfile => '名片档案（M4）';

  @override
  String get menuUnbind => '解绑卡片（M3）';

  @override
  String get menuLanguage => '语言';

  @override
  String get aboutTagline => '状态卡，专注为主打 —— 让你的状态，看得见';

  @override
  String get writeTitleCard => '名片预览';

  @override
  String get writeTitle => '写入卡片';

  @override
  String get guideAuto => '翻转手机，贴住卡片，自动写入中';

  @override
  String get guideMock => '演示模式：点「写入卡片」模拟完整流程';

  @override
  String get mockFailToggle => '模拟写入失败';

  @override
  String get guideManual => '翻转手机，贴住卡片';

  @override
  String get addMessageFirst => '先加留言？';

  @override
  String get messageLabel => '留言（可选）';

  @override
  String get messageHelper => '例如：15:30 后可打扰';

  @override
  String messageTooLong(int max) {
    return '留言不能超过 $max 字';
  }

  @override
  String get writing => '写入中…';

  @override
  String get writeButton => '写入卡片';

  @override
  String get retry => '重试';

  @override
  String get updated => '已更新';

  @override
  String updatedSub(String state) {
    return '卡片现在显示「$state」';
  }

  @override
  String get recordsTitle => '记录';

  @override
  String get recordsBuilding => '统计页建设中（M2）—— 会话已在静默记录';

  @override
  String get recordedSessions => '已记录会话';

  @override
  String get recordsEmpty => '切换一次状态，这里就会出现第一条会话';

  @override
  String get errTimeout => '没有读到卡片，请把手机贴紧卡片中央再试';

  @override
  String get errCapacity => '内容超出卡片容量，试试缩短留言';

  @override
  String get errReadOnly => '卡片已被写保护，无法更新';

  @override
  String get errCanceled => '已取消写入';

  @override
  String get errNfcDisabled => '手机 NFC 未开启，请在系统设置中打开';

  @override
  String get errTagLost => '写入中途卡片离开了，请保持贴合再试';

  @override
  String get errUnknown => '写入失败，请重试';
}
