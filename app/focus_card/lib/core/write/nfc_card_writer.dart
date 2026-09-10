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

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:ndef_record/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart'
    show NfcReaderErrorCodeIos;
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

import '../hal/card_writer.dart';

/// 我们的 NDEF MIME 类型（写入与回读校验共用）
const String focusCardMime = 'application/x-focuscard';

/// 真机调试埋点（adb logcat 过滤 [NFC]）
void _log(String m) => debugPrint('[NFC] $m');

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
    _log('write start, payload=${payload.length}B');
    if (!await isAvailable()) {
      _log('FAIL nfcDisabled');
      return const WriteFailure(WriteErrorKind.nfcDisabled);
    }

    final result = Completer<WriteResult>();

    Future<void> finish(WriteResult r) async {
      _log(switch (r) {
        WriteSuccess(:final bytesWritten) => 'finish: OK ${bytesWritten}B',
        WriteFailure(:final kind) => 'finish: FAIL ${kind.name}',
      });
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
        _log('tag discovered');
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null) {
            _log('FAIL notNdef（非 NDEF 卡：加密卡/银行卡/门禁卡）');
            await finish(const WriteFailure(WriteErrorKind.notNdef));
            return;
          }
          _log('ndef ok: writable=${ndef.isWritable} maxSize=${ndef.maxSize}');
          // 硬件侧复核（软件侧 W5 预检已在 orchestrator 做过）
          if (!ndef.isWritable) {
            _log('FAIL readOnly');
            await finish(const WriteFailure(WriteErrorKind.readOnly));
            return;
          }
          if (ndef.maxSize < payload.length) {
            _log('FAIL capacity: tag=${ndef.maxSize} < payload=${payload.length}');
            await finish(const WriteFailure(WriteErrorKind.capacity));
            return;
          }
          _log('writing ${payload.length}B ...');
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
          _log('write OK');
          await finish(WriteSuccess(payload.length));
        } catch (e) {
          _log('FAIL unknown: $e');
          await finish(WriteFailure(WriteErrorKind.unknown, detail: '$e'));
        }
      },
      onSessionErrorIos: (error) {
        _log('iOS session error: ${error.code} ${error.message}');
        if (result.isCompleted) return;
        result.complete(WriteFailure(_mapIosError(error.code)));
      },
    );

    return result.future.timeout(
      _discoverTimeout,
      onTimeout: () {
        _log('FAIL timeout（${_discoverTimeout.inSeconds}s 无标签）');
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
