/// W3 · 真机 NFC 写入（nfc_manager + nfc_manager_ndef）。
///
/// **会话生命周期 = 屏2 生命周期**（2026-09-10 真机教训）：
/// 若每次写入后 stopSession，卡仍在场时系统会把"仍在场的标签"当新事件
/// dispatch → 弹出系统 TechListChooser 抢走 NFC。reader 会话开着时系统
/// dispatch 被抑制 → 会话在屏2 存活期间保持打开，离开屏2 才 stopSession。
///
/// **会话 = 数据通道 + 供电通道**：无电池卡靠手机 NFC 场活着；
/// 重试 = 移除卡片再贴（同会话内重新触发 onDiscovered）。
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
  bool _sessionOpen = false;
  Completer<WriteResult>? _pending;
  Uint8List? _payload;

  @override
  Future<void> dispose() async {
    if (_sessionOpen) {
      _log('screen left → stopSession');
      _sessionOpen = false;
      _pending = null;
      try {
        await NfcManager.instance.stopSession();
      } catch (_) {}
    }
  }

  @override
  Future<bool> isAvailable() async =>
      (await NfcManager.instance.checkAvailability()) ==
      NfcAvailability.enabled;

  Future<void> _ensureSession() async {
    if (_sessionOpen) return;
    _log('startSession（屏2 期间保持打开，抑制系统 dispatch）');
    await NfcManager.instance.startSession(
      // ST25DV = ISO15693；测试标签多为 NTAG = ISO14443 → 两种都 poll
      pollingOptions: const {
        NfcPollingOption.iso14443,
        NfcPollingOption.iso15693,
      },
      noPlatformSoundsAndroid: true,
      onDiscovered: _onTag,
      onSessionErrorIos: (error) {
        _log('iOS session error: ${error.code} ${error.message}');
        final p = _pending;
        if (p != null && !p.isCompleted) {
          p.complete(WriteFailure(_mapIosError(error.code)));
        }
        _pending = null;
      },
    );
    _sessionOpen = true;
  }

  Future<void> _onTag(NfcTag tag) async {
    final pending = _pending;
    final payload = _payload;
    if (pending == null || pending.isCompleted || payload == null) {
      _log('tag present（无待写请求，忽略——重试请先点重试再贴卡）');
      return;
    }
    _pending = null;
    _log('tag discovered');
    try {
      final ndef = Ndef.from(tag);
      if (ndef == null) {
        _log('FAIL notNdef（非 NDEF 卡：加密卡/银行卡/门禁卡）');
        pending.complete(const WriteFailure(WriteErrorKind.notNdef));
        return; // 会话保持打开（抑制系统 dispatch）
      }
      _log('ndef ok: writable=${ndef.isWritable} maxSize=${ndef.maxSize}');
      if (!ndef.isWritable) {
        _log('FAIL readOnly');
        pending.complete(const WriteFailure(WriteErrorKind.readOnly));
        return;
      }
      if (ndef.maxSize < payload.length) {
        _log('FAIL capacity: tag=${ndef.maxSize} < payload=${payload.length}');
        pending.complete(const WriteFailure(WriteErrorKind.capacity));
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
      pending.complete(WriteSuccess(payload.length));
      // 不关会话：卡可能还在场，关场会触发系统 dispatch
    } catch (e) {
      _log('FAIL unknown: $e');
      pending.complete(WriteFailure(WriteErrorKind.unknown, detail: '$e'));
    }
  }

  @override
  Future<WriteResult> write(Uint8List payload) async {
    _log('write armed, payload=${payload.length}B —— 贴卡触发');
    if (!await isAvailable()) {
      _log('FAIL nfcDisabled');
      return const WriteFailure(WriteErrorKind.nfcDisabled);
    }
    await _ensureSession();
    final completer = Completer<WriteResult>();
    _pending = completer;
    _payload = payload;
    return completer.future.timeout(
      _discoverTimeout,
      onTimeout: () {
        _log('FAIL timeout（${_discoverTimeout.inSeconds}s 无贴卡）');
        _pending = null;
        return const WriteFailure(WriteErrorKind.timeout);
        // 会话保持打开：之后贴卡仍可被后续 write 武装前忽略，点写入再武装
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
