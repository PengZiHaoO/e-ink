/// 依赖装配（组合根）：生产用 [AppDeps.create]，测试直接构造注入。
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/hal/card_renderer.dart';
import '../core/hal/card_writer.dart';
import '../core/hal/device_profile.dart';
import '../core/state/session_log.dart';
import '../core/state/state_machine.dart';
import '../core/state/state_store.dart';
import '../core/write/write_orchestrator.dart';

abstract final class PrefsKeys {
  static const welcomeDone = 'welcome_done.v1';
  static const binding = 'card_binding.v1';
  static const locale = 'locale.v1';
}

/// T3.5 · 运行时语言热切换：不重启 App，选择持久化到 prefs。
/// 屏1 溢出菜单「语言」开关调用 [toggle]。
class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;
  bool get isZh => _locale.languageCode == 'zh';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(PrefsKeys.locale);
    if (code != null) _locale = Locale(code);
  }

  Future<void> setLocale(Locale l) async {
    _locale = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.locale, l.languageCode);
    notifyListeners();
  }

  Future<void> toggle() =>
      setLocale(isZh ? const Locale('en') : const Locale('zh'));
}

class AppDeps {
  final DeviceProfile profile;
  final CardRenderer renderer;
  final CardWriter writer;
  final StateMachine machine;
  final SessionLog sessionLog;
  final WriteOrchestrator orchestrator;
  final LocaleController localeController;

  /// N3：桌面/演示环境角标依据
  final bool isMock;

  /// 当前语言下的状态标签快捷方式
  bool get isZh => localeController.isZh;

  AppDeps({
    required this.profile,
    required this.writer,
    required this.machine,
    required this.sessionLog,
    LocaleController? localeController,
    int deviceId = 0x00000001,
    DateTime Function()? clock,
  })  : renderer = CardRenderer(profile),
        localeController = localeController ?? LocaleController(),
        isMock = writer is MockCardWriter,
        orchestrator = WriteOrchestrator(
          profile: profile,
          renderer: CardRenderer(profile),
          writer: writer,
          machine: machine,
          deviceId: deviceId,
          clock: clock,
        );

  /// 生产装配：Gen1 占位 profile + 平台 writer + Prefs 持久化 + 语言偏好
  static Future<AppDeps> create() async {
    final profile = DeviceProfile.gen1Placeholder;
    final machine = StateMachine(store: PrefsAppStateStore());
    await machine.load();
    final log = SessionLog();
    machine.sessionSink = log.add; // T4：换成 sqflite repository
    final localeController = LocaleController();
    await localeController.load();
    return AppDeps(
      profile: profile,
      writer: createPlatformCardWriter(),
      machine: machine,
      sessionLog: log,
      localeController: localeController,
    );
  }
}
