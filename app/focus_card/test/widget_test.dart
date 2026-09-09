/// App 全流程 widget 测试 + 屏幕 golden（评审材料）。
///
/// 异步纪律：
/// - 引擎级异步（渲染 toImage / 位图解码）→ 分段 tester.runAsync 里真实等待
/// - golden 捕获（内部自带 runAsync）→ 必须在 runAsync 段**外**，禁止嵌套
/// - 组件 Timer（庆祝 900ms / 发现 1.2s）→ 假时钟，tester.pump(duration) 推进
/// - golden 确定性：orchestrator 注入固定时钟（时间快照定格 14:32）
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/app/app.dart';
import 'package:focus_card/app/deps.dart';
import 'package:focus_card/core/device/card_binding.dart';
import 'package:focus_card/core/hal/card_writer.dart';
import 'package:focus_card/core/hal/device_profile.dart';
import 'package:focus_card/core/state/card_state.dart';
import 'package:focus_card/core/state/session_log.dart';
import 'package:focus_card/core/state/state_machine.dart';
import 'package:focus_card/core/state/state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/load_fonts.dart';

final _fixedClock = DateTime(2026, 9, 8, 14, 32);

AppDeps _testDeps() {
  final machine = StateMachine(store: MemoryAppStateStore());
  final log = SessionLog();
  machine.sessionSink = log.add;
  return AppDeps(
    profile: DeviceProfile.gen1Placeholder,
    writer: MockCardWriter(delay: Duration.zero),
    machine: machine,
    sessionLog: log,
    clock: () => _fixedClock,
  );
}

void _phoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void _seedPrefs({String uid = 'MOCK-TEST'}) {
  SharedPreferences.setMockInitialValues({
    PrefsKeys.welcomeDone: true,
    PrefsKeys.binding: CardBinding.encode(
        CardBinding(uid: uid, name: '测试卡', boundAt: DateTime(2026))),
  });
}

void main() {
  setUpAll(() async => loadCardFonts());

  testWidgets('主流程：屏1→专注→屏2→写入成功→屏1 更新（含 golden）',
      (tester) async {
    _phoneViewport(tester);
    _seedPrefs();
    final deps = _testDeps();
    await deps.machine.load();

    // ---- 段1：启动 + 屏1 渲染（引擎异步）----
    await tester.runAsync(() async {
      await tester.pumpWidget(FocusCardApp(deps: deps));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
    });
    expect(find.text('切换状态'), findsOneWidget);
    expect(find.text('还没写过卡'), findsOneWidget);
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/screen1_status.png'));

    // ---- 段2：进屏2 + prepare 渲染 ----
    await tester.runAsync(() async {
      await tester.tap(find.text('可打扰')); // 手动流程用非专注态（专注=自动写入）
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
      // 等 CardPreview 位图解码完成并落帧（否则 golden 拍到透明占位）
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await tester.pump();
    });
    expect(find.text('写入卡片'), findsWidgets);
    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('goldens/screen2_write.png'));

    // ---- 段3：写入成功 ----
    await tester.runAsync(() async {
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });
    expect(find.text('已更新'), findsOneWidget);

    // ---- 段4：庆祝 Timer 是真实时钟（runAsync 域内创建）→ 真实等待 pop，
    //      再推进路由动画，最后等屏1「现在」卡重渲染 ----
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
    });
    expect(deps.machine.state.currentState, CardState.available);
    expect(find.text('可打扰'), findsWidgets);
    expect(deps.sessionLog.count, 0, reason: '首次写入不产会话（防通胀）');
  });

  testWidgets('专注翻转即写入：进屏2 自动写入，无需点按钮', (tester) async {
    _phoneViewport(tester);
    _seedPrefs(uid: 'MOCK-FAST');
    final deps = _testDeps();
    await deps.machine.load();

    await tester.runAsync(() async {
      await tester.pumpWidget(FocusCardApp(deps: deps));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();

      // 英雄位整行按钮
      await tester.tap(find.text('专注'));
      await tester.pump();
      // 自动写入：prepare 完成即 submit（Mock 零延迟）→ 庆祝
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
      expect(deps.machine.state.currentState, CardState.focusing,
          reason: '未点写入按钮也应完成写入');

      // 庆祝真实 Timer 清理 → pop 回屏1
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
    });
    expect(find.text('专注中'), findsWidgets);
  });

  testWidgets('失败路径：模拟失败开关 → W4 文案 + 状态不动 → 重试成功',
      (tester) async {
    _phoneViewport(tester);
    _seedPrefs(uid: 'MOCK-T2');
    final deps = _testDeps();
    await deps.machine.load();

    await tester.runAsync(() async {
      await tester.pumpWidget(FocusCardApp(deps: deps));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
    });

    await tester.runAsync(() async {
      await tester.tap(find.text('可打扰'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump();
    });

    // 打开"模拟写入失败" → 写入
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });

    expect(find.textContaining('没有读到卡片'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
    expect(deps.machine.state.currentState, CardState.available,
        reason: '失败不改状态');

    // 关掉失败 → 重试成功
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('重试'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });
    expect(find.text('已更新'), findsOneWidget);
    expect(deps.machine.state.currentState, CardState.available);

    // 庆祝真实 Timer 清理：在测试域内等完 pop，避免跨测试噪音
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    });
  });

  testWidgets('首启：欢迎 3 页 → 绑定仪式 → 主页（N1+D1）', (tester) async {
    _phoneViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final deps = _testDeps();
    await deps.machine.load();

    await tester.pumpWidget(FocusCardApp(deps: deps));
    await tester.pump();
    await tester.pump();
    expect(find.text('这是你的状态卡'), findsOneWidget);

    // 跳过欢迎 → 绑定仪式
    await tester.tap(find.text('跳过'));
    await tester.pump();
    await tester.pump();
    expect(find.text('认识你的卡片'), findsOneWidget);

    // Mock 发现 Timer(1.2s)
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('发现卡片'), findsOneWidget);

    // 完成绑定 → 庆祝 Timer(900ms) → 主页
    await tester.tap(find.text('完成绑定'));
    await tester.pump();
    expect(find.text('绑定完成'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    await tester.pump();
    expect(find.text('切换状态'), findsOneWidget);

    // 二启不再出现欢迎（标记已写）
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefsKeys.welcomeDone), isTrue);
    expect(CardBinding.decode(prefs.getString(PrefsKeys.binding)), isNotNull);
  });

  testWidgets('T3.5 语言热切换：zh→en 标签即时变英文', (tester) async {
    _phoneViewport(tester);
    _seedPrefs(uid: 'MOCK-EN');
    final deps = _testDeps();
    await deps.machine.load();

    await tester.runAsync(() async {
      await tester.pumpWidget(FocusCardApp(deps: deps));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump();
    });
    expect(find.text('切换状态'), findsOneWidget);

    await deps.localeController.setLocale(const Locale('en'));
    await tester.pump();
    await tester.pump();
    expect(find.text('SWITCH STATE'), findsOneWidget); // v2: micro 大写标签
    expect(find.text('Focus'), findsOneWidget); // 英雄位英文标签
    expect(find.text('Not on card yet'), findsOneWidget);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('goldens/screen1_status_en.png'));
  });
}
