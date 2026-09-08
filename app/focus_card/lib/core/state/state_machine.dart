/// S2/S3/S4 · 状态机 —— 状态变更的唯一合法入口。
///
/// 铁律（全景 S3）：**只有 [onWriteSuccess] 改变状态**（写卡成功才打点）；
/// 失败/取消只记尝试状态。J10（写入中被杀）由此保证：
/// 重启后 = 最后一次成功状态，绝无半截会话。
library;

import 'package:flutter/foundation.dart';

import '../hal/card_writer.dart';
import 'app_state.dart';
import 'card_state.dart';
import 'state_store.dart';

/// 一条已关闭的状态会话 —— R1 的输入。
/// T4 起 sessionSink 接 sqflite repository；测试里用 List 捕获。
class SessionRecord {
  final CardState state;
  final DateTime start;
  final DateTime end;
  final String? note;

  const SessionRecord({
    required this.state,
    required this.start,
    required this.end,
    this.note,
  });

  Duration get duration => end.difference(start);
}

class StateMachine extends ChangeNotifier {
  StateMachine({required this.store});

  final AppStateStore store;

  /// R 域接线点（T4 挂 repository；测试挂 List.add）
  void Function(SessionRecord record)? sessionSink;

  /// S2：留言长度上限（占位 profile 画布可容纳的保守值；
  /// M5 换硬件后随 profile 重新标定）
  static const int maxCustomTextChars = 32;

  AppState _state = AppState.initial();
  AppState get state => _state;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// S4：启动恢复（无存档 = 首装默认态）
  Future<void> load() async {
    final saved = await store.read();
    if (saved != null) _state = saved;
    _loaded = true;
    notifyListeners();
  }

  /// S2：留言校验。返回错误文案；null = 通过。
  String? validateCustomText(String? text) {
    if (text == null) return null;
    final t = text.trim();
    if (t.isEmpty) return null;
    if (t.length > maxCustomTextChars) {
      return '留言不能超过 $maxCustomTextChars 字';
    }
    return null;
  }

  /// S3 打点：写卡成功后调用（W1 编排器的唯一回调路径）。
  /// 关闭旧会话（仅当旧状态确实上过卡）→ 提交新状态 → 持久化 → 通知。
  Future<void> onWriteSuccess({
    required CardState newState,
    String? customText,
    DateTime? writeTs,
  }) async {
    final ts = writeTs ?? DateTime.now();
    final old = _state;

    // 旧会话关闭条件：旧状态由成功写入建立（真的在卡上显示过）。
    // 首装默认态从未上卡 → 首次写入不产会话，
    // 防止"装完 App 三天全算可打扰时长"的统计通胀。
    if (old.isCardSynced) {
      sessionSink?.call(SessionRecord(
        state: old.currentState,
        start: old.since,
        end: ts,
        note: old.customText,
      ));
    }

    final trimmed = customText?.trim();
    _state = AppState(
      currentState: newState,
      since: ts,
      customText: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      lastWriteTs: ts,
      lastWriteStatus: 'success',
      lastSuccessTs: ts,
    );
    await store.write(_state);
    notifyListeners();
  }

  /// 写入失败：只记尝试，不改状态、不打点、不关会话。
  /// 卡上仍显示旧状态——`isCardSynced` 依据 lastSuccessTs，不受失败影响。
  Future<void> onWriteFailure(WriteErrorKind kind, {DateTime? ts}) async {
    _state = _state.copyWith(
      lastWriteTs: ts ?? DateTime.now(),
      lastWriteStatus: kind.name,
    );
    await store.write(_state);
    notifyListeners();
  }
}
