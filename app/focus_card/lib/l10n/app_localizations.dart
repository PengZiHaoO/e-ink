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
/// import 'l10n/app_localizations.dart';
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

  /// No description provided for @welcome1Title.
  ///
  /// In zh, this message translates to:
  /// **'这是你的状态卡'**
  String get welcome1Title;

  /// No description provided for @welcome1Desc.
  ///
  /// In zh, this message translates to:
  /// **'贴在手机背面，无电池、不充电，\n画面一旦刷新就永久保持。'**
  String get welcome1Desc;

  /// No description provided for @welcome2Title.
  ///
  /// In zh, this message translates to:
  /// **'翻转即写'**
  String get welcome2Title;

  /// No description provided for @welcome2Desc.
  ///
  /// In zh, this message translates to:
  /// **'选一个状态，翻转手机贴住卡片，\n几秒后卡片就是你现在的状态。'**
  String get welcome2Desc;

  /// No description provided for @welcome3Title.
  ///
  /// In zh, this message translates to:
  /// **'自动成账本'**
  String get welcome3Title;

  /// No description provided for @welcome3Desc.
  ///
  /// In zh, this message translates to:
  /// **'每次切换都会留下一条记录，\n专注多久，一目了然。'**
  String get welcome3Desc;

  /// No description provided for @skip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一页'**
  String get next;

  /// No description provided for @start.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get start;

  /// No description provided for @bindDiscovering.
  ///
  /// In zh, this message translates to:
  /// **'认识你的卡片'**
  String get bindDiscovering;

  /// No description provided for @bindDiscoverHint.
  ///
  /// In zh, this message translates to:
  /// **'把手机贴住卡片…'**
  String get bindDiscoverHint;

  /// No description provided for @bindMockNote.
  ///
  /// In zh, this message translates to:
  /// **'（演示模式：模拟发现过程）'**
  String get bindMockNote;

  /// No description provided for @bindFound.
  ///
  /// In zh, this message translates to:
  /// **'发现卡片'**
  String get bindFound;

  /// No description provided for @bindUidPrefix.
  ///
  /// In zh, this message translates to:
  /// **'编号'**
  String get bindUidPrefix;

  /// No description provided for @bindNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'给它起个名字'**
  String get bindNameLabel;

  /// No description provided for @bindNameHelper.
  ///
  /// In zh, this message translates to:
  /// **'跳过则用默认名'**
  String get bindNameHelper;

  /// No description provided for @bindDefaultName.
  ///
  /// In zh, this message translates to:
  /// **'我的专注卡'**
  String get bindDefaultName;

  /// No description provided for @bindComplete.
  ///
  /// In zh, this message translates to:
  /// **'完成绑定'**
  String get bindComplete;

  /// No description provided for @bindDone.
  ///
  /// In zh, this message translates to:
  /// **'绑定完成'**
  String get bindDone;

  /// No description provided for @bindDoneSub.
  ///
  /// In zh, this message translates to:
  /// **'这张卡现在是你的了'**
  String get bindDoneSub;

  /// No description provided for @demoBanner.
  ///
  /// In zh, this message translates to:
  /// **'演示模式 · 模拟写入，未连接真实卡片'**
  String get demoBanner;

  /// No description provided for @tabStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get tabStatus;

  /// No description provided for @tabRecords.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get tabRecords;

  /// No description provided for @statusTitle.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get statusTitle;

  /// No description provided for @nowLabel.
  ///
  /// In zh, this message translates to:
  /// **'现在'**
  String get nowLabel;

  /// No description provided for @notWritten.
  ///
  /// In zh, this message translates to:
  /// **'还没写过卡'**
  String get notWritten;

  /// No description provided for @notWrittenHint.
  ///
  /// In zh, this message translates to:
  /// **'选一个状态，翻转贴卡开始'**
  String get notWrittenHint;

  /// No description provided for @writtenAt.
  ///
  /// In zh, this message translates to:
  /// **'{time} 写入'**
  String writtenAt(String time);

  /// No description provided for @switchTitle.
  ///
  /// In zh, this message translates to:
  /// **'切换状态'**
  String get switchTitle;

  /// No description provided for @onCard.
  ///
  /// In zh, this message translates to:
  /// **'卡上'**
  String get onCard;

  /// No description provided for @since.
  ///
  /// In zh, this message translates to:
  /// **'{time} 起'**
  String since(String time);

  /// No description provided for @flipHint.
  ///
  /// In zh, this message translates to:
  /// **'翻转即写入'**
  String get flipHint;

  /// No description provided for @menuAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get menuAbout;

  /// No description provided for @menuProfile.
  ///
  /// In zh, this message translates to:
  /// **'名片档案（M4）'**
  String get menuProfile;

  /// No description provided for @menuUnbind.
  ///
  /// In zh, this message translates to:
  /// **'解绑卡片（M3）'**
  String get menuUnbind;

  /// No description provided for @menuLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get menuLanguage;

  /// No description provided for @aboutTagline.
  ///
  /// In zh, this message translates to:
  /// **'状态卡，专注为主打 —— 让你的状态，看得见'**
  String get aboutTagline;

  /// No description provided for @writeTitleCard.
  ///
  /// In zh, this message translates to:
  /// **'名片预览'**
  String get writeTitleCard;

  /// No description provided for @writeTitle.
  ///
  /// In zh, this message translates to:
  /// **'写入卡片'**
  String get writeTitle;

  /// No description provided for @guideAuto.
  ///
  /// In zh, this message translates to:
  /// **'翻转手机，贴住卡片，自动写入中'**
  String get guideAuto;

  /// No description provided for @guideMock.
  ///
  /// In zh, this message translates to:
  /// **'演示模式：点「写入卡片」模拟完整流程'**
  String get guideMock;

  /// No description provided for @mockFailToggle.
  ///
  /// In zh, this message translates to:
  /// **'模拟写入失败'**
  String get mockFailToggle;

  /// No description provided for @guideManual.
  ///
  /// In zh, this message translates to:
  /// **'翻转手机，贴住卡片'**
  String get guideManual;

  /// No description provided for @addMessageFirst.
  ///
  /// In zh, this message translates to:
  /// **'先加留言？'**
  String get addMessageFirst;

  /// No description provided for @messageLabel.
  ///
  /// In zh, this message translates to:
  /// **'留言（可选）'**
  String get messageLabel;

  /// No description provided for @messageHelper.
  ///
  /// In zh, this message translates to:
  /// **'例如：15:30 后可打扰'**
  String get messageHelper;

  /// No description provided for @messageTooLong.
  ///
  /// In zh, this message translates to:
  /// **'留言不能超过 {max} 字'**
  String messageTooLong(int max);

  /// No description provided for @writing.
  ///
  /// In zh, this message translates to:
  /// **'写入中…'**
  String get writing;

  /// No description provided for @writeButton.
  ///
  /// In zh, this message translates to:
  /// **'写入卡片'**
  String get writeButton;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @updated.
  ///
  /// In zh, this message translates to:
  /// **'已更新'**
  String get updated;

  /// No description provided for @updatedSub.
  ///
  /// In zh, this message translates to:
  /// **'卡片现在显示「{state}」'**
  String updatedSub(String state);

  /// No description provided for @recordsTitle.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get recordsTitle;

  /// No description provided for @recordsBuilding.
  ///
  /// In zh, this message translates to:
  /// **'统计页建设中（M2）—— 会话已在静默记录'**
  String get recordsBuilding;

  /// No description provided for @recordedSessions.
  ///
  /// In zh, this message translates to:
  /// **'已记录会话'**
  String get recordedSessions;

  /// No description provided for @recordsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'切换一次状态，这里就会出现第一条会话'**
  String get recordsEmpty;

  /// No description provided for @focusToday.
  ///
  /// In zh, this message translates to:
  /// **'今日专注'**
  String get focusToday;

  /// No description provided for @streakDays.
  ///
  /// In zh, this message translates to:
  /// **'连续 {n} 天'**
  String streakDays(int n);

  /// No description provided for @sessionsHeader.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get sessionsHeader;

  /// No description provided for @todayEmpty.
  ///
  /// In zh, this message translates to:
  /// **'今天还没有会话'**
  String get todayEmpty;

  /// No description provided for @openSessionTitle.
  ///
  /// In zh, this message translates to:
  /// **'还在专注吗？'**
  String get openSessionTitle;

  /// No description provided for @openSessionBody.
  ///
  /// In zh, this message translates to:
  /// **'卡片从 {time} 起一直显示「{state}」。'**
  String openSessionBody(String state, String time);

  /// No description provided for @endNow.
  ///
  /// In zh, this message translates to:
  /// **'现在结束'**
  String get endNow;

  /// No description provided for @stillGoing.
  ///
  /// In zh, this message translates to:
  /// **'仍在继续'**
  String get stillGoing;

  /// No description provided for @profileSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'名片档案'**
  String get profileSheetTitle;

  /// No description provided for @nameField.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get nameField;

  /// No description provided for @titleField.
  ///
  /// In zh, this message translates to:
  /// **'头衔'**
  String get titleField;

  /// No description provided for @qrField.
  ///
  /// In zh, this message translates to:
  /// **'二维码内容'**
  String get qrField;

  /// No description provided for @qrHelper.
  ///
  /// In zh, this message translates to:
  /// **'URL 或文本，渲染为卡上二维码'**
  String get qrHelper;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @errTimeout.
  ///
  /// In zh, this message translates to:
  /// **'没有读到卡片，请把手机贴紧卡片中央再试'**
  String get errTimeout;

  /// No description provided for @errCapacity.
  ///
  /// In zh, this message translates to:
  /// **'内容超出卡片容量，试试缩短留言'**
  String get errCapacity;

  /// No description provided for @errReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'卡片已被写保护，无法更新'**
  String get errReadOnly;

  /// No description provided for @errNotNdef.
  ///
  /// In zh, this message translates to:
  /// **'这张卡不是可写的 NDEF 卡（加密卡/银行卡/门禁卡等）'**
  String get errNotNdef;

  /// No description provided for @errCanceled.
  ///
  /// In zh, this message translates to:
  /// **'已取消写入'**
  String get errCanceled;

  /// No description provided for @errNfcDisabled.
  ///
  /// In zh, this message translates to:
  /// **'手机 NFC 未开启，请在系统设置中打开'**
  String get errNfcDisabled;

  /// No description provided for @errTagLost.
  ///
  /// In zh, this message translates to:
  /// **'写入中途卡片离开了，请保持贴合再试'**
  String get errTagLost;

  /// No description provided for @errUnknown.
  ///
  /// In zh, this message translates to:
  /// **'写入失败，请重试'**
  String get errUnknown;
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
