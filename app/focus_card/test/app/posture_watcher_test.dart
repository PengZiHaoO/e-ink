import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/app/deps.dart';
import 'package:focus_card/app/nfc_intent_router.dart';
import 'package:focus_card/app/posture_watcher.dart';
import 'package:focus_card/core/device/card_binding.dart';
import 'package:focus_card/core/hal/card_bitmap.dart';
import 'package:focus_card/core/hal/card_renderer.dart';
import 'package:focus_card/core/hal/card_writer.dart';
import 'package:focus_card/core/hal/device_profile.dart';
import 'package:focus_card/core/state/card_state.dart';
import 'package:focus_card/core/state/session_log.dart';
import 'package:focus_card/core/state/state_machine.dart';
import 'package:focus_card/core/state/state_store.dart';
import 'package:focus_card/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 即时渲染器：绕开引擎 toImage 真实异步（fake-async 测试可用）
class _InstantRenderer extends CardRenderer {
  _InstantRenderer(super.profile);

  @override
  Future<CardBitmap> render(CardRenderInput input) async =>
      CardBitmap.blank(profile.canvasW, profile.canvasH);
}

AppDeps _deps() {
  final machine = StateMachine(store: MemoryAppStateStore());
  final log = SessionLog();
  machine.sessionSink = log.add;
  return AppDeps(
    profile: DeviceProfile.gen1Placeholder,
    writer: MockCardWriter(delay: Duration.zero),
    machine: machine,
    sessionLog: log,
    rendererOverride: _InstantRenderer(DeviceProfile.gen1Placeholder),
  );
}

void main() {
  // 零持续时间：姿态转换立即生效（定时器首帧触发）
  const zero = Duration.zero;

  Future<AppDeps> seeded() async {
    SharedPreferences.setMockInitialValues({});
    await CardBindingStore.save(CardBinding(
      uid: 'TEST1',
      name: '测试卡',
      boundAt: DateTime(2026, 9, 10),
    ));
    final deps = _deps();
    await deps.machine.load();
    // 卡上当前 = 可打扰（已同步）
    await deps.machine.onWriteSuccess(
      newState: CardState.available,
      writeTs: DateTime(2026, 9, 10, 9, 0),
    );
    return deps;
  }

  testWidgets('扣下（非充电）+ 可打扰态 → 自动开始 focus', (tester) async {
    final deps = await seeded();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.key,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox.shrink()),
    ));
    final w = PostureWatcher(deps: deps, faceDownHold: zero, faceUpHold: zero);
    w.handlePosture('faceDown', false);
    await tester.pump();
    await tester.pump();
    expect(deps.machine.state.currentState, CardState.focusing);
    await tester.pumpAndSettle(); // 清 snackbar 定时器
  });

  testWidgets('扣下 + 充电中 → 抑制（不自动开始）', (tester) async {
    final deps = await seeded();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.key,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox.shrink()),
    ));
    final w = PostureWatcher(deps: deps, faceDownHold: zero, faceUpHold: zero);
    w.handlePosture('faceDown', true);
    await tester.pump();
    await tester.pump();
    expect(deps.machine.state.currentState, CardState.available);
  });

  testWidgets('focus 中拿起 → 自动结束 + 重写可打扰 + 会话入账', (tester) async {
    final deps = await seeded();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.key,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox.shrink()),
    ));
    final w = PostureWatcher(deps: deps, faceDownHold: zero, faceUpHold: zero);
    w.handlePosture('faceDown', false);
    await tester.pump();
    await tester.pump();
    expect(deps.machine.state.currentState, CardState.focusing);

    w.handlePosture('faceUp', false);
    await tester.pump();
    await tester.pump();
    expect(deps.machine.state.currentState, CardState.available);
    expect(deps.sessionLog.records.any((r) => r.state == CardState.focusing),
        isTrue);
    await tester.pumpAndSettle(); // 清 snackbar 定时器
  });

  testWidgets('故意状态（名片）扣下 → 不响应', (tester) async {
    final deps = await seeded();
    await deps.machine.onWriteSuccess(
      newState: CardState.namecard,
      writeTs: DateTime(2026, 9, 10, 10, 0),
    );
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.key,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox.shrink()),
    ));
    final w = PostureWatcher(deps: deps, faceDownHold: zero, faceUpHold: zero);
    w.handlePosture('faceDown', false);
    await tester.pump();
    await tester.pump();
    expect(deps.machine.state.currentState, CardState.namecard);
  });

  testWidgets('屏2 会话中 → 让位', (tester) async {
    final deps = await seeded();
    deps.writeScreenActive = true;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: AppNavigator.key,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox.shrink()),
    ));
    final w = PostureWatcher(deps: deps, faceDownHold: zero, faceUpHold: zero);
    w.handlePosture('faceDown', false);
    await tester.pump();
    await tester.pump();
    expect(deps.machine.state.currentState, CardState.available);
  });
}
