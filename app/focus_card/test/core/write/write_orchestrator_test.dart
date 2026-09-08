import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_card/core/hal/card_renderer.dart';
import 'package:focus_card/core/hal/card_writer.dart';
import 'package:focus_card/core/hal/device_profile.dart';
import 'package:focus_card/core/hal/protocol.dart';
import 'package:focus_card/core/hal/rle.dart';
import 'package:focus_card/core/state/card_state.dart';
import 'package:focus_card/core/state/state_machine.dart';
import 'package:focus_card/core/state/state_store.dart';
import 'package:focus_card/core/write/write_orchestrator.dart';

class FakeWriter implements CardWriter {
  FakeWriter(this.result);

  final WriteResult result;
  final List<Uint8List> payloads = [];
  int writeCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<WriteResult> write(Uint8List payload) async {
    writeCalls++;
    payloads.add(payload);
    return result;
  }

  @override
  Future<void> dispose() async {}
}

/// 超小内存 profile：任何帧都超预算（W5 预检测试用）
DeviceProfile _tinyProfile() => DeviceProfile(
      profileId: 'tiny-test',
      generation: 99,
      canvasW: 100,
      canvasH: 50,
      colorDepth: 1,
      memoryLimitBytes: 64,
      ndefOverheadBytes: 16,
      protocolVersion: 0,
      compressions: const [0, 1],
      fontRules:
          const FontRules(stateWordMinPx: 20, timeMinPx: 14, cjkMinPx: 12),
      layoutRules: DeviceProfile.gen1Placeholder.layoutRules,
    );

({StateMachine machine, List<SessionRecord> sessions, WriteOrchestrator orch})
    _build(
  FakeWriter writer, {
  DeviceProfile? profile,
  DateTime Function()? clock,
}) {
  final p = profile ?? DeviceProfile.gen1Placeholder;
  final machine = StateMachine(store: MemoryAppStateStore());
  final sessions = <SessionRecord>[];
  machine.sessionSink = sessions.add;
  final orch = WriteOrchestrator(
    profile: p,
    renderer: CardRenderer(p),
    writer: writer,
    machine: machine,
    clock: clock,
  );
  return (machine: machine, sessions: sessions, orch: orch);
}

void main() {
  final t0 = DateTime(2026, 9, 8, 14, 32);
  final t1 = DateTime(2026, 9, 8, 15, 19);

  group('W1 · 编排管线', () {
    test('C1 同源：submit 发送的字节 = prepare 产出的 frameBytes', () async {
      final fake = FakeWriter(const WriteSuccess(0));
      final b = _build(fake, clock: () => t0);

      final prepared = await b.orch
          .prepare(newState: CardState.focusing, customText: '深度工作');
      final outcome = await b.orch.submit(prepared);

      expect(outcome.ok, isTrue);
      expect(fake.payloads.single, prepared.frameBytes);
    });

    test('成功路径：状态提交 + 留言 trim + 帧可解码回原始位图', () async {
      final fake = FakeWriter(const WriteSuccess(0));
      final b = _build(fake, clock: () => t0);

      final prepared = await b.orch
          .prepare(newState: CardState.focusing, customText: ' 深度工作 ');
      await b.orch.submit(prepared);

      expect(b.machine.state.currentState, CardState.focusing);
      expect(b.machine.state.customText, '深度工作');
      expect(prepared.payloadBytes,
          lessThanOrEqualTo(b.orch.profile.payloadBudget));

      // 固件视角：收帧 → 解码 → 解压 = 渲染位图
      final decoded = CardFrame.decode(fake.payloads.single);
      expect(decoded.compression, CardFrame.compressionRle);
      expect(rleDecode(decoded.imageData), prepared.bitmap.bytes);
    });

    test('两次提交：旧会话入账，时长 = 时钟差', () async {
      var now = t0;
      final fake = FakeWriter(const WriteSuccess(0));
      final b = _build(fake, clock: () => now);

      final p1 = await b.orch.prepare(newState: CardState.focusing);
      await b.orch.submit(p1);
      now = t1;
      final p2 = await b.orch.prepare(newState: CardState.onBreak);
      await b.orch.submit(p2);

      expect(b.sessions.length, 1);
      expect(b.sessions.single.state, CardState.focusing);
      expect(b.sessions.single.duration, t1.difference(t0));
      expect(b.machine.state.currentState, CardState.onBreak);
    });

    test('W5 容量预检：超限不发起写入', () async {
      final fake = FakeWriter(const WriteSuccess(0));
      final b = _build(fake, profile: _tinyProfile(), clock: () => t0);

      final prepared = await b.orch.prepare(newState: CardState.focusing);
      expect(prepared.payloadBytes, greaterThan(48),
          reason: 'tiny 预算=48，帧必然超限');

      final outcome = await b.orch.submit(prepared);
      expect(outcome.ok, isFalse);
      expect(outcome.error, WriteErrorKind.capacity);
      expect(fake.writeCalls, 0, reason: '预检拦截，writer 未被调用');
      expect(b.machine.state.lastWriteStatus, 'capacity');
      expect(b.machine.state.currentState, CardState.available,
          reason: '失败不改状态');
    });

    test('失败路径：状态不动、无会话、W4 文案非空', () async {
      final fake = FakeWriter(const WriteFailure(WriteErrorKind.timeout));
      final b = _build(fake, clock: () => t0);

      final prepared = await b.orch.prepare(newState: CardState.focusing);
      final outcome = await b.orch.submit(prepared);

      expect(outcome.ok, isFalse);
      expect(outcome.error, WriteErrorKind.timeout);
      expect(b.machine.state.currentState, CardState.available);
      expect(b.machine.state.lastWriteStatus, 'timeout');
      expect(b.sessions, isEmpty);
    });

    test('S2 校验直通', () {
      final fake = FakeWriter(const WriteSuccess(0));
      final b = _build(fake);
      expect(b.orch.validateCustomText('a' * 32), isNull);
      expect(b.orch.validateCustomText('a' * 33), isNotNull);
    });
  });
}
