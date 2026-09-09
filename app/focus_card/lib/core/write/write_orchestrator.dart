/// W1 · 写入编排管线：校验(S2) → 渲染(H2) → 压缩(H4) → 编码(H3)
///      → 容量预检(W5) → 写入(H6) → 打点回调(S3)。
///
/// **C1 同源保证**：prepare/submit 两段式——屏2 预览的位图与写卡的字节
/// 出自同一次 [prepare] 的产物；[submit] 只发送 `prepared.frameBytes`，
/// 不重新渲染（预览永不骗人）。
library;

import 'dart:typed_data';

import '../hal/card_bitmap.dart';
import '../hal/card_renderer.dart';
import '../hal/card_writer.dart';
import '../hal/device_profile.dart';
import '../hal/protocol.dart';
import '../hal/rle.dart';
import '../state/card_state.dart';
import '../state/state_machine.dart';

/// prepare 的产物：预览位图 + 待写帧（同一份，两个用途）
class PreparedCard {
  final CardBitmap bitmap;
  final CardFrame frame;

  /// = frame.encode()；submit 只发送这份字节
  final Uint8List frameBytes;
  final CardState newState;
  final String? customText;

  PreparedCard({
    required this.bitmap,
    required this.frame,
    required this.frameBytes,
    required this.newState,
    this.customText,
  });

  int get rawBytes => bitmap.byteLength;
  int get payloadBytes => frameBytes.length;
}

enum WriteStage { render, compress, write, done, failed }

/// 写入结果。用户文案不在这里——W4 文案走 l10n，
/// 由 UI 层按 [error] 种类映射（write_screen.errorCopy）。
class WriteOutcome {
  final bool ok;
  final WriteErrorKind? error;
  final PreparedCard? prepared;

  const WriteOutcome({
    required this.ok,
    this.error,
    this.prepared,
  });
}

class WriteOrchestrator {
  WriteOrchestrator({
    required this.profile,
    required this.renderer,
    required this.writer,
    required this.machine,
    this.deviceId = 0x00000001, // M3 起 = 绑定 UID 哈希（D2）
    this.onStage,
    this.clock,
  });

  final DeviceProfile profile;
  final CardRenderer renderer;
  final CardWriter writer;
  final StateMachine machine;
  final int deviceId;
  final void Function(WriteStage stage)? onStage;

  /// 可注入时钟（golden 确定性 / 会话时长测试）；生产为 null → DateTime.now
  final DateTime Function()? clock;

  DateTime _now() => (clock ?? DateTime.now)();

  /// S2 校验直通（UI 输入时调用）
  String? validateCustomText(String? text) => machine.validateCustomText(text);

  /// 渲染 + 压缩 + 编码（不写入）。时间快照在此刻定格。
  Future<PreparedCard> prepare({
    required CardState newState,
    String? customText,
    String? name,
    String? title,
    CardBitmap? qrBitmap,
  }) async {
    onStage?.call(WriteStage.render);
    final input = newState.buildRenderInput(
      since: _now(),
      customText: customText,
      name: name,
      title: title,
      qrBitmap: qrBitmap,
    );
    final bitmap = await renderer.render(input);

    onStage?.call(WriteStage.compress);
    final compressed = rleEncode(bitmap.bytes);
    final frame = CardFrame(
      deviceId: deviceId,
      compression: CardFrame.compressionRle,
      imageData: compressed,
    );
    return PreparedCard(
      bitmap: bitmap,
      frame: frame,
      frameBytes: frame.encode(),
      newState: newState,
      customText: customText?.trim().isEmpty == true ? null : customText?.trim(),
    );
  }

  /// W5 容量预检：超限不发起写入
  WriteErrorKind? checkCapacity(PreparedCard prepared) =>
      profile.fitsPayload(prepared.payloadBytes) ? null : WriteErrorKind.capacity;

  /// 写入 + 按结果打点（成功→S3 onWriteSuccess；失败→只记尝试）
  Future<WriteOutcome> submit(PreparedCard prepared, {DateTime? writeTs}) async {
    final capacityError = checkCapacity(prepared);
    if (capacityError != null) {
      await machine.onWriteFailure(capacityError);
      onStage?.call(WriteStage.failed);
      return WriteOutcome(
        ok: false,
        error: capacityError,
        prepared: prepared,
      );
    }

    onStage?.call(WriteStage.write);
    final result = await writer.write(prepared.frameBytes);
    final ts = writeTs ?? _now();

    switch (result) {
      case WriteSuccess():
        await machine.onWriteSuccess(
          newState: prepared.newState,
          customText: prepared.customText,
          writeTs: ts,
        );
        onStage?.call(WriteStage.done);
        return WriteOutcome(ok: true, prepared: prepared);
      case WriteFailure(:final kind):
        await machine.onWriteFailure(kind, ts: ts);
        onStage?.call(WriteStage.failed);
        return WriteOutcome(
          ok: false,
          error: kind,
          prepared: prepared,
        );
    }
  }
}
