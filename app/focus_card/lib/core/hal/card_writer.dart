/// H6 · CardWriter —— 写入的唯一抽象接口。
///
/// 架构硬规矩（《App方案_V1.1》§4）：L2/L3 核心域通过本接口写卡，
/// 永不直接触碰任何平台 NFC API；平台差异全部关在实现类里：
/// - [MockCardWriter]：桌面/演示/测试（W2，T3 完善失败注入与 UI 联调）
/// - NfcCardWriter：Android 真机（W3，M3/T6 实现，nfc_manager）
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

import '../write/nfc_card_writer.dart';

/// 写入错误分类（W3 真机实现将 nfc_manager 异常映射至此；用户文案见 W4）
enum WriteErrorKind {
  timeout, // 会话超时/耦合差
  capacity, // 标签容量不足（W5 预检也会直接给这个）
  readOnly, // 标签被写保护
  notNdef, // 非 NDEF 卡（加密卡/银行卡/门禁卡等）
  canceled, // 用户取消（iOS 弹窗点取消）
  nfcDisabled, // 系统 NFC 未开启（N2 引导）
  tagLost, // 写入中途标签离场
  unknown,
}

/// 写入结果。sealed：UI 层 switch 必须穷尽成功/失败分支（编译期保证）。
sealed class WriteResult {
  const WriteResult();
}

class WriteSuccess extends WriteResult {
  final int bytesWritten;
  const WriteSuccess(this.bytesWritten);
}

class WriteFailure extends WriteResult {
  final WriteErrorKind kind;
  final String? detail;
  const WriteFailure(this.kind, {this.detail});
}

abstract class CardWriter {
  /// 当前是否具备写卡条件（平台能力 + 适配器状态）
  Future<bool> isAvailable();

  /// 写入完整协议帧（[CardFrame.encode] 的输出）。
  /// 实现负责整个流程：发现标签 → 会话 → 容量确认 → 写 NDEF → 收尾。
  Future<WriteResult> write(Uint8List payload);

  Future<void> dispose() async {}
}

/// W2 · Mock 实现：800ms 延迟 + 可注入失败率（测重试 UI 用）。
/// 纯 Dart、可注入 [Random]——单测完全确定性。
/// [failureRate] 可变：屏2 演示模式的"模拟写入失败"开关直接调它（T3）。
class MockCardWriter implements CardWriter {
  final Duration delay;

  /// 0.0 ~ 1.0
  double failureRate;
  final Random _random;

  MockCardWriter({
    this.delay = const Duration(milliseconds: 800),
    this.failureRate = 0.0,
    Random? random,
  }) : _random = random ?? Random();

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<WriteResult> write(Uint8List payload) async {
    // zero 延迟走 microtask（fake-async 测试可驱动；生产无感）
    if (delay == Duration.zero) {
      await Future<void>.value();
    } else {
      await Future<void>.delayed(delay);
    }
    if (failureRate > 0 && _random.nextDouble() < failureRate) {
      return const WriteFailure(WriteErrorKind.timeout, detail: 'mock: 模拟耦合超时');
    }
    return WriteSuccess(payload.length);
  }

  @override
  Future<void> dispose() async {}
}

/// 平台工厂：移动真机 = NfcCardWriter；桌面/测试 = Mock。
CardWriter createPlatformCardWriter() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return NfcCardWriter();
    default:
      return MockCardWriter();
  }
}
