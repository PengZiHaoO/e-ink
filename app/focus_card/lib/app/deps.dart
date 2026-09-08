/// 依赖装配（组合根）：生产用 [AppDeps.create]，测试直接构造注入。
library;

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
}

class AppDeps {
  final DeviceProfile profile;
  final CardRenderer renderer;
  final CardWriter writer;
  final StateMachine machine;
  final SessionLog sessionLog;
  final WriteOrchestrator orchestrator;

  /// N3：桌面/演示环境角标依据
  final bool isMock;

  AppDeps({
    required this.profile,
    required this.writer,
    required this.machine,
    required this.sessionLog,
    int deviceId = 0x00000001,
    DateTime Function()? clock,
  })  : renderer = CardRenderer(profile),
        isMock = writer is MockCardWriter,
        orchestrator = WriteOrchestrator(
          profile: profile,
          renderer: CardRenderer(profile),
          writer: writer,
          machine: machine,
          deviceId: deviceId,
          clock: clock,
        );

  /// 生产装配：Gen1 占位 profile + 平台 writer + Prefs 持久化
  static Future<AppDeps> create() async {
    final profile = DeviceProfile.gen1Placeholder;
    final machine = StateMachine(store: PrefsAppStateStore());
    await machine.load();
    final log = SessionLog();
    machine.sessionSink = log.add; // T4：换成 sqflite repository
    return AppDeps(
      profile: profile,
      writer: createPlatformCardWriter(),
      machine: machine,
      sessionLog: log,
    );
  }
}
