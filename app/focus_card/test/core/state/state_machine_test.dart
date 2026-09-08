import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/card_writer.dart';
import 'package:focus_card/core/hal/device_profile.dart';
import 'package:focus_card/core/state/app_state.dart';
import 'package:focus_card/core/state/card_state.dart';
import 'package:focus_card/core/state/state_machine.dart';
import 'package:focus_card/core/state/state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final t1 = DateTime(2026, 9, 8, 14, 32);
  final t2 = DateTime(2026, 9, 8, 15, 19);
  final t3 = DateTime(2026, 9, 8, 15, 31);

  group('S1 · 五态定义', () {
    test('五态齐全，templateId 唯一，isFocus 只有一个', () {
      expect(CardState.values.length, 5);
      expect(CardState.values.where((s) => s.isFocus).length, 1);
      expect(CardState.focusing.isFocus, isTrue);
      expect(CardState.namecard.stateWord, isNull);
      expect(
        CardState.values.map((s) => s.templateId).toSet(),
        {'focusing', 'break', 'available', 'away', 'card'},
      );
    });

    test('中文名齐全（UI 直接用）', () {
      for (final s in CardState.values) {
        expect(s.labelZh, isNotEmpty);
      }
    });
  });

  group('S5 · 状态→模板解析', () {
    test('Gen1 占位 profile 五态全部可解析', () {
      final p = DeviceProfile.gen1Placeholder;
      for (final s in CardState.values) {
        expect(s.resolveLayout(p).templateId, s.templateId);
      }
    });

    test('缺模板的 profile 抛 StateError（M5 换硬件的护栏）', () {
      final empty = DeviceProfile(
        profileId: 'empty-test',
        generation: 99,
        canvasW: 100,
        canvasH: 50,
        colorDepth: 1,
        memoryLimitBytes: 1024,
        ndefOverheadBytes: 16,
        protocolVersion: 0,
        compressions: const [0],
        fontRules: const FontRules(
            stateWordMinPx: 20, timeMinPx: 14, cjkMinPx: 12),
        layoutRules: const {},
      );
      expect(() => CardState.focusing.resolveLayout(empty), throwsStateError);
    });

    test('时间快照 HH:mm 补零（快照语义，非实时）', () {
      expect(CardState.focusing.timeSnapshot(DateTime(2026, 9, 8, 9, 5)),
          '09:05');
      expect(CardState.focusing.timeSnapshot(t1), '14:32');
    });

    test('buildRenderInput：状态模板带 stateWord/time/留言；名片带 name/title', () {
      final i1 = CardState.focusing
          .buildRenderInput(since: t1, customText: '开会中');
      expect(i1.templateId, 'focusing');
      expect(i1.stateWord, 'FOCUSING');
      expect(i1.timeText, '14:32');
      expect(i1.customText, '开会中');

      final i2 = CardState.namecard.buildRenderInput(name: 'ALEX', title: 'PM');
      expect(i2.templateId, 'card');
      expect(i2.stateWord, isNull);
      expect(i2.name, 'ALEX');
      expect(i2.title, 'PM');
    });
  });

  group('S2 · 留言校验', () {
    final m = StateMachine(store: MemoryAppStateStore());

    test('null / 空白 通过', () {
      expect(m.validateCustomText(null), isNull);
      expect(m.validateCustomText('   '), isNull);
    });

    test('32 字通过，33 字拒绝且文案含上限', () {
      expect(m.validateCustomText('a' * 32), isNull);
      expect(m.validateCustomText('中' * 32), isNull);
      expect(m.validateCustomText('a' * 33), isNotNull);
      expect(m.validateCustomText('a' * 33), contains('32'));
    });
  });

  group('S3 · 打点时机（铁律：写成功才打点）', () {
    test('首次写入成功：状态提交、留言 trim、无会话产生', () async {
      final sessions = <SessionRecord>[];
      final m = StateMachine(store: MemoryAppStateStore())
        ..sessionSink = sessions.add;

      await m.onWriteSuccess(
          newState: CardState.focusing, customText: ' 深度工作 ', writeTs: t1);

      expect(m.state.currentState, CardState.focusing);
      expect(m.state.since, t1);
      expect(m.state.customText, '深度工作');
      expect(m.state.isCardSynced, isTrue);
      expect(sessions, isEmpty,
          reason: '首装默认态从未上卡，不产生会话（防统计通胀）');
    });

    test('二次成功切换：旧会话关闭，时长/留言正确，留言不继承', () async {
      final sessions = <SessionRecord>[];
      final m = StateMachine(store: MemoryAppStateStore())
        ..sessionSink = sessions.add;

      await m.onWriteSuccess(
          newState: CardState.focusing, customText: '写方案', writeTs: t1);
      await m.onWriteSuccess(newState: CardState.onBreak, writeTs: t2);

      expect(sessions.length, 1);
      expect(sessions.single.state, CardState.focusing);
      expect(sessions.single.start, t1);
      expect(sessions.single.end, t2);
      expect(sessions.single.note, '写方案');
      expect(sessions.single.duration, const Duration(minutes: 47));
      expect(m.state.currentState, CardState.onBreak);
      expect(m.state.customText, isNull);
    });

    test('写入失败：状态不动、不打点、卡同步事实不被抹掉', () async {
      final sessions = <SessionRecord>[];
      final m = StateMachine(store: MemoryAppStateStore())
        ..sessionSink = sessions.add;

      await m.onWriteSuccess(newState: CardState.focusing, writeTs: t1);
      await m.onWriteFailure(WriteErrorKind.timeout, ts: t2);

      expect(m.state.currentState, CardState.focusing);
      expect(m.state.since, t1);
      expect(m.state.lastWriteStatus, 'timeout');
      expect(m.state.lastWriteTs, t2);
      expect(m.state.isCardSynced, isTrue,
          reason: '卡上仍是 t1 写入的 FOCUSING，失败尝试不改变事实');
      expect(sessions, isEmpty);

      // 失败后重试成功切换：t1→t3 的完整会话不丢失
      await m.onWriteSuccess(newState: CardState.available, writeTs: t3);
      expect(sessions.length, 1);
      expect(sessions.single.state, CardState.focusing);
      expect(sessions.single.duration, t3.difference(t1));
    });

    test('每次提交必落库（S4 writeCount）', () async {
      final store = MemoryAppStateStore();
      final m = StateMachine(store: store);
      await m.onWriteSuccess(newState: CardState.focusing, writeTs: t1);
      await m.onWriteFailure(WriteErrorKind.canceled, ts: t2);
      expect(store.writeCount, 2);
    });
  });

  group('S4 · 持久化与重启恢复', () {
    test('重启恢复：新实例从同一 store 恢复全部状态并接续会话', () async {
      final store = MemoryAppStateStore();
      final m1 = StateMachine(store: store);
      await m1.onWriteSuccess(
          newState: CardState.away, customText: '17:00 回', writeTs: t1);

      // 模拟杀进程重启（J10）
      final sessions = <SessionRecord>[];
      final m2 = StateMachine(store: store)..sessionSink = sessions.add;
      await m2.load();

      expect(m2.isLoaded, isTrue);
      expect(m2.state.currentState, CardState.away);
      expect(m2.state.since, t1);
      expect(m2.state.customText, '17:00 回');
      expect(m2.state.isCardSynced, isTrue);

      await m2.onWriteSuccess(newState: CardState.available, writeTs: t2);
      expect(sessions.single.state, CardState.away);
      expect(sessions.single.duration, t2.difference(t1));
    });

    test('load：无存档 = 首装默认（可打扰、未同步）', () async {
      final m = StateMachine(store: MemoryAppStateStore());
      await m.load();
      expect(m.state.currentState, CardState.available);
      expect(m.state.isCardSynced, isFalse);
    });

    test('notifyListeners：load/成功/失败都通知（UI 接线点）', () async {
      final m = StateMachine(store: MemoryAppStateStore());
      var notified = 0;
      m.addListener(() => notified++);
      await m.load();
      await m.onWriteSuccess(newState: CardState.focusing, writeTs: t1);
      await m.onWriteFailure(WriteErrorKind.tagLost);
      expect(notified, 3);
    });

    test('AppState JSON round-trip', () {
      final s = AppState(
        currentState: CardState.onBreak,
        since: t1,
        customText: 'x',
        lastWriteTs: t2,
        lastWriteStatus: 'success',
        lastSuccessTs: t2,
      );
      final back = AppState.fromJson(s.toJson());
      expect(back.currentState, CardState.onBreak);
      expect(back.since, t1);
      expect(back.customText, 'x');
      expect(back.lastWriteStatus, 'success');
      expect(back.lastSuccessTs, t2);
      expect(back.isCardSynced, isTrue);
    });

    test('AppState.fromJson：未知状态名回退 available（版本降级兼容）', () {
      final back = AppState.fromJson(
          {'currentState': 'ghost', 'since': t1.toIso8601String()});
      expect(back.currentState, CardState.available);
    });

    test('PrefsAppStateStore round-trip（mock prefs）', () async {
      SharedPreferences.setMockInitialValues({});
      final store = PrefsAppStateStore();
      expect(await store.read(), isNull);
      await store.write(AppState(
          currentState: CardState.focusing, since: t1, lastSuccessTs: t1));
      final back = await store.read();
      expect(back!.currentState, CardState.focusing);
      expect(back.since, t1);
      expect(back.isCardSynced, isTrue);
    });

    test('PrefsAppStateStore：损坏数据视为首启，不抛异常', () async {
      SharedPreferences.setMockInitialValues(
          {PrefsAppStateStore.key: '{{{not-json'});
      expect(await PrefsAppStateStore().read(), isNull);
    });
  });
}
