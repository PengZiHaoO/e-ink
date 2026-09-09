/// W3 · 真机 NFC 写入（nfc_manager + nfc_manager_ndef）。
///
/// **会话 = 数据通道 + 供电通道**：无电池卡靠手机 NFC 场活着，
/// 故 stopSession 必须等写入完成；提前关场 = 卡断电 = 写一半死。
/// 失败重试 = 重开会话 = 重新上电。
///
/// NDEF 承载：单条 MIME media 记录 `application/x-focuscard`，
/// payload = 协议 v0 帧（Magic/Version/DeviceID/ImageSize/Compression/ImageData/CRC）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart'
    show NfcReaderErrorCodeIos;
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../hal/card_writer.dart';

/// 我们的 NDEF MIME 类型（写入与回读校验共用）
const String focusCardMime = 'application/x-focuscard';

/// 无标签等待上限：超时 = 用户没贴卡（Android 无系统级回调，由此兜底）
const Duration _discoverTimeout = Duration(seconds: 20);

class NfcCardWriter implements CardWriter {
  @override
  Future<void> dispose() async {}

  @override
  Future<bool> isAvailable() async =>
      (await NfcManager.instance.checkAvailability()) ==
      NfcAvailability.enabled;

  @override
  Future<WriteResult> write(Uint8List payload) async {
    if (!await isAvailable()) {
      return const WriteFailure(WriteErrorKind.nfcDisabled);
    }

    final result = Completer<WriteResult>();

    Future<void> finish(WriteResult r) async {
      if (!result.isCompleted) result.complete(r);
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {
        // 会话已被系统/用户结束，忽略
      }
    }

    await NfcManager.instance.startSession(
      // ST25DV = ISO15693；测试标签多为 NTAG = ISO14443 → 两种都 poll
      pollingOptions: const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      onDiscovered: (tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            await finish(const WriteFailure(WriteErrorKind.tagLost));
            return;
          }
          // 硬件侧复核（软件侧 W5 预检已在 orchestrator 做过）
          if (!ndef.isWritable) {
            await finish(const WriteFailure(WriteErrorKind.readOnly));
            return;
          }
          if (ndef.maxSize < payload.length) {
            await finish(const WriteFailure(WriteErrorKind.capacity));
            return;
          }
          await ndef.write(
            message: NdefMessage(records: [
              NdefRecord(
                typeNameFormat: TypeNameFormat.media,
                type: Uint8List.fromList(utf8.encode(focusCardMime)),
                identifier: Uint8List(0),
                payload: payload,
              ),
            ]),
          );
          await finish(WriteSuccess(payload.length));
        } catch (e) {
          await finish(WriteFailure(WriteErrorKind.unknown, detail: '$e'));
        }
      },
      onSessionErrorIos: (error) {
        if (result.isCompleted) return;
        result.complete(WriteFailure(_mapIosError(error.code)));
      },
    );

    return result.future.timeout(
      _discoverTimeout,
      onTimeout: () {
        if (!result.isCompleted) {
          result.complete(const WriteFailure(WriteErrorKind.timeout));
          NfcManager.instance.stopSession().catchError((_) {});
        }
        return const WriteFailure(WriteErrorKind.timeout);
      },
    );
  }

  WriteErrorKind _mapIosError(NfcReaderErrorCodeIos code) => switch (code) {
        NfcReaderErrorCodeIos.readerSessionInvalidationErrorUserCanceled =>
          WriteErrorKind.canceled,
        NfcReaderErrorCodeIos.readerSessionInvalidationErrorSessionTimeout =>
          WriteErrorKind.timeout,
        NfcReaderErrorCodeIos
            .readerSessionInvalidationErrorSessionTerminatedUnexpectedly =>
          WriteErrorKind.tagLost,
        _ => WriteErrorKind.unknown,
      };
}
